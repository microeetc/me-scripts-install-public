# me-scripts-install-public

Scripts para configuração automática via curl
Repositório público para permitir download e execução de qualquer dispositivo

## Ubuntu

```bash
# Setup Inicial
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/ubuntu/setup.sh | sh

# Domain Join (requer revisão)
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/domain-join/ubuntu2204.sh | bash -s -- --domain domain.local --user username --groups "linuxadmins grexample2"
```

## Docker (Qualquer distribuição)
```bash
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/docker/install.sh | sh
```

## Redhat
```bash
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/domain-join/redhat.sh | bash -s -- --domain domain.local --user username --groups "linuxadmins grexample2"
```

#### Links de referência para instalações
https://askubuntu.com/questions/820844/how-do-i-make-bash-history-undeleteable
https://askubuntu.com/questions/503216/how-can-i-set-a-single-bashrc-file-for-several-users
