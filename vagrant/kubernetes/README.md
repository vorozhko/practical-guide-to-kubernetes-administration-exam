# Kubernetes multi nodes cluster in Vagrant

## Insgtall Vagrant machines

```bash
vagrant up
```

## Check cluster health

ssh on master machine

```bash
vagrant ssh master
```

```bash
kubectl get nodes
NAME      STATUS   ROLES    AGE     VERSION
master    Ready    master   2m46s   v1.18.2
worker1   Ready    <none>   35s     v1.18.2
worker2   Ready    <none>   32s     v1.18.2
```

## Install Addons

### Deploy metrics server

```shell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
```

### Update metrics-server deployment

```bash
kubectl -n kube-system edit deployment metrics-server
```

Add following settings to metrics-server start command:

```bash
- --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
- --kubelet-insecure-tls
```
