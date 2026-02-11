#!/bin/bash

# Se executado via pipe, baixar e re-executar o script
if [ ! -t 0 ] && [ -z "$ZABBIX_INSTALL_REEXEC" ]; then
    SCRIPT_URL="https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/zabbix/udm/install.sh"
    TMP_SCRIPT="/tmp/zabbix-install-$$.sh"
    wget -q -O "$TMP_SCRIPT" "$SCRIPT_URL"
    chmod +x "$TMP_SCRIPT"
    export ZABBIX_INSTALL_REEXEC=1
    exec bash "$TMP_SCRIPT" </dev/tty
    exit 0
fi

echo "### Iniciando Instalacao do Zabbix na UDM-Pro ###"

# --- VERIFICAR DEPENDENCIAS ---
which wget > /dev/null 2>&1 || { echo "ERRO: 'wget' nao esta instalado."; exit 1; }
which unzip > /dev/null 2>&1 || { echo "ERRO: 'unzip' nao esta instalado."; exit 1; }
which openssl > /dev/null 2>&1 || { echo "ERRO: 'openssl' nao esta instalado."; exit 1; }

# --- VERIFICAR CONFIGURACAO EXISTENTE ---
EXISTING_CONFIG=0
if [ -f /etc/zabbix/zabbix_proxy.conf ] && [ -f /etc/zabbix/zabbix_agent2.conf ] && [ -f /etc/zabbix/secret.psk ]; then
    echo "### Configuracao existente detectada ###"
    echo

    # Extrair valores existentes
    PROXY_SERVER=$(grep "^Server=" /etc/zabbix/zabbix_proxy.conf | cut -d'=' -f2)
    HOSTNAME=$(grep "^Hostname=" /etc/zabbix/zabbix_agent2.conf | cut -d'=' -f2)
    PSK_IDENTITY=$(grep "^TLSPSKIdentity=" /etc/zabbix/zabbix_proxy.conf | cut -d'=' -f2)
    PSK_VALUE=$(cat /etc/zabbix/secret.psk)

    # Verificar se todos os valores foram extraidos
    if [ -n "$PROXY_SERVER" ] && [ -n "$HOSTNAME" ] && [ -n "$PSK_IDENTITY" ] && [ -n "$PSK_VALUE" ]; then
        EXISTING_CONFIG=1
        echo "  Configuracao encontrada:"
        echo "    Server:       $PROXY_SERVER"
        echo "    Hostname:     $HOSTNAME"
        echo "    PSK Identity: $PSK_IDENTITY"
        echo "    PSK Value:    ${PSK_VALUE:0:12}..."
        echo
        echo "  Usando configuracao existente (reinstalacao)."
        echo
    else
        echo "  Configuracao incompleta, solicitando novos dados..."
        echo
        EXISTING_CONFIG=0
    fi
fi

# --- CONFIGURACOES ---
if [ "$EXISTING_CONFIG" -eq 0 ]; then
    echo "### Configuracoes ###"
    echo
    echo -n "IP do servidor central (formato IP:PORTA): "
    read PROXY_SERVER
    echo

    echo -n "Host do dispositivo (Padrao: EMPR-LOCL-TP-HOSTNAME): "
    read HOSTNAME
    echo

    # TLS - Gerar novos valores
    PSK_IDENTITY=$(openssl rand -hex 6)
    PSK_VALUE=$(openssl rand -hex 24)
fi

BIN_URL="https://github.com/microeetc/me-scripts-install-public/releases/download/zabbix-7.2.15-debian11-arm64.zip"

echo "### Instalacao ###"

# 1. Criar Usuario e Grupo
echo "  [1/10] Criando usuario e grupo..."
if ! getent group zabbix > /dev/null; then
    groupadd --system zabbix
fi
if ! getent passwd zabbix > /dev/null; then
    useradd --system -g zabbix -d /var/lib/zabbix -s /sbin/nologin zabbix
fi

# 2. Criar Estrutura de Pastas
echo "  [2/10] Criando estrutura de pastas..."
mkdir -p /etc/zabbix /var/lib/zabbix /var/lib/zabbix/mibs /var/log/zabbix /etc/zabbix/zabbix_agent2.d /etc/zabbix/externalscripts /usr/sbin
chown -R zabbix:zabbix /etc/zabbix /var/lib/zabbix /var/log/zabbix

# 3. Download dos Binarios
echo "  [3/10] Baixando binarios (pode demorar)..."

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

wget --progress=bar:force -O zabbix.zip "$BIN_URL" 2>&1 || {
    echo "ERRO: Falha ao baixar binarios de $BIN_URL"
    rm -rf "$TMP_DIR"
    exit 1
}

echo "  [4/10] Extraindo arquivos..."
unzip -q zabbix.zip || {
    echo "ERRO: Falha ao extrair zabbix.zip"
    rm -rf "$TMP_DIR"
    exit 1
}

EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "zabbix-*" | head -1)
if [ -z "$EXTRACTED_DIR" ]; then
    echo "ERRO: Diretorio extraido nao encontrado"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Parar servicos se existirem (para substituir binarios em uso)
