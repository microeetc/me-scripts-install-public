# me-scripts-install-public

Scripts para configuração automática via curl
Repositório público para permitir download e execução de qualquer dispositivo

## Ubuntu

```bash
# Setup Inicial
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/ubuntu/setup.sh | sh

# Domain Join
```bash
wget https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/ubuntu/domain-join-ubuntu2204.sh
chmod +x domain-join-ubuntu2204_NEW.sh
./domain-join-ubuntu2204_NEW.sh --domain <domain.local> --user <userlogim> --groups "<grupos_acesso_ssh>"
```
```

## Docker (Qualquer distribuição)
```bash
# Instala docker e depenências
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/docker/install.sh | sh
```

## Zabbix Agent
```bash
# Configura o agent.conf do zabbix instalado como SERVIÇO
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/zabbix/agent/service/configure.sh | sh

# Cria o docker-compose.yml e configura o .env com as informações solicitadas para o Zabbix Agent em DOCKER
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/zabbix/agent/docker/configure.sh | sh
```

## Zabbix Proxy
```bash
# Cria o docker-compose.yml e configura o .env com as informações solicitadas para o Zabbix Proxy e Zabbix Agent em DOCKER
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/zabbix/agent/docker/configure.sh | bash -s -- --proxy
```

## Zabbix no UDM
```bash
# Download dos binários e configuração
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/zabbix/udm/install.sh | sh
```

## Redhat
```bash
# Domain Join (requer revisão)
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/redhat/domain-join.sh | bash -s -- --domain domain.local --user username --groups "linuxadmins grexample2"
```

#### Links de referência para instalações
https://askubuntu.com/questions/820844/how-do-i-make-bash-history-undeleteable
https://askubuntu.com/questions/503216/how-can-i-set-a-single-bashrc-file-for-several-users
