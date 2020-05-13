# Provision Kubernetes Cluster(EKS) with eksctl

*eksctl* is **the fastest** way to spin up managed kubernetes cluster at AWS.
No pre-existing infrastructure required. Everything will be provisioned with CloudFormation templates.

## Install EKS cluster

### Install requirements

* [Install requirements](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)

### Create cluster

* Create dev cluster. See [eksctl-install.sh](./eksctl-install.sh)

```bash
eksctl create cluster \
--name dev-test \
--region us-east-1 \
--zones us-east-1a,us-east-1b,us-east-1c \
--nodegroup-name standard-workers \
--node-type t2.medium \
--nodes 1 \
--nodes-min 1 \
--nodes-max 3 \
--ssh-access \
--ssh-public-key ~/.ssh/ssh-key.pub \
--managed
```

> Adjust --ssh-public-key for your needs

### Troubleshooting

If you encounter any issues, check CloudFormation console or try ```eksctl utils describe-stacks --region=us-east-1 --cluster=dev-test```

### Scale up cluster

```eksctl scale nodegroup --cluster dev-test --name standard-workers --nodes 2```

### Check nodes status

```bash
kubectl get nodes
```

### SSH to a node

```ssh ec2-user@<ec2-ip>```

### Check pods status

```bash
kubectl get pods --all-namespaces
```

## Destroy EKS cluster

```eksctl delete cluster --name dev-test```
