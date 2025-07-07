#!/bin/bash
#
# Instalação: wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/zabbix-agent.sh | sh
# Link para download: https://www.zabbix.com/download
#

# Exit immediately if a command exits with a non-zero status.
set -e

# Variables
ZABBIX_VERSION="7.2.10"

# Get versions
VERSION_ID=$(. /etc/os-release && echo "$VERSION_ID")
SYSTEM_ID=$(. /etc/os-release && echo "$ID")

# Is ARM or X64?
ARM=""
if dpkg --print-architecture | grep -q "arm64"; then
  ARM="-arm64"
fi

# Filename
FILENAME="zabbix-release_${ZABBIX_VERSION}+${SYSTEM_ID}${VERSION_ID}_all.deb"

# Download Zabbix Versions
wget https://repo.zabbix.com/zabbix/6.4/${SYSTEM_ID}${ARM}/pool/main/z/zabbix-release/${FILENAME}

dpkg -i ${FILENAME}
apt update
apt install zabbix-agent2 zabbix-agent2-plugin-*
systemctl restart zabbix-agent2
systemctl enable zabbix-agent2






# Link download examples
# wget https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian12_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian11_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian10_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian9_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu18.04_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu16.04_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu14.04_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/ubuntu-arm64/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
# wget https://repo.zabbix.com/zabbix/6.4/ubuntu-arm64/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb


