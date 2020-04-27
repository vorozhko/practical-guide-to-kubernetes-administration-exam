# Testing Kubernetes AWS ELB support
## Overview
In this guide I am testing Kubernetes AWS ELB features like:
* http/https support
* access logs
* connections draining

## Before you begin
If you do not already have a cluster, you can create one by using [Minikube](https://kubernetes.io/docs/setup/learning-environment/minikube/).

## Prepare Kustomize secrets data
This guide is using kustomize with "secrets" overlay to exclude secret data from git repository. To run examples in this guide you need to provide valid AWS SSL certificate ARN and create "secrets" overlay.

Create secrets overlay:
```bash
mkdir -p overlays/secrets
```
Create overlays/secrets/service.yaml with following content:
```yaml
---
# ELB http and https support
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:us-east-1:123456789012:certificate/1234-1234-1234-1234-1234567890"
```
Replace "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" with validate AWS certificate arn.

Create overlays/secrets/kustomization.yaml:
```yaml
bases:
- ../../base
patchesStrategicMerge:
- service.yaml
```

## Deployment with Kustomize
```
kubectl apply -k nginx/overlays/secrets/
```
Secrets folder contain overlay for AWS Certificate ARN.

## Testing ELB http and https support

For web application which support of both protoclos http and https Kubernetes provide special Service annotations: backcend-protocol and ssl-ports. 
In following example backend protocol accept http connections and all https connections are be terminate on load balancing level and proxy to backed by http protocol.
Lets test how it will work. 

To terminate TLS connection at ELB provision a certificate in AWS Certificate manager for your domain. Update aws-load-balancer-ssl-cert annotaion with certificate ARN in nginx Service.

Create service and deployment of nginx web server.

AWS ELB http and https support

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  annotations:
	service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
    - protocol: TCP
      port: 443
      targetPort: 80
  type: LoadBalancer
---
#Nginx deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80

```
  
## AWS ELB Proxy protocol

The PROXY protocol provides a convenient way to safely transport connection
information such as a client's address across multiple layers of NAT or TCP
proxies.
This is very common scenario when packets transfer from node to node to reach the right Pod container.

To enable AWS ELB proxy protocol use following annotation:   
```
metadata:
  name: my-service
  annotations:
	service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
```

## AWS ELB Access logs
```
metadata:
  name: my-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
    # Specifies whether access logs are enabled for the load balancer
    service.beta.kubernetes.io/aws-load-balancer-access-log-emit-interval: "60"
    # The interval for publishing the access logs. You can specify an interval of either 5 or 60 (minutes).
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: "my-bucket"
    # The name of the Amazon S3 bucket where the access logs are stored
    service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-prefix: "my-bucket-prefix/prod"
    # The logical hierarchy you created for your Amazon S3 bucket, for example `my-bucket-prefix/prod`
```

## AWS ELB Connection draining
```
metadata:
  name: my-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-connection-draining-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-connection-draining-timeout: "60"
```