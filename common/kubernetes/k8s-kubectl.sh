#!/bin/bash
#
# Instalar a ferramenta kubectl
#
#
#######################################################################

VM_DISTRO_CODENAME="$(lsb_release -cs 2> /dev/null)"

# Variáveis

echo
echo "Versão do Kubernetes: $VM_K8S_VERSION"
echo "Repositório Kubernetes: $VM_K8S_REPO"
echo "Distro: $VM_DISTRO_CODENAME"
echo

if [[ -z "$VM_K8S_VERSION" || -z "$VM_K8S_REPO" || -z "$VM_DISTRO_CODENAME" ]]; then
    echo "Variável VM_K8S_VERSION, VM_K8S_REPO, VM_DISTRO_CODENAME  não definida!"
    exit 1
fi

### --------------------------------


echo 'Adicionar a chave do repositório APT do Kubernetes'
curl -fsSL https://pkgs.k8s.io/core:/stable:/$VM_K8S_REPO/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


echo 'Adicionar o repositório APT do Kubernetes'
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$VM_K8S_REPO/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list


echo 'Atualizar repositório apt'
apt update

### --------------------------------


echo "Instalar o kubectl"
apt install -y kubectl=$VM_K8S_VERSION


echo 'Marcar para não atualizar kubectl junto com o apt upgrade'
apt-mark hold kubectl


### --------------------------------


echo 'Configurar auto complete Kubernetes'
apt-get install -y bash-completion
mkdir -p /etc/bash_completion.d
kubectl completion bash > /etc/bash_completion.d/kubectl
cat << EOF >> /etc/bash.bashrc
source /usr/share/bash-completion/bash_completion
source /etc/bash_completion
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
EOF

