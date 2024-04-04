#!/bin/bash
#
# Instalação: wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/docker.sh | sh
# Link para download: https://docs.docker.com/engine/install/debian/
#

# Exit immediately if a command exits with a non-zero status.
set -e

# Unistall Old
# for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Ubuntu or debian
SYSTEM_ID=$(. /etc/os-release && echo "$ID")

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get -y install ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/${SYSTEM_ID}/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${SYSTEM_ID} \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
