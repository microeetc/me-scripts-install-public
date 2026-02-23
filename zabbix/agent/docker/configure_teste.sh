#!/usr/bin/env bash

set -e

composeDir="/_docker/me-svc-zabbix-agent"
composeFile="$composeDir/docker-compose.yml"
dotEnv="$composeDir/.env"

ENABLE_PROXY=false

# -------------------------------
# Parse de argumentos
# -------------------------------
for arg in "$@"; do
  case "$arg" in
    --proxy)
      ENABLE_PROXY=true
      ;;
    *)
      echo "Parâmetro desconhecido: $arg"
      exit 1
      ;;
  esac
done

# -------------------------------
# Geração de chaves
# -------------------------------
AGENT_IDENTITY_KEY=$(openssl rand -hex 6)
AGENT_PSK_KEY=$(openssl rand -hex 24)

if [ "$ENABLE_PROXY" = true ]; then
  PROXY_IDENTITY_KEY=$(openssl rand -hex 6)
  PROXY_PSK_KEY=$(openssl rand -hex 24)
fi

# -------------------------------
# Entrada interativa (sempre via tty)
# -------------------------------
echo -n "IP do Servidor Proxy: "
read Server_Host < /dev/tty

echo -n "Host do Dispositivo (Padrão SPKR - EMPR-LOCL-TP-HOSTNAME): "
read Hostname < /dev/tty

if [ "$ENABLE_PROXY" = true ]; then
  echo -n "Hostname do Proxy: "
  read Proxy_Hostname < /dev/tty
fi

# -------------------------------
# Validação básica
# -------------------------------
if [ -z "$Server_Host" ] || [ -z "$Hostname" ]; then
  echo "Erro: variáveis obrigatórias não informadas."
  exit 1
fi

# -------------------------------
# Estrutura de diretórios
# -------------------------------
mkdir -p "$composeDir/data/zabbix"
mkdir -p "$composeDir/data/zabbix/proxy/db"
mkdir -p "$composeDir/config/zabbix/externalscripts"

# -------------------------------
# Criação do .env
# -------------------------------
echo "SERVER_HOST=$Server_Host" > "$dotEnv"
echo "HOSTNAME=$Hostname" >> "$dotEnv"
echo "KEY_IDENTITY=$AGENT_IDENTITY_KEY" >> "$dotEnv"
echo "KEY_PSK=$AGENT_PSK_KEY" >> "$dotEnv"

echo "$AGENT_PSK_KEY" > "$composeDir/data/zabbix/tls.psk"

if [ "$ENABLE_PROXY" = true ]; then
  echo "PROXY_HOSTNAME=$Proxy_Hostname" >> "$dotEnv"
  echo "PROXY_KEY_IDENTITY=$PROXY_IDENTITY_KEY" >> "$dotEnv"
  echo "PROXY_KEY_PSK=$PROXY_PSK_KEY" >> "$dotEnv"

  echo "$PROXY_PSK_KEY" > "$composeDir/data/zabbix/proxy_tls.psk"
fi

# -------------------------------
# Criação condicional do compose
# -------------------------------
if [ ! -f "$composeFile" ]; then

  if [ "$ENABLE_PROXY" = true ]; then

cat <<EOF > "$composeFile"
services:
  meetc-zabbix-agent:
    container_name: meetc-zabbix-agent
    image: zabbix/zabbix-agent2:7.2.10-alpine
    restart: always
    privileged: true
    user: root
    network_mode: "host"
    pid: "host"
    cap_add:
      - NET_RAW
      - NET_ADMIN
      - SYS_ADMIN
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data/zabbix/tls.psk:/var/lib/zabbix/tls.psk:ro
      - /:/hostroot:ro,rslave
    expose:
      - 10150
    environment:
      - ZBX_SERVER_HOST=\${SERVER_HOST}
      - ZBX_SERVER_PORT=10151
      - ZBX_LISTENIP=0.0.0.0
      - ZBX_LISTENPORT=10150
      - ZBX_HOSTNAME=\${HOSTNAME}
      - ZBX_TIMEOUT=30
      - ZBX_DEBUGLEVEL=3
      - ZBX_TLSPSKFILE=/var/lib/zabbix/tls.psk
      - ZBX_TLSPSKIDENTITY=\${KEY_IDENTITY}
      - ZBX_TLSCONNECT=psk
      - ZBX_TLSACCEPT=psk
      - ZBX_ENABLEREMOTECOMMANDS=1

  zabbix-proxy:
    container_name: zabbix-proxy
    image: zabbix/zabbix-proxy-sqlite3:7.2.10-alpine
    restart: always
    privileged: true
    network_mode: "host"
    pid: "host"
    expose:
      - 10151
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - ./config/zabbix/externalscripts:/usr/lib/zabbix/externalscripts
      - ./data/zabbix/proxy/db:/var/lib/zabbix/db_data:rw
      - ./data/zabbix/proxy_tls.psk:/var/lib/zabbix/tls.psk:ro
    environment:
      - ZBX_SERVER_HOST=144.22.141.222:15151
      - ZBX_HOSTNAME=\${PROXY_HOSTNAME}
      - ZBX_LISTENIP=0.0.0.0
      - ZBX_LISTENPORT=10151
      - ZBX_PROXYMODE=0
      - ZBX_TIMEOUT=30
      - ZBX_DEBUGLEVEL=3
      - ZBX_CONFIGFREQUENCY=60
      - ZBX_TLSPSKFILE=/var/lib/zabbix/tls.psk
      - ZBX_TLSPSKIDENTITY=\${PROXY_KEY_IDENTITY}
      - ZBX_TLSACCEPT=psk
      - ZBX_TLSCONNECT=psk
      - ZBX_ENABLEREMOTECOMMANDS=1
      - ZBX_LOGREMOTECOMMANDS=1
EOF

  else

cat <<EOF > "$composeFile"
services:
  meetc-zabbix-agent:
    container_name: meetc-zabbix-agent
    image: zabbix/zabbix-agent2:7.2.15-alpine
    restart: always
    privileged: true
    user: root
    network_mode: "host"
    pid: "host"
    cap_add:
      - NET_RAW
      - NET_ADMIN
      - SYS_ADMIN
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data/zabbix/tls.psk:/var/lib/zabbix/tls.psk:ro
      - /:/hostroot:ro,rslave
    expose:
      - 10150
    environment:
      - ZBX_SERVER_HOST=\${SERVER_HOST}
      - ZBX_SERVER_PORT=10151
      - ZBX_LISTENIP=0.0.0.0
      - ZBX_LISTENPORT=10150
      - ZBX_HOSTNAME=\${HOSTNAME}
      - ZBX_TIMEOUT=30
      - ZBX_DEBUGLEVEL=3
      - ZBX_TLSPSKFILE=/var/lib/zabbix/tls.psk
      - ZBX_TLSPSKIDENTITY=\${KEY_IDENTITY}
      - ZBX_TLSCONNECT=psk
      - ZBX_TLSACCEPT=psk
EOF

  fi

  echo "docker-compose.yml criado."
else
  echo "docker-compose.yml já existe — não foi alterado."
fi

# -------------------------------
# Output final
# -------------------------------
echo
echo "===================================================================="
echo "Configurações geradas:"
echo "===================================================================="
cat "$dotEnv"
echo "===================================================================="

echo
echo "PSK Agent:"
echo "$AGENT_PSK_KEY"

if [ "$ENABLE_PROXY" = true ]; then
  echo
  echo "PSK Proxy:"
  echo "$PROXY_PSK_KEY"
fi
