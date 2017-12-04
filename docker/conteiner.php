<?php
	header('Content-Type: text/plain');
?>

#!/bin/bash

#Exit immediately if a command exits with a non-zero status.
set -e

#Apt-get updates and installs
apt-get update
apt-get install -y wget git curl vim

#
# Configurações padrões do VI
# sed -i '/<pattern>/s/^/"/g' file ---- insere um comentário (iniciado por " por exemplo)
# sed -i '/<pattern>/s/^"//g' file ---- remove um comentário (iniciado por " por exemplo)
#

sed -i '/set background=dark/s/^"//g' /etc/vim/vimrc
sed -i '/set showcmd/s/^"//g' /etc/vim/vimrc
sed -i '/set showmatch/s/^"//g' /etc/vim/vimrc
sed -i '/set ignorecase/s/^"//g' /etc/vim/vimrc
sed -i '/set smartcase/s/^"//g' /etc/vim/vimrc
sed -i '/set incsearch/s/^"//g' /etc/vim/vimrc
sed -i '/set autowrite/s/^"//g' /etc/vim/vimrc
sed -i '/set hidden/s/^"//g' /etc/vim/vimrc

cat << EOF >> /etc/vim/vimrc
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