# Kubernetes multi nodes cluster in Vagrant

## Prepare Vagrant

### Prepare one master and two worker machines in Vagrant

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_IMAGE = "ubuntu/bionic64"
NODE_COUNT = 2

Vagrant.configure("2") do |config|
  config.vm.define "master" do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = "master"
    subconfig.vm.network :private_network, ip: "10.0.0.10"
  end

  (1..NODE_COUNT).each do |i|
    config.vm.define "worker#{i}" do |subconfig|
      subconfig.vm.box = BOX_IMAGE
      subconfig.vm.hostname="worker#{i}"
      subconfig.vm.network :private_network, ip: "10.0.0.#{i+10}"
    end
  end

  config.vm.provider "virtualbox" do |vb|
    # Customize the amount of memory on the VM:
    vb.memory = "2048"
    vb.cpus = 2
  end
  
  config.vm.provision "shell", inline: <<-SHELL
    apt-get install -y avahi-daemon libnss-mdns
  SHELL
end
```

## Install Kubernetes

### Install kubeadm, kubectl and kubelet

On each machine:

```bash
/vagrant/install-kubeadm.sh
```

### Setup control plane on master machine

On master machine:

```bash
IP_ADDR=`ifconfig enp0s8 | grep netmask | awk '{print $2}'| cut -f2 -d:`
kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR
```

### Setup kubectl

On master machine:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Install network plugin (calico)

On master machine:

```bash
kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml
```

### Join worker machines

Run on both worker machines:

```bash
kubeadm join 10.0.0.10:6443 --token zsk4mp.pib173c9qqv97q9l \
    --discovery-token-ca-cert-hash sha256:860a4ba21c745648495559e2d10961e728aec7b426a393da3722b95e9ec39f0c
```

### Check nodes

On master machine:

```bash
kubectl get nodes
NAME      STATUS   ROLES    AGE     VERSION
master    Ready    master   2m46s   v1.18.2
worker1   Ready    <none>   35s     v1.18.2
worker2   Ready    <none>   32s     v1.18.2
```

## Install Metrics Server

### Deploy metrics server

On master machine:

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

### Enable kube-apiserver aggregator

On master server:

Add `--enable-aggregator-routing=true` to kube apiserver.
Add the flag to /etc/kubernetes/manifests/kube-apiserver.yaml
