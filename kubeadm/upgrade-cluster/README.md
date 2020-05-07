# Practical guide to Kubernetes Cluster Upgrade

In this guide I install Kuberentes version 1.17 and then upgrade it to the latest stable version(in time of writing 1.18). 

## Before begin

### Provision Kubernetes 1.17.xx

First we need a Kubernets cluster.
Choose one of following setup if you don't have your own:
* [single master on Vagrant](../../vagrant/kubernetes/README.md)
* [multi master with worker nodes on AWS](../ha-control-plane/README.md)

When server nodes are up:
* ssh to each node in case of HA cluster
* re-install kubeadm, kubectl and kubelet with version tag 1.17.4-00 instead of mainstream. See below:

```bash
VERSION=1.17.4-00 
apt-get install --allow-change-held-packages -qy kubelet=$VERSION kubectl=$VERSION kubeadm=$VERSION
# All versions are avaialble at: 
# curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages | grep Version | awk '{print $2}'
```

### Disable swap

* Identify configured swap devices and files with cat /proc/swaps.
* Turn off all swap devices and files with swapoff -a.
* Remove any matching reference found in /etc/fstab.
* Optional: Destroy any swap devices or files found in step 1 to prevent their reuse. Due to your concerns about leaking sensitive information, you may wish to consider performing some sort of secure wipe.

### Backup etcd
* [Backup and restore Kubernetes objects with Velero](../../velero/README.md)
* [Backup and resore with etcdctl](https://etcd.io/docs/v3.4.0/op-guide/recovery/)

## Upgrade
### Determine which version to upgrade
```
apt update
apt-cache madison kubeadm
# find the latest 1.18 version in the list
# it should look like 1.18.x-00, where x is the latest patch
```

### Upgrading first control plane node
```
# replace x in 1.18.x-00 with the latest patch version
apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.18.x-00 && \
apt-mark hold kubeadm

# since apt-get version 1.1 you can also use the following method
apt-get update && \
apt-get install -y --allow-change-held-packages kubeadm=1.18.x-00
```

* Verify kubeadm new version: ```kubeadm version```
* Drain the control plane node: ```kubectl drain <cp-node-name> --ignore-daemonsets```
* On control plane node run: ```sudo kubeadm upgrade plan```
* Choose a version to upgrade to: ```sudo kubeadm upgrade apply v1.18.x```
* Manually upgrade your CNI provider plugin.
* Uncordon the control plane node: ```kubectl uncordon <cp-node-name>```

### Upgrade additional control plane nodes
* Same as first CP node, but use: ```sudo kubeadm upgrade node```, instead of ```sudo kubeadm upgrade apply```

### Upgrade kublet and kubectl
```
# replace x in 1.18.x-00 with the latest patch version
apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.18.x-00 kubectl=1.18.x-00 && \
apt-mark hold kubelet kubectl

# since apt-get version 1.1 you can also use the following method
apt-get update && \
apt-get install -y --allow-change-held-packages kubelet=1.18.x-00 kubectl=1.18.x-00
```
* Restart kubelet: ```sudo systemctl restart kubelet```

## Upgrade worker nodes
### Upgrade kubeadm on worker nodes
```
# replace x in 1.18.x-00 with the latest patch version
apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.18.x-00 && \
apt-mark hold kubeadm

# since apt-get version 1.1 you can also use the following method
apt-get update && \
apt-get install -y --allow-change-held-packages kubeadm=1.18.x-00
```
### Drain the node
```
kubectl drain <node-to-drain> --ignore-daemonsets
```
### Upgrade the kubelet configuration
```
sudo kubeadm upgrade node
```

### Upgrade kubelet and kubectl
```
# replace x in 1.18.x-00 with the latest patch version
apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.18.x-00 kubectl=1.18.x-00 && \
apt-mark hold kubelet kubectl

# since apt-get version 1.1 you can also use the following method
apt-get update && \
apt-get install -y --allow-change-held-packages kubelet=1.18.x-00 kubectl=1.18.x-00
```
* Restart the kubelet: ```sudo systemctl restart kubelet```

### Uncordon the node
```kubectl uncordon <node-to-drain>```

## Verify status of the cluster
```kubectl get nodes```

## More
[Recovery from failure state](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/#recovering-from-a-failure-state)
