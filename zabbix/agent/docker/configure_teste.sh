#!/bin/bash

dotEnv=".env"
composeDir="/_docker/me-svc-zabbix-agent"
composeFile="$composeDir/docker-compose.yml"

Identity_Key=$(openssl rand -hex 6)
PSK_KEY=$(openssl rand -hex 24)

# Solicita o IP do Proxy
echo -n "IP do Servidor Proxy: "
read Server_Host

# Solicita o Host do Dispositivo
echo -n "Host do Dispositivo (Padrão SPKR - EMPR-LOCL-TP-HOSTNAME): "
read Hostname

# Cria diretório do compose caso não exista
mkdir -p "$composeDir"

# Cria o .env dentro do diretório do compose
dotEnv="$composeDir/.env"

echo "SERVER_HOST=$Server_Host" > "$dotEnv"
echo "HOSTNAME=$Hostname" >> "$dotEnv"
echo "KEY_IDENTITY=$Identity_Key" >> "$dotEnv"
echo "KEY_PSK=$PSK_KEY" >> "$dotEnv"

# Cria diretório do PSK
mkdir -p "$composeDir/data/zabbix/"

echo "$PSK_KEY" > "$composeDir/data/zabbix/tls.psk"

# Cria docker-compose.yml apenas se não existir
if [ ! -f "$composeFile" ]; then
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

echo "docker-compose.yml criado em $composeDir"
else
echo "docker-compose.yml já existe em $composeDir — não foi alterado."
fi

echo
echo "Configurações salvas em '$dotEnv':"
echo "===================================================================="
cat "$dotEnv"
echo "===================================================================="
