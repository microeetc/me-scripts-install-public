#!/bin/bash
dotEnv=".env"
Identity_Key=$(openssl rand -hex 6)
PSK_KEY=$(openssl rand -hex 24)

#Solicita o IP do Proxy
echo -n "IP do Servidor Proxy: "
read Server_Host

#Solicita o Host do Dipositivo
echo -n "Host do Dispositivo(Padrão SPKR - EMPR-LOCL-TP-HOSTNAME): "
read Hostname


echo "SERVER_HOST=$Server_Host" > "$dotEnv"
echo "HOSTNAME=$Hostname" >> "$dotEnv"
echo "KEY_IDENTITY=$Identity_Key" >> "$dotEnv"
echo "KEY_PSK=$PSK_KEY" >> "$dotEnv"

mkdir -p ./data/zabbix/
echo "$PSK_KEY" > ./data/zabbix/tls.psk


echo "Configurações salvas em '$dotEnv':"
echo "===================================================================="
cat "$dotEnv"
echo "===================================================================="