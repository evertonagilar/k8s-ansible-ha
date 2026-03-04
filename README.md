# Projeto de Cluster Kubernetes em Alta Disponibilidade (HA)

Este projeto automatiza o provisionamento (IaC) de um cluster Kubernetes em HA com keepalive, utilizando **Vagrant** para o gerenciamento das máquinas virtuais (VirtualBox) e **Ansible** para a configuração e orquestração do software.

## Arquitetura do Cluster

O ambiente é composto por **7 Máquinas Virtuais** interconectadas através de uma rede privada interna:

*   **Host Gateway/Firewall**: Atua como roteador NAT para fornecer acesso à internet para o cluster.
*   **3 Control Planes**: Nós mestres do Kubernetes configurados com **Keepalived** para prover um IP Virtual (VIP) de alta disponibilidade para a API Server.
*   **3 Workers**: Nós onde as cargas de trabalho (Pods) são executadas.

### Topologia de Rede (Default)

*   **Rede Interna:** `192.168.20.0/24`
*   **VIP do Control Plane:** `192.168.20.10`

| Hostname             | IP              | Função                |
| :------------------- | :-------------- | :-------------------- |
| `vm-proxyfw`         | `192.168.20.8`  | Gateway NAT / Firewall|
| `vm-controlplane-01` | `192.168.20.11` | Master 1              |
| `vm-controlplane-02` | `192.168.20.12` | Master 2              |
| `vm-controlplane-03` | `192.168.20.13` | Master 3              |
| `vm-worker-01`       | `192.168.20.16` | Worker 1              |
| `vm-worker-02`       | `192.168.20.17` | Worker 2              |
| `vm-worker-03`       | `192.168.20.18` | Worker 3              |

## Pré-requisitos

Para executar este projeto, você precisará instalar em sua máquina local:

1.  **[VirtualBox](https://www.virtualbox.org/)**: Hypervisor para rodar as VMs.
2.  **[Vagrant](https://www.vagrantup.com/)**: Gerenciador de ambientes virtuais.
3.  **[Ansible](https://www.ansible.com/)**: Ferramenta de automação (necessário para rodar os playbooks).

## Guia de Instalação

Siga os passos abaixo, na ordem apresentada, para subir o cluster.

### 1. Provisionar o Gateway (ProxyFW)

Primeiro, inicie a máquina que servirá de gateway para as demais.

```bash
cd proxyfw
vagrant up
```
*Aguarde o provisionamento completo antes de prosseguir.*

### 2. Provisionar os Nós do Cluster

Em seguida, inicie as VMs do Kubernetes.

```bash
cd ../cluster
vagrant up
```

> **Nota:** O `Vagrantfile` está configurado (`VM_BOOTSTRAP_WITH_ANSIBLE="true"`) para apenas criar as VMs e configurar o acesso SSH. A instalação do Kubernetes será feita via Ansible nos próximos passos.

### 3. Configurar Acesso SSH para o Ansible

As chaves SSH utilizadas para comunicação entre os nós são geradas automaticamente pelo Vagrant caso não existam (em `common/ssh`). Para que o Ansible (rodando na sua máquina) consiga se conectar às VMs, você deve configurar a chave privada gerada.

Copie a chave para o seu diretório `.ssh` pessoal:

```bash
# Estando na raiz do projeto (ou ajuste o caminho conforme necessário)
cp common/ssh/k8s-multinode ~/.ssh/
chmod 600 ~/.ssh/k8s-multinode
```

### 4. Executar os Playbooks Ansible

Navegue até o diretório `ansible` para iniciar a configuração do cluster.

```bash
cd ../ansible
```

Execute os playbooks na ordem a seguir:

#### 4.1. Preparação do Sistema Operacional
Configura `/etc/hosts`, timezone, swap off, módulos do kernel, etc.
```bash
ansible-playbook -i inventory-local.ini playbooks/cluster/so/so-playbook.yaml
```

#### 4.2. Instalação do Container Runtime (Containerd)
```bash
ansible-playbook -i inventory-local.ini playbooks/cluster/container-runtime/container-runtime-playbook.yaml
```

#### 4.3. Configuração do Keepalived (HA VIP)
Configura o IP Virtual `192.168.20.10` entre os Control Planes.
```bash
ansible-playbook -i inventory-local.ini playbooks/cluster/keepalive-controlplane/keepalived-controlplane-playbook.yaml
```

#### 4.4. Instalação dos Binários do Kubernetes
Instala `kubeadm`, `kubelet` e `kubectl`.
```bash
ansible-playbook -i inventory-local.ini playbooks/cluster/kubernetes/k8s-common-playbook.yaml
```

#### 4.5. Inicialização do Cluster (Bootstrap)
Inicializa o primeiro control plane e configura a rede (CNI/Calico).
```bash
ansible-playbook -i inventory-local.ini playbooks/cluster/kubernetes/k8s-criar-cluster-playbook.yaml
```

#### 4.6. Join dos Outros Control Planes
```bash
ansible-playbook -i inventory-local.ini playbooks/cluster/kubernetes/k8s-join-controlplane-playbook.yaml
```

#### 4.7. Join dos Workers
```bash
ansible-playbook -i inventory-local.ini playbooks/cluster/kubernetes/k8s-join-worker-playbook.yaml
```

#### 4.8. Deploy de Addons Básicos (Opcional)
Instala Ingress Nginx, Metrics Server e configuração de Storage Class NFS/Local.
```bash
ansible-playbook -i inventory-local.ini playbooks/cluster/kubernetes/k8s-deploy-basico-playbook.yaml
```

## Acesso e Gerenciamento

Após a conclusão dos playbooks, o cluster estará operacional.

Para interagir com o cluster, acesse um dos control planes via SSH:

```bash
ssh -i ~/.ssh/k8s-multinode vagrant@192.168.20.11
```

Verifique o status dos nós:

```bash
sudo kubectl get nodes -o wide
```

Verifique os Pods em execução:

```bash
sudo kubectl get pods -A
```
