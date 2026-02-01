#!/bin/bash

set -e

echo "### Iniciando Instalação do Zabbix na UDM-Pro ###"

# --- VERIFICAR DEPENDÊNCIAS ---
for cmd in wget unzip openssl; do
    if ! command -v $cmd > /dev/null 2>&1; then
        echo "ERRO: '$cmd' não está instalado. Instale antes de continuar."
        exit 1
    fi
done

# --- CONFIGURAÇÕES ---
echo "### Configurações                             ###"
echo
echo -n "IP do servidor central (formato IP:PORTA)"
read PROXY_SERVER
echo

#Solicita o Host do Dipositivo
echo -n "Host do dispositivo (Padrão: EMPR-LOCL-TP-HOSTNAME): "
read HOSTNAME
echo

# TLS
PSK_IDENTITY=$(openssl rand -hex 6)
PSK_VALUE=$(openssl rand -hex 24)
BIN_URL="https://github.com/microeetc/me-scripts-install-public/releases/latest/download/zabbix-7.2.15-debian11-arm64.zip"

echo "### Instalação                                ###"

# 1. Criar Usuário e Grupo
if ! getent group zabbix > /dev/null; then
    groupadd --system zabbix
fi
if ! getent passwd zabbix > /dev/null; then
    useradd --system -g zabbix -d /var/lib/zabbix -s /sbin/nologin zabbix
fi

# 2. Criar Estrutura de Pastas
mkdir -p /etc/zabbix /var/lib/zabbix /var/lib/zabbix/mibs /var/log/zabbix /etc/zabbix/zabbix_agent2.d /usr/sbin
chown -R zabbix:zabbix /etc/zabbix /var/lib/zabbix /var/log/zabbix /etc/zabbix/zabbix_agent2.d

# 3. Download dos Binários
echo "Baixando binários..."

# Criar diretório temporário para download
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download do ZIP
if ! wget -q -O zabbix.zip "$BIN_URL"; then
    echo "ERRO: Falha ao baixar binários de $BIN_URL"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Extrair ZIP
if ! unzip -q zabbix.zip; then
    echo "ERRO: Falha ao extrair zabbix.zip"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Identificar diretório extraído (zabbix-*-debian11-arm64)
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "zabbix-*" | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    echo "ERRO: Diretório extraído não encontrado"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Copiar binários para /usr/sbin
cp "$EXTRACTED_DIR/zabbix_proxy" /usr/sbin/
cp "$EXTRACTED_DIR/zabbix_agent2" /usr/sbin/
chmod +x /usr/sbin/zabbix_proxy /usr/sbin/zabbix_agent2

# Copiar database inicial (apenas se não existir)
if [ ! -f /var/lib/zabbix/zabbix_proxy.db ]; then
    cp "$EXTRACTED_DIR/zabbix_proxy.db" /var/lib/zabbix/
    chown zabbix:zabbix /var/lib/zabbix/zabbix_proxy.db
    chmod 644 /var/lib/zabbix/zabbix_proxy.db
else
    echo "Database já existe, mantendo dados existentes..."
fi

# Copiar MIBs
if [ -d "$EXTRACTED_DIR/mibs" ]; then
    cp -r "$EXTRACTED_DIR/mibs/"* /var/lib/zabbix/mibs/
    chown -R zabbix:zabbix /var/lib/zabbix/mibs
fi

# Limpar diretório temporário
cd /
rm -rf "$TMP_DIR"

echo "Binários instalados com sucesso!"

# 4. Criar Arquivo PSK
echo "$PSK_VALUE" > /etc/zabbix/secret.psk
chown zabbix:zabbix /etc/zabbix/secret.psk
chmod 600 /etc/zabbix/secret.psk

