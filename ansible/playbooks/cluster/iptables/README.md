## Comandos úteis

### Executar a playbook do firewall apenas em uma máquina específica
```bash
ansible-playbook -e @settings-producao.yaml -i inventory-producao.ini playbooks/iptables/iptables-proxy-reverso-playbook.yaml --limit wportal06
```
