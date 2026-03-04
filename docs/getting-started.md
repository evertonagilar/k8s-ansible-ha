# Guia de Início Rápido — Cluster Kubernetes HA

Este guia descreve desde a configuração inicial até um cluster Kubernetes em Alta Disponibilidade rodando localmente com Vagrant + VirtualBox + Ansible.

---

## Índice

1. [Pré-requisitos](#1-pré-requisitos)
2. [Requisitos de Hardware do Host](#2-requisitos-de-hardware-do-host)
3. [Estrutura do Projeto](#3-estrutura-do-projeto)
4. [Configuração Inicial](#4-configuração-inicial)
5. [Provisionamento das VMs](#5-provisionamento-das-vms)
6. [Provisionamento do Cluster com Ansible](#6-provisionamento-do-cluster-com-ansible)
7. [Verificação do Cluster](#7-verificação-do-cluster)
8. [Addons Opcionais](#8-addons-opcionais)
9. [Destruir e Recriar](#9-destruir-e-recriar)
10. [Solução de Problemas](#10-solução-de-problemas)

---

## 1. Pré-requisitos

Instale as ferramentas abaixo na máquina host antes de prosseguir:

| Ferramenta | Versão mínima | Download |
|---|---|---|
| VirtualBox | 7.0+ | https://www.virtualbox.org/wiki/Downloads |
| Vagrant | 2.3+ | https://developer.hashicorp.com/vagrant/downloads |
| Ansible | 2.14+ | `pip install ansible` |

Verifique as versões instaladas:

```bash
vagrant --version
VBoxManage --version
ansible --version
```

---

## 2. Requisitos de Hardware do Host

| Recurso | Mínimo | Recomendado |
|---|---|---|
| RAM | 32 GB | 48 GB |
| CPUs | 8 cores | 16 cores |
| Disco | 150 GB livres | 300 GB livres |

### Distribuição de recursos por VM

| VM | RAM | CPUs | Disco |
|---|---|---|---|
| `vm-proxyfw` | 800 MB | 1 | 20 GB |
| `vm-controlplane-01` | 2 GB | 2 | 100 GB |
| `vm-controlplane-02` | 2 GB | 2 | 100 GB |
| `vm-controlplane-03` | 2 GB | 2 | 100 GB |
| `vm-worker-01` | 14 GB | 2 | 100 GB |
| `vm-worker-02` | 8 GB | 2 | 100 GB |
| `vm-worker-03` | 2 GB | 2 | 100 GB |
| **Total** | **~31 GB** | **13** | **~620 GB** |

> **Dica:** Para economizar recursos, edite `VM_WORKER_MEMORY` no `cluster/Vagrantfile`
> reduzindo memória dos workers. Mínimo recomendado por worker: `2048` (2 GB).

---

## 3. Estrutura do Projeto

```
k8s-ansible-ha/
├── ansible/                   # Playbooks e configurações Ansible
│   ├── settings-local.yaml    # ⚙️  Arquivo central de configuração do ambiente
│   ├── inventory-local.ini    # Inventário dos hosts do cluster
│   ├── ansible.cfg            # Configurações do Ansible
│   └── playbooks/
│       └── cluster/           # Playbooks por componente
├── cluster/                   # Vagrantfile dos nós do cluster (controlplanes + workers)
├── proxyfw/                   # Vagrantfile do gateway NAT
├── common/                    # Scripts e chaves SSH compartilhadas entre VMs
└── docs/                      # Documentação do projeto
```

---

## 4. Configuração Inicial

### 4.1. Editar o arquivo de configuração central

Abra **`ansible/settings-local.yaml`** e ajuste as variáveis essenciais:

```yaml
# Administrador do cluster — usado nos RBACs e certificados
CLUSTER_ADMIN:
  username: seu-usuario           # nome do usuário kubectl/RBAC
  email: seu-email@exemplo.com    # e-mail para cert-manager (Let's Encrypt)

# Senha do protocolo VRRP (Keepalived entre os control planes)
VM_VRRP_PASSWD: sua-senha-vrrp

# Senha inicial do ArgoCD (alterável depois via UI)
ARGOCD:
  password: sua-senha-argocd

# Credenciais do Elasticsearch/Kibana (stack EFK — opcional)
EFK_LOGGING:
  elasticsearch:
    password: sua-senha-elasticsearch
```

> **Variáveis opcionais:** O bloco `GITLAB` só precisa ser configurado se você for
> utilizar os playbooks de deploy de aplicações via ArgoCD. Para o cluster base, pode ser ignorado.

### 4.2. Verificar o inventário

O arquivo `ansible/inventory-local.ini` já vem pré-configurado para o ambiente local padrão.
Não é necessário alterá-lo, a menos que você mude os IPs no `cluster/Vagrantfile`.

---

## 5. Provisionamento das VMs

Todos os comandos abaixo partem da **raiz do projeto**.

### 5.1. Subir o Gateway NAT (ProxyFW)

O gateway deve ser provisionado **primeiro**, pois os demais nós dependem dele para ter acesso à internet.

```bash
cd proxyfw
vagrant up
```

Aguarde a conclusão (≈ 2 min). O Vagrant irá:
- Criar a VM `vm-proxyfw` (Ubuntu 24.04)
- Configurar a regra iptables de MASQUERADE para compartilhar internet com a rede `192.168.20.0/24`

### 5.2. Subir os Nós do Cluster

```bash
cd ../cluster
vagrant up
```

Aguarde a conclusão (≈ 10–20 min dependendo da banda para download das boxes).

O Vagrant irá:
- Gerar as chaves SSH em `common/ssh/k8s-multinode` (se não existirem)
- Criar 3 Control Planes (`vm-controlplane-01/02/03`) e 3 Workers (`vm-worker-01/02/03`)
- Copiar os scripts e configurações para dentro das VMs
- **Não** instalar Kubernetes — isso é feito pelo Ansible no próximo passo

### 5.3. Instalar a chave SSH do cluster

Para que o Ansible consiga se conectar às VMs, copie a chave privada gerada pelo Vagrant:

```bash
cp ../common/ssh/k8s-multinode ~/.ssh/
chmod 600 ~/.ssh/k8s-multinode
```

Teste a conectividade:

```bash
cd ../ansible
ansible all -i inventory-local.ini -m ping
```

Todos os hosts devem responder com `pong`.

---

## 6. Provisionamento do Cluster com Ansible

Execute os playbooks **na ordem abaixo**, a partir do diretório `ansible/`.

> **Prefixo comum a todos os comandos:**
> ```bash
> cd /caminho/para/k8s-ansible-ha/ansible
> ```

### 6.1. Preparação do Sistema Operacional

Configura `/etc/hosts`, timezone, swap off, módulos do kernel, sysctl, pacotes essenciais.

```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/so/so-playbook.yaml
```

### 6.2. Instalação do Container Runtime (Containerd)

```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/container-runtime/container-runtime-playbook.yaml
```

### 6.3. Configuração do Keepalived (VIP de Alta Disponibilidade)

Configura o IP Virtual `192.168.20.10` entre os control planes via protocolo VRRP.

```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/keepalive-controlplane/keepalived-controlplane-playbook.yaml
```

### 6.4. Instalação dos Binários Kubernetes

Instala `kubeadm`, `kubelet` e `kubectl` em todos os nós.

```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/kubernetes/k8s-common-playbook.yaml
```

### 6.5. Inicialização do Cluster (Bootstrap)

Executa `kubeadm init` no primeiro control plane e instala o CNI Calico.

```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/kubernetes/k8s-criar-cluster-playbook.yaml
```

### 6.6. Join dos Control Planes Secundários

```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/kubernetes/k8s-join-controlplane-playbook.yaml
```

### 6.7. Join dos Workers

```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/kubernetes/k8s-join-worker-playbook.yaml
```

### 6.8. Deploy dos Addons Básicos

Instala Ingress Nginx, Metrics Server e configura Storage Classes (NFS/Local Path).

```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/kubernetes/k8s-deploy-basico-playbook.yaml
```

---

## 7. Verificação do Cluster

Acesse o primeiro control plane:

```bash
ssh -i ~/.ssh/k8s-multinode vagrant@192.168.20.11
```

Verifique os nós — todos devem estar `Ready`:

```bash
kubectl get nodes -o wide
```

Saída esperada:

```
NAME                   STATUS   ROLES           AGE   VERSION
vm-controlplane-01     Ready    control-plane   10m   v1.34.x
vm-controlplane-02     Ready    control-plane   8m    v1.34.x
vm-controlplane-03     Ready    control-plane   6m    v1.34.x
vm-worker-01           Ready    <none>          4m    v1.34.x
vm-worker-02           Ready    <none>          4m    v1.34.x
vm-worker-03           Ready    <none>          4m    v1.34.x
```

Verifique os pods do sistema:

```bash
kubectl get pods -A
```

Verifique a alta disponibilidade (o VIP deve estar acessível):

```bash
curl -k https://192.168.20.10:6443/healthz
# Resposta esperada: ok
```

---

## 8. Addons Opcionais

Cada addon abaixo é independente e pode ser instalado após o cluster estar operacional.
Todos usam `ansible-playbook -e @settings-local.yaml -i inventory-local.ini`.

| Addon | Playbook |
|---|---|
| MetalLB (LoadBalancer) | `playbooks/cluster/k8s-metallb/k8s-metallb-playbook.yaml` |
| Cert-Manager (TLS) | `playbooks/cluster/cert-manager/cert-manager-playbook.yaml` |
| ArgoCD (GitOps) | `playbooks/cluster/argocd/argocd-client-and-server-playbook.yaml` |
| K8s Dashboard | `playbooks/cluster/k8s-dashboard/k8s-dashboard-playbook.yaml` |
| Kube-Prometheus (Monitoramento) | `playbooks/cluster/kube-prometheus/kube-prometheus-playbook.yaml` |
| EFK Stack (Logs) | `playbooks/cluster/efk-logging-stack/efk-logging-stack-playbook.yaml` |
| Firewall (iptables) | `playbooks/cluster/iptables/iptables-cluster-playbook.yaml` |
| NFS | `playbooks/cluster/nfs/nfs-playbook.yaml` |

---

## 9. Destruir e Recriar

Para destruir completamente o ambiente:

```bash
# Destruir nós do cluster
cd cluster
vagrant destroy -f

# Destruir o gateway
cd ../proxyfw
vagrant destroy -f

# Remover chaves SSH geradas (opcional — serão recriadas no próximo vagrant up)
rm -f ../common/ssh/k8s-multinode ../common/ssh/k8s-multinode.pub
```

---

## 10. Solução de Problemas

### VMs não conseguem acessar a internet

Verifique se a regra de MASQUERADE está ativa no `vm-proxyfw`:

```bash
vagrant ssh  # dentro do diretório proxyfw/
sudo iptables -t nat -L POSTROUTING -n -v
```

### Ansible não conecta às VMs

```bash
# Verificar se a chave SSH está correta
ssh -i ~/.ssh/k8s-multinode -o StrictHostKeyChecking=no vagrant@192.168.20.11

# Verificar conectividade básica
ansible all -i inventory-local.ini -m ping
```

### kubeadm init falha por swap ativa

O playbook `so-playbook.yaml` desabilita swap. Se o erro persistir:

```bash
ssh -i ~/.ssh/k8s-multinode vagrant@192.168.20.11
sudo swapoff -a
```

### Nó não entra no cluster após join

```bash
# No control plane, verificar certificado de join ainda válido (validade: 24h)
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/cluster/kubernetes/k8s-join-controlplane-playbook.yaml
```

### Verificar logs do kubelet

```bash
ssh -i ~/.ssh/k8s-multinode vagrant@192.168.20.11
sudo journalctl -u kubelet -f
```
