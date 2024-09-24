#!/bin/bash
#
# Instalação: wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/ubuntu.sh | sh
#
#Exit immediately if a command exits with a non-zero status.
set -e

#Apt-get updates and installs
apt-get update
apt-get install -y wget git curl vim htop iftop sudo


# Criando Swap file
echo "Configurações de Swap"
dd if=/dev/zero bs=1M count=2048 of=/mnt/2GiB.swap
chmod 600 /mnt/2GiB.swap
mkswap /mnt/2GiB.swap
swapon /mnt/2GiB.swap
echo '/mnt/2GiB.swap swap swap defaults 0 0' | tee -a /etc/fstab


# Configurações do uso do swapp
# O parâmetro swappiness controla a tendência do kernel de mover processos da memória RAM para a swap. Um valor mais baixo faz com que o sistema use menos swap e mantenha mais dados na RAM.
# Alterar valor :  sudo sed -i 's/^vm.swappiness=.*/vm.swappiness=20/' /etc/sysctl.conf && sysctl -p
cat /proc/sys/vm/swappiness
sysctl vm.swappiness=10
cat << EOF >> /etc/sysctl.conf
vm.swappiness=10
EOF

# O vfs_cache_pressure determina com que frequência o kernel deve liberar a memória usada para cache de inodes e dentries (estruturas que representam arquivos e diretórios no sistema de arquivos).
# Valor Padrão  :  O valor padrão é 100, o que significa que o kernel trata a memória usada para cache de VFS e a memória usada para pagecache de forma igual.
# Valores Altos :  Valores acima de 100 fazem com que o kernel libere a memória de cache de VFS mais agressivamente. Isso pode ser útil em sistemas com pouca memória, mas pode reduzir o desempenho ao acessar arquivos e diretórios frequentemente.
# Valores Baixos:  Valores abaixo de 100 fazem com que o kernel mantenha mais memória para cache de VFS, o que pode melhorar o desempenho ao acessar arquivos e diretórios, mas pode reduzir a memória disponível para outros usos12.
# Limpar o cache:  sudo sync; sudo echo 3 > /proc/sys/vm/drop_caches
# Alterar valor :  sudo sed -i 's/^vm.vfs_cache_pressure=.*/vm.vfs_cache_pressure=90/' /etc/sysctl.conf && sysctl -p
cat /proc/sys/vm/vfs_cache_pressure
sysctl vm.vfs_cache_pressure=50
cat << EOF >> /etc/sysctl.conf
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


# Profile alias local user
sed -i '/force_color_prompt=yes/s/^#//g' ~/.bashrc

cat << EOF >> ~/.bashrc
alias ls='ls -FlhAv --color=auto'
alias lt='ls -FlhAt --color=auto' 
alias ltr='ls -FlhAtr --color=auto'

export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=3000
export HISTFILESIZE=20000

# add timestamp to history command output
export HISTTIMEFORMAT="%F %T "
EOF