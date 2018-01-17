<?php
	header('Content-Type: text/plain');
?>

#!/bin/bash

#Exit immediately if a command exits with a non-zero status.
set -e

#Apt-get updates and installs
sudo apt-get update
sudo apt-get install -y wget git curl vim


# Install Docker
sudo wget -qO- https://get.docker.com/ | sh


# Install docker-compose
sudo true
COMPOSE_VERSION=`git ls-remote https://github.com/docker/compose | grep refs/tags | grep -oP "[0-9]+\.[0-9][0-9]+\.[0-9]+$" | tail -n 1`

sudo sh -c "curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"

sudo chmod +x /usr/local/bin/docker-compose

sudo sh -c "curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"


#
# Criando Swap file
#

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile



#
# Configurações padrões do VI
# sed -i '/<pattern>/s/^/"/g' file ---- insere um comentário (iniciado por " por exemplo)
# sed -i '/<pattern>/s/^"//g' file ---- remove um comentário (iniciado por " por exemplo)
#

sudo sed -i '/set background=dark/s/^"//g' /etc/vim/vimrc
sudo sed -i '/set showcmd/s/^"//g' /etc/vim/vimrc
sudo sed -i '/set showmatch/s/^"//g' /etc/vim/vimrc
sudo sed -i '/set ignorecase/s/^"//g' /etc/vim/vimrc
sudo sed -i '/set smartcase/s/^"//g' /etc/vim/vimrc
sudo sed -i '/set incsearch/s/^"//g' /etc/vim/vimrc
sudo sed -i '/set autowrite/s/^"//g' /etc/vim/vimrc
sudo sed -i '/set hidden/s/^"//g' /etc/vim/vimrc

sudo cat << EOF >> /etc/vim/vimrc
if has("autocmd")
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
EOF

#
# Profile alias local user
#

sed -i '/force_color_prompt=yes/s/^#//g' ~/.bashrc

cat << EOF >> ~/.bashrc
alias ls='ls -FlhAv --color=auto'
alias lt='ls -FlhAt --color=auto' 
alias ltr='ls -FlhAtr --color=auto'

export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
EOF
