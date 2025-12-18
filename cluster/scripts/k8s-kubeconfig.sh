#!/bin/bash

echo 'Criar o kubeconfig no usuário root'
mkdir -p /root/.kube
chmod 0700 /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config


### --------------------------------

echo 'Criar o kubeconfig no usuário vagrant'
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
chmod 0700 /home/vagrant/.kube/config
