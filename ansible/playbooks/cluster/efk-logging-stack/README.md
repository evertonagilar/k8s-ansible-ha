## Testar o elasticsearch

1. Com port-forward

```bash
kubectl --namespace=efk-logging port-forward es-cluster-0 9200:9200 
curl -k -u elastic:J#DEkUUxFOHNPOEQkMU9uZ0@2025 https://localhost:9200
```

2. Com pod na namespace diagnostico

```bash
k -n diagnostico run -it ubuntu --image=evertonagilar/ubuntu
curl -k -u elastic:J#DEkUUxFOHNPOEQkMU9uZ0@2025 https://es-cluster-0.elasticsearch.efk-logging.svc.cluster.local:9200
```


Resposta:

```json
{
  "name" : "es-cluster-0",
  "cluster_name" : "k8s-logs",
  "cluster_uuid" : "t-jnlMx_T7aTr4y1oI49ew",
  "version" : {
    "number" : "8.16.0",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "12ff76a92922609df4aba61a368e7adf65589749",
    "build_date" : "2024-11-08T10:05:56.292914697Z",
    "build_snapshot" : false,
    "lucene_version" : "9.12.0",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

## Testar o kibana

```bash
kubectl -n efk-logging port-forward kibana-77c4cc5c8b-h9t84 5601:5601
```


## Validar arquivo de config fluentd

```bash
sudo fluentd -c /etc/fluent/fluentd.conf -dry-run
```
