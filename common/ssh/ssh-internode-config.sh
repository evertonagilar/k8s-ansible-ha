#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

# Executar esta parte somente se VM_BOOTSTRAP_WITH_ANSIBLE estiver definida e for false
if [[ -n "$VM_BOOTSTRAP_WITH_ANSIBLE" && "$VM_BOOTSTRAP_WITH_ANSIBLE" == 'false' ]]; then
    vm_variables=$(env | grep -E '^VM_')
    if [ -n "$vm_variables" ]; then
        echo 'Cadastrar variáveis prefixo VM_ em /etc/environment'
        for vm_variable in "${vm_variables[@]}"; do
            vm_variable_name=${vm_variable%%=*}
            vm_variable_value=${vm_variable#*=}
            echo "Cadastrar $vm_variable_name=$vm_variable_value"
            echo "$vm_variable_name=$vm_variable_value" | tee -a /etc/environment
        done
    fi


    ### --------------------------------

    if [[ -n "$VM_CONTROLPLANE_COUNT" || -n "$VM_WORKER_COUNT" ]]; then
        echo 'Cadastrar máquinas virtuais em /etc/hosts'
        if [[ -n "$VM_VIRTUAL_IP" && -n "$VM_CLUSTER_NAME" && -n "$VM_CLUSTER_NAME" ]]; then
            echo  "Cadastrar $VM_VIRTUAL_IP $VM_CLUSTER_NAME $VM_CLUSTER_NAME.${VM_CLUSTER_DOMAIN}"
            echo "$VM_VIRTUAL_IP $VM_CLUSTER_NAME $VM_CLUSTER_NAME.${VM_CLUSTER_DOMAIN}" >> /etc/hosts
        fi
        if [ -n "$VM_CONTROLPLANE_COUNT" ]; then
            echo "Cadastrar hosts controlplane..."
            for i in $(seq 1 $VM_CONTROLPLANE_COUNT); do
                node="${VM_MASTER_BASE_NAME}${i}"
                node_fqdn="${node}.${VM_CLUSTER_DOMAIN}"
                ip="${VM_IP_SUFIX}.$((VM_IP_CONTROLPLANE_START + i))"
                echo "Cadastrar $ip ${node} ${node_fqdn}"
                echo "$ip ${node} ${node_fqdn}" >> /etc/hosts
            done
        fi
        if [ -n "$VM_WORKER_COUNT" ]; then
            echo "Cadastrar hosts workers..."
            for i in $(seq 1 $VM_WORKER_COUNT); do
                node="${VM_WORKER_BASE_NAME}${i}"
                node_fqdn="${node}.${VM_CLUSTER_DOMAIN}"
                ip="${VM_IP_SUFIX}.$((VM_IP_WORKER_START + i))"
                echo "Cadastrar $ip ${node} ${node_fqdn}"
                echo "$ip ${node} ${node_fqdn}" >> /etc/hosts
            done
        fi
    fi
fi

### --------------------------------

echo 'Configurar parâmetro ssh PasswordAuthentication para yes'
sed -i \
    's/^PasswordAuthentication .*/PasswordAuthentication yes/' \
    /etc/ssh/sshd_config


### --------------------------------

echo 'Configurar parâmetro ssh PermitRootLogin para yes'
sed -i \
  's/^#PermitRootLogin.*/PermitRootLogin yes/' \
  /etc/ssh/sshd_config


### --------------------------------

echo 'Comentar parâmetro MaxAuthTries'
sed -i \
  's/^MaxAuthTries.*/#MaxAuthTries 10/' \
  /etc/ssh/sshd_config


### --------------------------------

echo 'Desabilitar a verificação de hostnames remotos do ssh'
sed -i '/UseDNS/s/^#//' /etc/ssh/sshd_config


### --------------------------------

echo '*********** CONFIG USER VAGRANT ***********'

echo 'Criar arquivo configuração /home/vagrant/.ssh/config'
cat << EOF >> /home/vagrant/.ssh/config
Host vm-*
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF
chmod 600 /home/vagrant/.ssh/config


echo "Copiando chave k8s-multinode para /home/vagrant/.ssh/"
cp "common/ssh/k8s-multinode" "common/ssh/k8s-multinode.pub" /home/vagrant/.ssh/
cat "common/ssh/k8s-multinode.pub" >> /home/vagrant/.ssh/authorized_keys
ln -s /home/vagrant/.ssh/k8s-multinode /home/vagrant/.ssh/id_rsa
ln -s /home/vagrant/.ssh/k8s-multinode.pub /home/vagrant/.ssh/id_rsa.pub
chmod 600 /home/vagrant/.ssh/k8s-multinode
chmod 644 /home/vagrant/.ssh/k8s-multinode.pub
chown -R vagrant:vagrant /home/vagrant/.ssh

### --------------------------------

echo '*********** CONFIG USER ROOT ***********'

echo 'Criar arquivo configuração /root/.ssh/config'
cat << EOF >> /root/.ssh/config
Host vm-*
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF
chmod 600 /root/.ssh/config


echo "Copiando chave k8s-multinode para /root/.ssh/"
cp "common/ssh/k8s-multinode" "common/ssh/k8s-multinode.pub" /root/.ssh/
cat "common/ssh/k8s-multinode.pub" >> /root/.ssh/authorized_keys
ln -s /root/.ssh/k8s-multinode /root/.ssh/id_rsa
ln -s /root/.ssh/k8s-multinode.pub /root/.ssh/id_rsa.pub


### --------------------------------


echo 'Senha padrão do root: admin'
echo -e "admin\admin" | passwd root >/dev/null 2>&1

### --------------------------------

echo 'Reload sshd'
systemctl reload ssh



