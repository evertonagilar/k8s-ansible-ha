#!/bin/bash
#
# Configurar o repositório do Kubernetes e containerd
#
#
#######################################################################

VM_DISTRO_CODENAME="$(lsb_release -cs 2> /dev/null)"

# Variáveis

echo
echo "Versão do Kubernetes: $VM_K8S_VERSION"
echo "Repositório Kubernetes: $VM_K8S_REPO"
echo "Versão do ContainerD: $VM_CONTAINERD_VERSION"
echo "Distro: $VM_DISTRO_CODENAME"
echo

if [[ -z "$VM_K8S_VERSION" || -z "$VM_K8S_REPO" || -z "$VM_CONTAINERD_VERSION" ]]; then
    echo "Variável VM_K8S_VERSION, VM_K8S_REPO, VM_CONTAINERD_VERSION não definida!"
    exit 1
fi

echo 'Adicionar a chave do repositório APT do Kubernetes'
curl -fsSL https://pkgs.k8s.io/core:/stable:/$VM_K8S_REPO/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


echo 'Adicionar o repositório APT do Kubernetes'
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$VM_K8S_REPO/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list


### --------------------------------


echo 'Adicionar a chave do repositório APT do containerd'
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg


echo 'Adicionar o repositório APT do containerd'
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $VM_DISTRO_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null


echo 'Atualizar repositório apt'
apt update


