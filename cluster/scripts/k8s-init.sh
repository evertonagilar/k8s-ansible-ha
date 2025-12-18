#!/bin/bash
#
# Criar o cluster Kubernetes
#
#
#######################################################################


# Variáveis

echo
echo "Versão do Kubernetes: $VM_K8S_VERSION"
echo "Versão CALICO: $VM_CALICO_VERSION"
echo "VM_POD_NETWORK_CIDR: $VM_POD_NETWORK_CIDR"
echo "VM_SERVICE_CIDR: $VM_SERVICE_CIDR"
echo



### --------------------------------

echo 'Executar o kubeadm init para criar o cluster'
kubeadm init --apiserver-advertise-address=$VM_IP \
--control-plane-endpoint $VM_CONTROL_PLANE_ENDPOINT \
--upload-certs \
--node-name $VM_HOSTNAME \
--pod-network-cidr=$VM_POD_NETWORK_CIDR \
--service-cidr=$VM_SERVICE_CIDR \
--apiserver-cert-extra-sans=$VM_VIRTUAL_IP,$VM_IP,$VM_HOSTNAME \
--cri-socket unix:///run/containerd/containerd.sock

### --------------------------------

echo 'Criar a pasta /root/.kube'
mkdir -p /root/.kube
chmod 0700 /root/.kube

### --------------------------------

echo 'Copiar o arquivo /etc/kubernetes/admin.conf para /root/.kube/config'
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 0700 /root/.kube/config

### --------------------------------

echo 'Criar a pasta /home/vagrant/.kube'
mkdir -p /home/vagrant/.kube
chown vagrant:vagrant /home/vagrant/.kube
chmod 0700 /home/vagrant/.kube

### --------------------------------

echo 'Copiar o arquivo /etc/kubernetes/admin.conf para /home/vagrant/.kube/config'
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config
chmod 0700 /home/vagrant/.kube/config

### --------------------------------

echo 'Copiar pasta /etc/kubernetes para a pasta /vagrant/config'
rm -rf /vagrant/config/kubernetes
cp -R /etc/kubernetes /vagrant/config

### --------------------------------

echo 'Instalar plugin de rede Calico CNI'
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/$VM_CALICO_VERSION/manifests/calico.yaml
sleep 30