# 5. Criar Configuração do Proxy
cat <<EOF > /etc/zabbix/zabbix_proxy.conf
Server=$PROXY_SERVER
Hostname=$HOSTNAME-proxy
ListenIP=0.0.0.0
ListenPort=10151
ProxyMode=0
Timeout=30
DebugLevel=0
ProxyConfigFrequency=120
TLSPSKIdentity=$PSK_IDENTITY
TLSPSKFile=/etc/zabbix/secret.psk
TLSAccept=psk
TLSConnect=psk
EnableRemoteCommands=0
LogRemoteCommands=1
LogFile=/var/log/zabbix/zabbix_proxy.log
DBName=/var/lib/zabbix/zabbix_proxy.db
DataSenderFrequency=2
EOF

# 6. Criar Configuração do Agent 2
cat <<EOF > /etc/zabbix/zabbix_agent2.conf
Hostname=$HOSTNAME
ListenIP=0.0.0.0
ListenPort=10150
Server=127.0.0.1
ServerActive=127.0.0.1:10151
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=$PSK_IDENTITY
TLSPSKFile=/etc/zabbix/secret.psk
Include=/etc/zabbix/zabbix_agent2.d/*.conf
ControlSocket=/tmp/agent.sock
LogFile=/var/log/zabbix/zabbix_agent2.log
DebugLevel=0
Timeout=30
EOF

# 7. Criar Serviços Systemd
cat <<EOF > /etc/systemd/system/zabbix-proxy.service
[Unit]
Description=Zabbix Proxy (Static)
After=network.target

[Service]
Type=simple
User=zabbix
Group=zabbix
ExecStart=/usr/sbin/zabbix_proxy -f -c /etc/zabbix/zabbix_proxy.conf
Restart=on-failure
RestartSec=5
Environment="MIBDIRS=/var/lib/zabbix/mibs"

[Install]
WantedBy=multi-user.target
Alias=zabbix-proxy.service
EOF

cat <<EOF > /etc/systemd/system/zabbix-agent2.service
[Unit]
Description=Zabbix Agent 2 (Static)
After=network.target

[Service]
Type=simple
User=zabbix
Group=zabbix
ExecStart=/usr/sbin/zabbix_agent2 -f -c /etc/zabbix/zabbix_agent2.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
Alias=zabbix-agent.service
EOF

# 8. Habilitar e Iniciar
systemctl daemon-reload
systemctl enable zabbix-proxy zabbix-agent2
systemctl restart zabbix-proxy zabbix-agent2

echo ""
echo "###############################################################################"
echo "###                    INSTALAÇÃO CONCLUÍDA COM SUCESSO!                    ###"
echo "###############################################################################"
echo ""
echo "=== INFORMAÇÕES PARA CONFIGURAÇÃO NO ZABBIX SERVER ==="
echo ""
echo "--- PROXY ---"
echo "  Nome do Proxy:      ${HOSTNAME}-proxy"
echo "  Modo:               Ativo"
echo "  Criptografia:       Connections from proxy: PSK"
echo ""
echo "--- HOST (DEVICE) ---"
echo "  Nome do Host:       ${HOSTNAME}"
echo "  Grupo:              <DEFINIR_GRUPO> (lembrar do padrão Empresa xxxx)"
echo "  Interface Agent:    127.0.0.1:10150"
echo "  Monitorado via:     ${HOSTNAME}-proxy"
echo ""
echo "--- CRIPTOGRAFIA PSK (usar no Proxy E no Host) ---"
echo "  PSK Identity:       ${PSK_IDENTITY}"
echo "  PSK (Chave):        ${PSK_VALUE}"
echo ""
echo "--- SERVIDOR ZABBIX CONFIGURADO ---"
echo "  Server:             ${PROXY_SERVER}"
echo ""
echo "###############################################################################"
echo ""
echo ""
echo "Logs disponíveis em:"
echo "  - Proxy:   /var/log/zabbix/zabbix_proxy.log"
echo "  - Agent2:  /var/log/zabbix/zabbix_agent2.log"
echo ""
echo "Comandos úteis:"
echo "  systemctl status zabbix-proxy zabbix-agent2"
echo "  journalctl -u zabbix-proxy -f"
echo "  journalctl -u zabbix-agent2 -f"
echo ""



