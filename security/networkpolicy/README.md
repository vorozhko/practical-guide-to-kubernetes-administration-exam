# NetworkPolicy quick test

## Before you begin
You would need a kubernetes cluster with a network pluging which support NetworkPolicies like Calico or WeaveNet.
To run a local cluster with Vagrat see [Single node Kubernetes on Vagrant](../../vagrant/kubernetes/README.md)

## Testing NetworkPolicy
### Prepare workload
```
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80
```
It will create nginx Pod and Service in default namespace.

### Testing connection to nginx pod
Create new pod from which we will try to access nginx Pod through nginx Service:
```
kubectl run --generator=run-pod/v1 busybox --rm -ti --image=busybox -- /bin/sh
```
Testing access:
```
wget --spider --timeout=1 nginx
Connecting to nginx (10.108.8.157:80)
remote file exists
```

### Create NetworkPolicy
NetworkPolicy nginx-access will be applied to all pods with label "app=nginx" and will allow access only from pods with label "access=true".

```yaml
kubect create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: access-nginx
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: "true"
networkpolicy.networking.k8s.io/access-nginx created
```

### Testing access to nginx Pod without access label
```
wget --spider --timeout=1 nginx
Connecting to nginx (10.108.8.157:80)
wget: download timed out
```

### Testing access to nginx Pod with access label
```
kubectl run --generator=run-pod/v1 busybox --rm -ti --image=busybox --labels="access=true" -- /bin/sh

wget --spider --timeout=1 nginx
Connecting to nginx (10.108.8.157:80)
remote file exists
```

## References
[Declare Network Policy](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)