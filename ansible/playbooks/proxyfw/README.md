## Proxy Firewall

### Requisitos: Habilitar encaminhamento de pacotes

```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/${INTERFACE_DO_GATEWAY_AQUI}/forwarding
```

### Habilitar a internet 

```bash
sudo iptables -t nat -A POSTROUTING -s 192.168.20.0/24 ! -d 192.168.20.0/24 -j MASQUERADE
```

### Ver as regras criadas

```bash
sudo iptables -nvL -t nat --line-numbers
sudo ip6tables -nvL -t nat --line-numbers
```


