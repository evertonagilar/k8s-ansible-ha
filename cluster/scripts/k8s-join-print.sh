#!/bin/bash
#
# Criar o comando para fazer join
#
#
#######################################################################


echo 'Criar o join_command para adicionar os demais nodes'
join_command="$(kubeadm token create --print-join-command)"

echo 'Obter token para adicionar novo controlplane'
TOKEN_CERT=$(kubeadm init phase upload-certs --upload-certs 2> /dev/null | tail -1)

echo 'Gerando arquivo /opt/join-controlplane.sh'
echo "$join_command --cri-socket unix:///run/containerd/containerd.sock --control-plane --certificate-key $TOKEN_CERT " > /opt/join-controlplane.sh
chmod +x /opt/join-controlplane.sh

echo 'Gerando arquivo /opt/join-worker.sh'
echo "$join_command --cri-socket unix:///run/containerd/containerd.sock " > /opt/join-worker.sh
chmod +x /opt/join-worker.sh




