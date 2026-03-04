## Comandos úteis

### Executar a playbook do firewall apenas em uma máquina específica
```bash
ansible-playbook -e @settings-local.yaml -i inventory-local.ini playbooks/iptables/iptables-proxy-reverso-playbook.yaml --limit vm-worker-01
```
