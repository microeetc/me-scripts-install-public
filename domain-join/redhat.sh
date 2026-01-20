#!/bin/bash

# =================================================================
# SCRIPT DE INGRESSO EM DOMÍNIO AD - RED HAT / RHEL BASED (V3.1)
# =================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    echo "Uso: $0 [opções]"
    echo "Opções:"
    echo "  --domain DOMAIN     Ex: domain.local"
    echo "  --user USER         Usuário com permissão de Join"
    echo "  --groups GROUPS     Grupos AD entre aspas (ex: \"linuxadmins\")"
    exit 0
}

# 1. Parse de Argumentos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --domain) AD_DOMAIN="$2"; shift ;;
        --user) AD_USER="$2"; shift ;;
        --groups) AD_GROUPS="$2"; shift ;;
        --help) show_help ;;
    esac
    shift
done

# 2. Modo Interativo (Suporte a Pipe via /dev/tty)
if [ -t 0 ] || [ -f /dev/tty ]; then
    exec < /dev/tty
fi

if [ -z "$AD_DOMAIN" ]; then
    read -p "Digite o Nome do Domínio (ex: empresa.com.br): " AD_DOMAIN
fi

if [ -z "$AD_USER" ]; then
    read -p "Digite o Usuário Administrador do AD: " AD_USER
fi

if [ -z "$AD_GROUPS" ]; then
    read -p "Digite os Grupos AD (ex: admins suporte): " AD_GROUPS
fi

SSH_GROUPS=$(echo $AD_GROUPS | tr ' ' ',')

echo -e "\n${YELLOW}--- Verificando Pré-requisitos (Red Hat Based) ---${NC}"

# 3. Ferramentas de Diagnóstico (Instala bind-utils para o comando 'host')
if ! command -v host &> /dev/null; then
    sudo dnf install -y bind-utils ntpdate bc > /dev/null 2>&1
fi

echo -n "1. Testando resolução DNS para $AD_DOMAIN... "
DC_IP=$(host -t A "$AD_DOMAIN" | awk '/has address/ {print $4; exit}')

if [ -z "$DC_IP" ]; then
    echo -e "${RED}FALHA${NC}"
    echo "Erro: Não foi possível encontrar o IP do domínio $AD_DOMAIN."
    exit 1
else
    echo -e "${GREEN}OK ($DC_IP)${NC}"
fi

# Verifica se o IP é privado (RFC 1918)
is_private_ip() {
    local ip="$1"
    local octet1=$(echo "$ip" | cut -d. -f1)
    local octet2=$(echo "$ip" | cut -d. -f2)

    # 10.0.0.0/8
    [[ "$octet1" -eq 10 ]] && return 0
    # 172.16.0.0/12 (172.16.x.x - 172.31.x.x)
    [[ "$octet1" -eq 172 && "$octet2" -ge 16 && "$octet2" -le 31 ]] && return 0
    # 192.168.0.0/16
    [[ "$octet1" -eq 192 && "$octet2" -eq 168 ]] && return 0

    return 1
}

if ! is_private_ip "$DC_IP"; then
    echo -e "${YELLOW}AVISO: O IP $DC_IP não é um endereço privado (RFC 1918).${NC}"
    echo -e "${YELLOW}Não é comum um Active Directory exposto com IP público.${NC}"
    read -p "Deseja continuar mesmo assim? (s/N): " CONTINUAR
    if [[ ! "$CONTINUAR" =~ ^[Ss]$ ]]; then
        echo "Operação cancelada pelo usuário."
        exit 0
    fi
fi

# 4. Sincronização de Tempo
echo -n "2. Verificando horário com o AD... "
OFFSET=$(sudo ntpdate -q "$AD_DOMAIN" 2>/dev/null | tail -1 | awk -F'offset ' '{print $2}' | cut -d' ' -f1 | tr -d '-')
if [ ! -z "$OFFSET" ]; then
    IS_DIVERGENT=$(echo "$OFFSET > 300" | bc -l)
    if [ "$IS_DIVERGENT" -eq 1 ]; then
        echo -e "${RED}DIVERGENTE ($OFFSET seg). Sincronizando...${NC}"
        sudo ntpdate -u "$AD_DOMAIN"
    else
        echo -e "${GREEN}OK${NC}"
    fi
fi

# 5. Políticas de Criptografia (Específico RHEL)
echo -e "${YELLOW}Ajustando políticas de criptografia (AD-SUPPORT)...${NC}"
sudo update-crypto-policies --set DEFAULT:AD-SUPPORT

# 6. Instalação de Dependências
echo -e "${YELLOW}Instalando pacotes via DNF/YUM...${NC}"
sudo dnf install -y samba-common-tools realmd oddjob oddjob-mkhomedir sssd adcli krb5-workstation

# 7. Ingressar no Domínio
echo -e "\n${YELLOW}Ingressando no domínio (digite a senha para $AD_USER):${NC}"
sudo realm join -U "$AD_USER" "$AD_DOMAIN" < /dev/tty

if [ $? -ne 0 ]; then
    echo -e "${RED}Erro no 'realm join'.${NC}"
    exit 1
fi

# 8. Configuração do SSSD
echo "Configurando /etc/sssd/sssd.conf..."
sudo bash -c "cat > /etc/sssd/sssd.conf <<EOF
[sssd]
domains = $AD_DOMAIN
config_file_version = 2
services = nss, pam

[domain/$AD_DOMAIN]
ad_domain = $AD_DOMAIN
krb5_realm = ${AD_DOMAIN^^}
realmd_tags = manages-system joined-with-adcli 
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/%u
ad_gpo_access_control = permissive
ad_gpo_ignore_unreadable = True
EOF"

sudo chmod 600 /etc/sssd/sssd.conf
sudo systemctl restart sssd

# 9. Ativar SSSD e Home Directory (Específico RHEL via authselect)
echo "Ativando SSSD no sistema..."
sudo authselect select sssd with-mkhomedir --force
sudo systemctl enable --now oddjobd.service

# 10. SSH e Sudoers
if [ ! -z "$SSH_GROUPS" ]; then
    echo "Configurando AllowGroups no SSH..."
    if ! grep -q "AllowGroups" /etc/ssh/sshd_config; then
        echo "AllowGroups $SSH_GROUPS" | sudo tee -a /etc/ssh/sshd_config
    else
        sudo sed -i "s/^AllowGroups.*/AllowGroups $SSH_GROUPS/" /etc/ssh/sshd_config
    fi
    sudo systemctl restart sshd
fi

for group in $AD_GROUPS; do
    SUDO_FILE="/etc/sudoers.d/ad-group-${group}"
    echo "%$group ALL=(ALL) ALL" | sudo tee "$SUDO_FILE" > /dev/null
    sudo chmod 0440 "$SUDO_FILE"
done

echo -e "\n${GREEN}Concluído! VM Red Hat integrada ao domínio $AD_DOMAIN.${NC}"