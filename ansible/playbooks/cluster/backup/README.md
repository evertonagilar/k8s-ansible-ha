## Playbooks de backups


### Gerar o secret utilizado pelo cronjob etcd-backup 

```bash
sudo kubectl -n backup-jobs create secret generic etcd-certs   \
--from-file=ca.crt=/etc/kubernetes/pki/etcd/ca.crt   \
--from-file=etcd.crt=/etc/kubernetes/pki/etcd/server.crt   \
--from-file=etcd.key=/etc/kubernetes/pki/etcd/server.key  
```

### Executar um job imediatamente

```bash
kubectl -n backup-jobs create job --from=cronjob/etcd-backup etcd-backup-now
```
