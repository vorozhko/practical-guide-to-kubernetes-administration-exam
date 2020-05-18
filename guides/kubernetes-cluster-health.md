## How to check Kubernetes cluster health

### Install node problem detector

node-problem-detector aims to make various node problems visible to the upstream layers in cluster management stack. It is a daemon which runs on each node, detects node problems and reports them to apiserver.

```bash
kubectl apply -f https://k8s.io/examples/debug/node-problem-detector.yaml
```
Learn more at [Monitor Node Health](https://kubernetes.io/docs/tasks/debug-application-cluster/monitor-node-health/).

### Cluster info

```bash
kubectl cluster-info

Kubernetes master is running at https://10.0.0.10:6443
KubeDNS is running at https://10.0.0.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://10.0.0.10:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```

### Nodes info

Get extended output of nodes. Pay attention to statuses, roles and IP addresses of nodes.
```
kubectl get nodes -o wide

NAME      STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master    Ready    master   11h   v1.18.2   10.0.0.10     <none>        Ubuntu 18.04.4 LTS   4.15.0-99-generic   docker://19.3.8
worker1   Ready    <none>   11h   v1.18.2   10.0.0.11     <none>        Ubuntu 18.04.4 LTS   4.15.0-99-generic   docker://19.3.8
worker2   Ready    <none>   11h   v1.18.2   10.0.0.12     <none>        Ubuntu 18.04.4 LTS   4.15.0-99-generic   docker://19.3.8
```

### Pods status

```bash
kubectl get pods --all-namespaces
```

### API Component statuses

```bash
kubectl get componentstatuses
```

### Retrieve various cluster events

Get events from all namespaces sorted by timestamp
```bash
kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp
```

### Api server health

Api server has healthz endpoint which return http status 200 and message ok if it's healthy:

```bash
curl -k https://api-server-ip:6443/healthz
ok
```
