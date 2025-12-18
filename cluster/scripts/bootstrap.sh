#!/bin/bash

echo '********** Chamando ssh-internode-config obrigatório **********'
source common/ssh/ssh-internode-config.sh

if [ "$VM_BOOTSTRAP_WITH_ANSIBLE" == 'true' ]; then
    echo '********** A criação do cluster Kubernetes será feito com Ansible *********'
    sleep 2
else
    echo '********** Iniciando o provisionamento do cluster com scripts *********'
    sleep 2

    source common/so/so-common.sh
    source common/kubernetes/k8s-common.sh

    # *** Executar em controlplane ***
    if [ -n "$VM_CONTROLPLANE_NUMBER" ]; then
        source scripts/keepalived.sh
        # *** Executar somente no primeiro controlplane ***
        if [ "$VM_CONTROLPLANE_NUMBER" == "1" ]; then
            source scripts/k8s-init.sh
            source scripts/k8s-join-print.sh
        else
            source scripts/k8s-join-controlplane.sh
        fi
        source scripts/k8s-etcdctl.sh
    # **** Executar em worker node ***
    else
        source scripts/k8s-join-worker.sh
    fi
    source scripts/k8s-kubeconfig.sh
fi
