#!/bin/bash
#
# Faz o join de um control-plane
#
#
#######################################################################


### --------------------------------

controlplane1="${VM_MASTER_BASE_NAME}1"

echo "Recuperar o join command no controlplane1"
scp -i /home/vagrant/.ssh/k8s-multinode vagrant@$controlplane1:/opt/join-controlplane.sh /tmp


### --------------------------------

echo "Executar /tmp/join-controlplane.sh"
echo " --apiserver-advertise-address=$VM_IP"  >> /tmp/join-controlplane.sh
tr -d '\n' < /tmp/join-controlplane.sh > /tmp/join-controlplane2.sh
cat /tmp/join-controlplane2.sh
source /tmp/join-controlplane2.sh


