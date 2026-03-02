#!/usr/bin/env bash

set -euo pipefail

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
# Funções
# -------------------------------

ensure_structure() {
  echo ">> Verificando estrutura..."

  mkdir -p "$composeDir"
  mkdir -p "$composeDir/data/zabbix"
  mkdir -p "$composeDir/data/zabbix/proxy/db"
  mkdir -p "$composeDir/config/zabbix/externalscripts"

  chmod -R 750 "$composeDir"

  echo ">> Estrutura validada."
}

generate_keys() {
  AGENT_IDENTITY_KEY=$(openssl rand -hex 6)
  AGENT_PSK_KEY=$(openssl rand -hex 24)

  if [ "$ENABLE_PROXY" = true ]; then
    PROXY_IDENTITY_KEY=$(openssl rand -hex 6)
    PROXY_PSK_KEY=$(openssl rand -hex 24)
  fi
}

create_env_file() {
  if [[ -f "$dotEnv" ]]; then
    echo ">> .env já existe, será sobrescrito."
  else
    echo ">> Criando .env"
    touch "$dotEnv"
  fi

  > "$dotEnv"

  echo "SERVER_HOST=$Server_Host" >> "$dotEnv"
  echo "AGENT_HOST=$Agent_Hostname" >> "$dotEnv"
  echo "KEY_IDENTITY=$AGENT_IDENTITY_KEY" >> "$dotEnv"
  echo "KEY_PSK=$AGENT_PSK_KEY" >> "$dotEnv"

  if [ "$ENABLE_PROXY" = true ]; then
    echo "PROXY_HOSTNAME=$Proxy_Hostname" >> "$dotEnv"
    echo "PROXY_KEY_IDENTITY=$PROXY_IDENTITY_KEY" >> "$dotEnv"
    echo "PROXY_KEY_PSK=$PROXY_PSK_KEY" >> "$dotEnv"
  fi
}

create_psk_files() {
  echo "$AGENT_PSK_KEY" > "$composeDir/data/zabbix/tls.psk"
  chmod 600 "$composeDir/data/zabbix/tls.psk"

  if [ "$ENABLE_PROXY" = true ]; then
    echo "$PROXY_PSK_KEY" > "$composeDir/data/zabbix/proxy_tls.psk"
    chmod 600 "$composeDir/data/zabbix/proxy_tls.psk"
  fi
}

create_compose_file() {

  if [[ -f "$composeFile" ]]; then
    echo ">> docker-compose.yml já existe, será sobrescrito."
  else
    echo ">> Criando docker-compose.yml"
    touch "$composeFile"
  fi

  if [ "$ENABLE_PROXY" = true ]; then

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
      - ZBX_SERVER_HOST=${SERVER_HOST}
      - ZBX_SERVER_PORT=10151
      - ZBX_LISTENIP=0.0.0.0
      - ZBX_LISTENPORT=10150
      - ZBX_HOSTNAME=${AGENT_HOST}
      - ZBX_TIMEOUT=30
      - ZBX_DEBUGLEVEL=3
      - ZBX_TLSPSKFILE=/var/lib/zabbix/tls.psk
      - ZBX_TLSPSKIDENTITY=${KEY_IDENTITY}
      - ZBX_TLSCONNECT=psk
      - ZBX_TLSACCEPT=psk
      - ZBX_ENABLEREMOTECOMMANDS=1

  zabbix-proxy:
    container_name: zabbix-proxy
    image: zabbix/zabbix-proxy-sqlite3:7.2.15-alpine
    restart: always
    privileged: true
    network_mode: "host"
    pid: "host"
    expose:
      - 10151
    volumes:
      - ./data/zabbix/proxy/db:/var/lib/zabbix/db_data
      - ./data/zabbix/proxy_tls.psk:/var/lib/zabbix/tls.psk:ro
      - ./config/zabbix/externalscripts:/usr/lib/zabbix/externalscripts
    environment:
      - ZBX_SERVER_HOST=144.22.141.222:15151
      - ZBX_HOSTNAME=${PROXY_HOSTNAME}
      - ZBX_LISTENIP=0.0.0.0
      - ZBX_LISTENPORT=10151
      - ZBX_PROXYMODE=0
      - ZBX_TIMEOUT=30
      - ZBX_DEBUGLEVEL=3
      - ZBX_CONFIGFREQUENCY=60
      - ZBX_TLSPSKFILE=/var/lib/zabbix/tls.psk
      - ZBX_TLSPSKIDENTITY=${PROXY_KEY_IDENTITY}
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
      - ZBX_HOSTNAME=\${AGENT_HOST}
      - ZBX_TIMEOUT=30
      - ZBX_DEBUGLEVEL=3
      - ZBX_TLSPSKFILE=/var/lib/zabbix/tls.psk
      - ZBX_TLSPSKIDENTITY=\${KEY_IDENTITY}
      - ZBX_TLSCONNECT=psk
      - ZBX_TLSACCEPT=psk
EOF

  fi
}

# -------------------------------
# Execução
# -------------------------------

ensure_structure
generate_keys

if [ "$ENABLE_PROXY" = true ]; then
  echo -n "Hostname do Proxy (Padrão SPKR - NOMECLIENTE-LOCL-HOSTNAME-PROXY):"
  read Proxy_Hostname < /dev/tty
fi

echo -n "IP do Servidor Proxy: "
read Server_Host < /dev/tty

echo -n "Host do Agent (Padrão SPKR - EMPR-LOCL-TP-HOSTNAME):"
read Agent_Hostname < /dev/tty

if [[ -z "$Server_Host" || -z "$Agent_Hostname" ]]; then
  echo "Erro: variáveis obrigatórias não informadas."
  exit 1
fi

if [ "$ENABLE_PROXY" = true ] && [[ -z "$Proxy_Hostname" ]]; then
  echo "Erro: Hostname do proxy não informado."
  exit 1
fi

create_env_file
create_psk_files
create_compose_file
chown -R 1997:1997 "$composeDir/data/zabbix/"

echo ""
echo "##########################################################################" 
echo "### INSTALACAO CONCLUIDA COM SUCESSO! ###" 
echo "##########################################################################" 
echo "" 
echo "=== INFORMACOES PARA CONFIGURACAO NO ZABBIX SERVER ===" 
echo "" 
echo "--- PROXY ---" 
echo " Nome do Proxy......: ${Proxy_Hostname}" 
echo " PSK Identity.......: ${PROXY_IDENTITY_KEY}" 
echo " PSK Key............: ${PROXY_PSK_KEY}" 
echo "" 
echo "--- HOST AGENT ---" 
echo " Nome do Host.......: ${Agent_Hostname}" 
echo " IP do Host.........: ${Server_Host}" 
echo " Porta de Conexao...: 10150" 
echo " PSK Identity.......: ${AGENT_IDENTITY_KEY}" 
echo " PSK Key............: ${AGENT_PSK_KEY}" 
echo "" 
echo "##########################################################################"

echo ""
echo "Arquivos criados em: $composeDir"
echo ""
echo "Para subir os containers:"
echo "cd $composeDir && docker compose up -d"
echo ""
