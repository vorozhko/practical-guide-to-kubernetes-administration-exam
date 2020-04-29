# Single node Kubernetes at Vagrant box

## Install

Prepare vagrant box with Ubuntu 18.04
```bash
vagrant up
```

Install kubeadm
```bash
vagrant ssh
sudo /vagrant/install-kubeadm.sh
kubeadm init --pod-network-cidr=192.168.0.0/16
```

To start using your cluster, you need to run the following as a regular user:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

To allow scheduling pods on control plan nodes(in case of single node):
```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

Install network plugin (Calico)
```
kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml
```

