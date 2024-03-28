#!/bin/bash
#Exit immediately if a command exits with a non-zero status.
set -e

#Apt-get updates and installs
apt-get update
apt-get install -y wget git curl vim htop iftop


# Criando Swap file
dd if=/dev/zero bs=1M count=2048 of=/mnt/2GiB.swap
chmod 600 /mnt/2GiB.swap
mkswap /mnt/2GiB.swap
swapon /mnt/2GiB.swap
echo '/mnt/2GiB.swap swap swap defaults 0 0' | tee -a /etc/fstab


# Configurações do uso do swapp
cat /proc/sys/vm/swappiness
cat /proc/sys/vm/vfs_cache_pressure
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50

cat << EOF >> /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF


# Sao Paulo Timezone
unlink /etc/localtime
ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime


# Configurações padrões do VI
# sed -i '/<pattern>/s/^/"/g' file ---- insere um comentário (iniciado por " por exemplo)
# sed -i '/<pattern>/s/^"//g' file ---- remove um comentário (iniciado por " por exemplo)
sed -i '/set background=dark/s/^"//g' /etc/vim/vimrc
sed -i '/set showcmd/s/^"//g' /etc/vim/vimrc
sed -i '/set showmatch/s/^"//g' /etc/vim/vimrc
sed -i '/set ignorecase/s/^"//g' /etc/vim/vimrc
sed -i '/set smartcase/s/^"//g' /etc/vim/vimrc
sed -i '/set incsearch/s/^"//g' /etc/vim/vimrc
sed -i '/set autowrite/s/^"//g' /etc/vim/vimrc
sed -i '/set hidden/s/^"//g' /etc/vim/vimrc

echo "set mouse-=a" >> ~/.vimrc

cat << EOF >> /etc/vim/vimrc
if has("autocmd")
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
EOF


#
# Profile alias local user
sed -i '/force_color_prompt=yes/s/^#//g' ~/.bashrc

cat << EOF >> ~/.bashrc
alias ls='ls -FlhAv --color=auto'
alias lt='ls -FlhAt --color=auto' 
alias ltr='ls -FlhAtr --color=auto'

export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
EOF