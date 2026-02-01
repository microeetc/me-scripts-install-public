#!/bin/bash
zabConf="/etc/zabbix/zabbix_agent2.conf"
PSK_Loc="/etc/zabbix/zabbix_agent2.d/tls.psk"
Identity_Key=$(openssl rand -hex 6)
PSK_KEY=$(openssl rand -hex 24)

#Solicita o IP do Proxy
echo
echo -n "IP do Servidor Proxy: "
read Server_Host
echo

#Solicita o Host do Dipositivo
echo -n "Host do Dispositivo(Padrão SPKR: EMPR-LOCL-TP-HOSTNAME): "
read Hostname
echo

echo "ListenIP=0.0.0.0
ListenPort=10150
PluginSocket=/run/zabbix/agent.plugin.sock
ControlSocket=/run/zabbix/agent.sock
TLSConnect=psk
TLSAccept=psk
TLSPSKFile=/etc/zabbix/zabbix_agent2.d/psk.key
Include=/etc/zabbix/zabbix_agent2.d/plugins.d/*.conf
Include=/etc/zabbix/zabbix_agent2.d/*.conf
PidFile=/run/zabbix/zabbix_agent2.pid
LogFile=/var/log/zabbix/zabbix_agent2.log
LogFileSize=0
DebugLevel=3" > "$zabConf"

echo "Hostname=$Hostname" >> "$zabConf"
echo "Server=$Server_Host" >> "$zabConf"
echo "ServerActive=$Server_Host:10151" >> "$zabConf"
echo "TLSPSKIdentity=$Identity_Key" >> "$zabConf"
echo "#PSK_Key=$PSK_KEY" >> "$zabConf"


echo "$PSK_KEY" > /etc/zabbix/zabbix_agent2.d/psk.key
echo
echo
echo "Configurações salvas em '$zabConf':"
echo

echo "===================================================================="
cat "$zabConf"
echo "===================================================================="