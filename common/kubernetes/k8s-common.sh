#!/bin/bash
#
# Instalar o software do Kubernetes
#
# Os seguintes pacotes são instalados:
# * kubelet
# * kubeadm
# * kubectl
#
#######################################################################

VM_DISTRO_CODENAME="$(lsb_release -cs 2> /dev/null)"
echo ETCDCTL_API=$ETCDCTL_API | tee -a /etc/environment

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

### --------------------------------

echo 'Desabilitar o swap'
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


### --------------------------------


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


### --------------------------------


echo 'Instalar Containerd'
apt install -y containerd.io=$VM_CONTAINERD_VERSION

echo 'Marcar para não atualizar containerd.io junto com o apt upgrade'
apt-mark hold containerd.io


### --------------------------------


echo "Instalar ferramentas Kubernetes"
apt install -y kubelet=$VM_K8S_VERSION kubeadm=$VM_K8S_VERSION kubectl=$VM_K8S_VERSION


echo 'Marcar para não atualizar Kubernetes junto com o apt upgrade'
apt-mark hold kubelet kubeadm kubectl


### --------------------------------

echo 'Criar o arquivo de configuração do Containerd'
mkdir -p /etc/containerd
containerd config default | \
  sed 's/^\([[:space:]]*SystemdCgroup = \).*/\1true/' | \
  tee /etc/containerd/config.toml

### --------------------------------

echo 'Reiniciar o Containerd'
systemctl restart containerd

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


### --------------------------------


echo 'Criar arquivo de configuração /etc/crictl.yaml'
cat << EOF >> /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
pull-image-on-create: false
EOF


### --------------------------------


echo 'Mostrar os pacotes marcados que NÂO deve atualizar'
apt-mark showhold


### --------------------------------

echo 'Configura KUBELET_EXTRA_ARGS para o kubelet'
echo "KUBELET_EXTRA_ARGS=\"--node-ip=$VM_IP --container-runtime-endpoint=unix:///run/containerd/containerd.sock\"" >> /etc/default/kubelet


### --------------------------------

echo 'Baixar as imagens do Kubernetes'
kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock


### --------------------------------

echo 'Habilitar o containerd e o kubelet'
systemctl enable --now containerd
systemctl enable kubelet
systemctl restart kubelet

