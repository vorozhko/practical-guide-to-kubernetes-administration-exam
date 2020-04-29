# Practical guide to Kubernetes Multi node control plane

## Requirements
Before using **terraform** script you have to prepare default aws profile and adjust aws region in **variables.tf**

## Install infrastructure with Terraform

### What it does
* Create ASG for control plane nodes
* Create ASG for worker nodes
* Create NLB Load balancer for control plane

### How AWS resources are related to each other
* aws_launch_template(LT) - define instance parameters
* aws_autoscaling_group(ASG) - use LT and define VPC subnets
* aws_autoscaling_attachment - connect TG with ASG
* aws_lb_target_group(TG) - define vpc
* aws_lb(LB) - define subnets
* aws_lb_listener - connect LB with TG


### Apply Terrafom
```bash
terraform init
terraform plan
terraform apply
```

## Activate control plane Kubernetes nodes
For easy steup and testing all EC2 nodes have public ip.

### Create first control plane node
Run on **first master** node. You can choose any ec2 server as **first master** from master group.

```kubeadm init --control-plane-endpoint "LOAD_BALANCER_DNS:LOAD_BALANCER_PORT" --upload-certs --pod-network-cidr=192.168.0.0/16```

To access our api server from laptop require public load balancer which will forward TCP connection to control plane instances.

Internet facing NLB require instances security group to open inbound connection from client ips, so if our client is laptop it mean to open connection to VPN public ip.

To start using your cluster, you need to run the following as a regular user:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```


### Install network plugin

>Note: Some CNI network plugins like Calico require a CIDR such as 192.168.0.0/16 and some like Weave do not. See the [CNI network documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network).

*WeaveWorks plugin:*
```kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"```

*Calico plugin:*
```kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml```

>Note: Possible issue with CNI plugin on AWS - [ Available ENIs left dangling after node termination #608 ](https://github.com/aws/amazon-vpc-cni-k8s/issues/608) 

### Join additional control plan nodes
Run on other **master** nodes.

```kubeadm join 192.168.0.200:6443 --token 9vr73a.a8uxyaju799qwdjv --discovery-token-ca-cert-hash sha256:7c2e69131a36ae2a042a339b33381c6d0d43887e2de83720eff5359e26aec866 --control-plane --certificate-key f8902e114ef118304e561c3ecd4d0b543adc226b7a07f675f56564185ffe0c07```


>Note: Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
>As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use kubeadm init phase upload-certs to reload certs afterward

To re-upload the certificates and generate a new decryption key, use the following command on a control plane node that is already joined to the cluster:

```sudo kubeadm init phase upload-certs --upload-certs```

### Join worker nodes
Run on each **worker**.
```kubeadm join 192.168.0.200:6443 --token 9vr73a.a8uxyaju799qwdjv --discovery-token-ca-cert-hash sha256:7c2e69131a36ae2a042a339b33381c6d0d43887e2de83720eff5359e26aec866```
