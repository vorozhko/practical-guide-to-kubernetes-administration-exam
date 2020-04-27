# Practical guide to secure cluster communications

## Before you begin
If you do not already have a cluster, you can create one by using [Minikube](https://kubernetes.io/docs/setup/learning-environment/minikube/).

## Download cfssl and cfssljson
```
wget -O cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget -O cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x ./cfssl ./cfssljson
```

## Run some workloads:
```
kubectl run nginx --image=nginx
kubectl expose pod nginx --port=80 --name nginx
```

## Generate certificate sign in request for service and pods
```
cat <<EOF | ./cfssl genkey - | ./cfssljson -bare server
{
  "hosts": [
    "nginx.default.svc.cluster.local",
    "nginx.default.pod.cluster.local",
    "10.103.225.57",
    "192.168.50.68"
  ],
  "CN": "nginx.default.pod.cluster.local",
  "key": {
    "algo": "ecdsa",
    "size": 256
  }
}
EOF
```
Where 10.103.225.57 is service ip and 192.168.50.68 is pod ip.

## Create a Certificate Signing Request object to send to the Kubernetes API
```
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: nginx.default
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF
```
Check status: ```kubectl describe csr nginx```

## Approve certificate
Two requirements:

* The subject of the CSR controls the private key used to sign the CSR. This addresses the threat of a third party masquerading as an authorized subject. In the above example, this step would be to verify that the pod controls the private key used to generate the CSR.
* The subject of the CSR is authorized to act in the requested context. This addresses the threat of an undesired subject joining the cluster. In the above example, this step would be to verify that the pod is allowed to participate in the requested service.

```kubectl certificate approve```

## Download certificate file to use in the pod
```
kubectl get csr nginx.default -o jsonpath='{.status.certificate}' \
    | base64 --decode > server.crt
```

## Create TLS secret to consume by pod
```kubectl create secret tls nginx --cert=./server.crt --key=./server-key.pem```

Mount secret as volume
```
cat <<EOF | kubectl apply -f -
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
        volumeMounts:
        - name: secret-volume
          readOnly: true
          mountPath: "/etc/secret-volume"
      volumes:
      - name: secret-volume
        secret:
          secretName: nginx
EOF
```

When the container’s command runs, the pieces of the key will be available in:
```
/etc/secret-volume/tls.crt
/etc/secret-volume/tls.key
```

To verify files location you can exec into pod:
```kubectl exec -ti nginx-deployment-67844cc956-4c5xk -- ls /etc/secret-volume```
