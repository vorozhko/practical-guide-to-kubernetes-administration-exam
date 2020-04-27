# Provision Kubernetes Cluster(EKS) with eksctl

*eksctl* is **the fastest** way to spin up managed kubernetes cluster at AWS.
No pre-existing infrastructure required. Everything will be provisioned with CloudFormation templates.

## Quick start

### Install requirements cluster
* [Install requirements](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)

### Create cluster
* Create dev cluster. See [install.sh](./eksctl-install.sh)

### Troubleshooting
If you encounter any issues, check CloudFormation console or try ```eksctl utils describe-stacks --region=us-east-1 --cluster=dev-test```

### SSH to a node
```ssh ec2-user@<ec2-ip>```

### Scale up cluster
```eksctl scale nodegroup --cluster dev-test --name standard-workers --nodes 2```

### Install apps
```bash
cd apps/
kubectl apply -k nginx/overlays/secret/
kubectl get pods
kubectl get svc
```
### Delete apps
We have to delete apps explicitly to clean up provision load balancers for services.
```k delete -k nginx/overlays/secrets/```

# Destroy cluster
```eksctl delete cluster --name dev-test```