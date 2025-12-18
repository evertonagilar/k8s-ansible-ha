#!/bin/bash
#
# Objetivos do script:
# ====================================================================
# * Configurar /etc/hosts
# * Configurar locale pt_BR.UTF-8
# * Configurar o timezone para America/Sao_Paulo
# * Instalação de pacotes básicos
# * Criar /etc/apt/keyrings se não existe
# * Configurar o vim
#
#
#######################################################################

echo '------------------------ Faz a cofiguração básica no SO ------------------------'

export DEBIAN_FRONTEND=noninteractive


echo "Atualizando repositório apt"
apt update
echo 'Instalação de pacotes básicos'
apt install -y git vim apt-transport-https ca-certificates curl wget gnupg lsb-release

### --------------------------------


echo 'Configurar o locale pt_BR.UTF-8'
export LANG=pt_BR.UTF-8
sed -i "s/# pt_BR.UTF-8 UTF-8/${LANG} UTF-8/" /etc/locale.gen
locale-gen


### --------------------------------


echo 'Configurar o timezone para America/Sao_Paulo'
echo America/Sao_Paulo | tee /etc/timezone
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

### --------------------------------


echo 'Criar /etc/apt/keyrings se não existe'
mkdir -p /etc/apt/keyrings
chmod 755 -R /etc/apt/keyrings


### --------------------------------


echo 'Configurar o vim'
cat << EOF > /root/.vimrc
set nomodeline
set bg=dark
set tabstop=2
set expandtab
set ruler
set nu
syntax on
EOF
cp /root/.vimrc /home/vagrant/.vimrc && chown vagrant:vagrant /home/vagrant/.vimrc


### --------------------------------


echo 'Instalação dos módulos do Linux Kernel'
cat << EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
nf_nat
xt_REDIRECT
xt_owner
iptable_nat
iptable_mangle
iptable_filter
EOF
modprobe overlay
modprobe br_netfilter


### --------------------------------


echo 'Configurar sysctl para o Kubernetes'
cat << EOF | tee /etc/sysctl.d/100-k8s.conf
kernel.shmall = 2097152
kernel.shmmax = 4294967295
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv6.conf.all.forwarding = 1
fs.aio-max-nr = 1048576
fs.file-max = 6815744
EOF
sysctl --system


### --------------------------------


