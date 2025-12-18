## Antes de executar o playbook do fluentd, precisa criar o manifesto fluentd.yaml com kustomize

```bash
# na pasta templates, executar
kubectl kustomize base --output fluentd.yaml
```
