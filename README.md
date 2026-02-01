# me-scripts-install-public

Scripts para configuração automática via curl
Repositório público para permitir download e execução de qualquer dispositivo

## Ubuntu

```bash
# Setup Inicial
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/ubuntu/setup.sh | sh

# Domain Join (requer revisão)
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/ubuntu/domain-join-ubuntu2204.sh | bash -s -- --domain domain.local --user username --groups "linuxadmins grexample2"
```

## Docker (Qualquer distribuição)
```bash
# Instala docker e depenências
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/docker/install.sh | sh
```

## Zabbix Agent
```bash
# Configura o agent.conf do zabbix instalado como serviço
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/zabbix/agent/service/configure.sh | sh

# Configura o .env do zabbix agent configurado como docker compose
# TODO: Incluir no script a cópia do docker-compose.yml via raw.githubusercontent.com
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/zabbix/agent/docker/configure.sh | sh
```

## Zabbix Proxy
```bash
# TODO: Fazer procedimento para instalação do agent e proxy
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
