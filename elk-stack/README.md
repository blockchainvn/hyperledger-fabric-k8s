# Logging with Elastic in Kubernetes

This setup is similar to the [`Full Stack Example`](https://github.com/elastic/examples/tree/master/Miscellaneous/docker/full_stack_example), but adopted to be run on a Kubernetes cluster.

There is no access control for the Kibana web interface. If you want to run this in public you need to secure your setup. The provided manifests here are for demonstration purposes only.


## Logging with Elasticsearch and fluentd

```bash
kubectl apply -f elk-stack/manifests-all.yaml
```

For the index pattern in Kibana choose `fluentd-*`, then switch to the "Discover" view.
Every log line by containers running within the Kubernetes cluster is enhanced by meta data like `namespace_name`, `labels` and so on. This way it is easy to group and filter down on specific parts.

## Logging with Elasticsearch and logstash - additional option

```bash
kubectl apply -f elk-stack/logstash
```

For the index pattern in Kibana choose `logstash-*`, then switch to the "Discover" view.

## Turn down all logging components

```bash
kubectl delete -f elk-stack/manifests-all.yaml
```

FIXME alternatively
--selector stack=logging