if systemctl is-active --quiet zabbix-proxy 2>/dev/null || systemctl is-active --quiet zabbix-agent2 2>/dev/null; then
    echo "  [5/10] Parando servicos existentes..."
    systemctl stop zabbix-proxy zabbix-agent2 2>/dev/null
fi

echo "  [6/10] Copiando binarios..."
cp "$EXTRACTED_DIR/zabbix_proxy" /usr/sbin/
cp "$EXTRACTED_DIR/zabbix_agent2" /usr/sbin/
chmod +x /usr/sbin/zabbix_proxy /usr/sbin/zabbix_agent2

# Copiar fping (necessario para ICMP checks)
if [ -f "$EXTRACTED_DIR/fping" ]; then
    cp "$EXTRACTED_DIR/fping" /usr/sbin/fping
    chmod 4755 /usr/sbin/fping  # setuid para raw sockets (zabbix user)
    echo "  fping instalado!"
fi

if [ ! -f /var/lib/zabbix/zabbix_proxy.db ]; then
    cp "$EXTRACTED_DIR/zabbix_proxy.db" /var/lib/zabbix/
    chown zabbix:zabbix /var/lib/zabbix/zabbix_proxy.db
    chmod 644 /var/lib/zabbix/zabbix_proxy.db
else
    echo "  Database ja existe, mantendo dados existentes..."
fi

if [ -d "$EXTRACTED_DIR/mibs" ]; then
    cp -r "$EXTRACTED_DIR/mibs/"* /var/lib/zabbix/mibs/
    chown -R zabbix:zabbix /var/lib/zabbix/mibs
fi

# Copiar scripts externos
if [ -d "$EXTRACTED_DIR/externalscripts" ]; then
    cp "$EXTRACTED_DIR/externalscripts/"* /etc/zabbix/externalscripts/
    chmod +x /etc/zabbix/externalscripts/*
    chown -R zabbix:zabbix /etc/zabbix/externalscripts
    echo "  Scripts externos instalados!"
fi

cd /
rm -rf "$TMP_DIR"

echo "  Binarios instalados!"

# 6. Criar Arquivo PSK
echo "  [7/10] Criando arquivo PSK..."
echo "$PSK_VALUE" > /etc/zabbix/secret.psk
chown zabbix:zabbix /etc/zabbix/secret.psk
chmod 600 /etc/zabbix/secret.psk
echo "        PSK criado."

# 7. Criar Configuracao do Proxy
echo "  [8/10] Criando arquivos de configuracao..."
echo "        Criando zabbix_proxy.conf..."
cat > /etc/zabbix/zabbix_proxy.conf << 'CONFIGEND'
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
ExternalScripts=/etc/zabbix/externalscripts
FpingLocation=/usr/sbin/fping
CONFIGEND
sed -i "s/\$PROXY_SERVER/$PROXY_SERVER/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/\$HOSTNAME/$HOSTNAME/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/\$PSK_IDENTITY/$PSK_IDENTITY/g" /etc/zabbix/zabbix_proxy.conf

echo "        Criando zabbix_agent2.conf..."
cat > /etc/zabbix/zabbix_agent2.conf << 'CONFIGEND'
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
CONFIGEND
sed -i "s/\$HOSTNAME/$HOSTNAME/g" /etc/zabbix/zabbix_agent2.conf
sed -i "s/\$PSK_IDENTITY/$PSK_IDENTITY/g" /etc/zabbix/zabbix_agent2.conf

# 8. Criar Servicos Systemd
echo "  [9/10] Criando e iniciando servicos..."
cat > /etc/systemd/system/zabbix-proxy.service << 'SERVICEEND'
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
SERVICEEND

cat > /etc/systemd/system/zabbix-agent2.service << 'SERVICEEND'
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
SERVICEEND

# 8. Habilitar e Iniciar
systemctl daemon-reload
systemctl enable zabbix-proxy zabbix-agent2
systemctl restart zabbix-proxy zabbix-agent2

echo ""
echo "###############################################################################"
echo "###                    INSTALACAO CONCLUIDA COM SUCESSO!                    ###"
echo "###############################################################################"
echo ""
echo "=== INFORMACOES PARA CONFIGURACAO NO ZABBIX SERVER ==="
echo ""
echo "--- PROXY ---"
echo "  Nome do Proxy:      ${HOSTNAME}-proxy"
echo "  Modo:               Ativo"
echo "  Criptografia:       Connections from proxy: PSK"
echo ""
echo "--- HOST (DEVICE) ---"
echo "  Nome do Host:       ${HOSTNAME}"
echo "  Grupo:              <DEFINIR_GRUPO>"
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
echo "Logs disponiveis em:"
echo "  - Proxy:   /var/log/zabbix/zabbix_proxy.log"
echo "  - Agent2:  /var/log/zabbix/zabbix_agent2.log"
echo ""
echo "Comandos uteis:"
echo "  systemctl status zabbix-proxy zabbix-agent2"
echo "  journalctl -u zabbix-proxy -f"
echo "  journalctl -u zabbix-agent2 -f"
echo ""
