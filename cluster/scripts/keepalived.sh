#!/bin/bash
#
# Instalar o load balancer do cluster Kubernetes
#
#
#######################################################################

echo 'Instalar o keepalived'
apt install -y keepalived


### --------------------------------


echo 'Criar o script para monitoramento da API /etc/keepalived/check_apiserver.sh'
envsubst < config/check_apiserver.sh | tee /etc/keepalived/check_apiserver.sh


### --------------------------------

echo 'Criar o arquivo de configuração do keepalived'
envsubst < config/keepalived.conf | tee /etc/keepalived/keepalived.conf


### --------------------------------

echo 'Criar o usuário keepalived_script para o script /etc/keepalived/check_apiserver.sh'
adduser --system --no-create-home --disabled-password --disabled-login keepalived_script
chown keepalived_script /etc/keepalived/check_apiserver.sh
chmod +x /etc/keepalived/check_apiserver.sh


### --------------------------------

echo 'Habilitar o serviço keepalived'
systemctl enable --now keepalived

