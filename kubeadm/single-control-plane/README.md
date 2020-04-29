# Practical guide to Single Kubernetes control plane with Kubeadm

## Provision AWS test VPС and EC2 server (Optional)
If you have a test server and want to practice all steps manually you can skipt to [Install requirements](#install-requirements)

**Provision test VPC and ec2 server with kubeadm pre-installed using Terraform**

```bash
terraform init
terraform plan
terraform apply
``` 

## Install requirements

### Letting iptable to see bridge traffic

```
# Load kernel module
modprobe br_netfilter

# Setup bridge flags
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
# Reload system
sysctl --system
```

### Install Docker CE

```
# Set up the repository:
# Install packages to allow apt to use a repository over HTTPS
apt-get update && apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Add Docker apt repository.
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

# Install Docker CE.
apt-get update && apt-get install -y \
  containerd.io=1.2.13-1 \
  docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker
```


### Install kubeadm kubectl and kubelet
```
# Add Repository
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Install kubelet kubeadm kubectl 
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

``
## Initialize kubeadm on control plane node
Run on each control plane node
```bash
#192.168.0.0/16 is compatible with Calico network plugin
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
## Install network plugin (Calico)
```
kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml
```

## Join worker nodes
Run on each worker node(Adjust token and token hash):
```
kubeadm join 10.0.4.207:6443 --token 9g8vzf.0ztgmm0lq7pmtof6 \
    --discovery-token-ca-cert-hash sha256:bac95d036efd65974ebd5ec26f4c714dac5b59c28d566e66e17a1e6a92e20748
```

## Access cluster from laptop
```
scp root@<control-plane-host>:/etc/kubernetes/admin.conf .
kubectl --kubeconfig ./admin.conf get nodes
```
VPN connection need to be established to access local network.

## What's next

* Verify that your cluster is running properly with [Sonobuoy](https://github.com/heptio/sonobuoy)
* See [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) for details about upgrading your cluster using kubeadm.
* Install [Weave Scope](https://www.weave.works/oss/scope/) addon.
* See the [list of add-ons](https://kubernetes.io/docs/concepts/cluster-administration/addons/) to explore other add-ons, including tools for logging, monitoring, network policy, visualization & control of your Kubernetes cluster.
* Configure how your cluster handles logs for cluster events and from applications running in Pods. See [Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/) for an overview of what is involved
