# me-scripts-install-public

Scripts para configuração automática via curl

# Comandos / Arquivos
- wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/ubuntu/setup.sh | sh
- wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/docker/install.sh | sh

- wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/domain-join/redhat.sh | bash -s -- --domain domain.local --user username --groups "linuxadmins grexample2"
- wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/domain-join/ubuntu2204.sh | bash -s -- --domain domain.local --user username --groups "linuxadmins grexample2"


### Links de referência
https://askubuntu.com/questions/820844/how-do-i-make-bash-history-undeleteable
https://askubuntu.com/questions/503216/how-can-i-set-a-single-bashrc-file-for-several-users
