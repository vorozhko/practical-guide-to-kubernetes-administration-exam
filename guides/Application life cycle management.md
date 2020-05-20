# Application life cycle management

## Install process

### Install nginx 1.12.2 with 2 pods

Create deployment template with nginx version 1.12.2

```bash
kubectl create  deployment nginx --save-config=true --image=nginx:1.12.2 --dry-run=client -o yaml > nginx.yaml
```

Edit nginx.yaml to update replicas count.

```bash
edit nginx.yaml
```

Apply deployment template to Kubernetes cluster

```bash
kubectl apply --record=true -f nginx.yaml
```

## Scale

### Scale up to 4 pods

```bash
kubectl scale deployment nginx --replicas 4
```

### Scale down to 2 pods

```bash
kubectl scale deployment nginx --replicas 2
```

## Upgrade

### Upgrade nginx to 1.13.8

Update deployment container image with `kubectl set image`

```bash
kubectl set image --record=true deployment/nginx nginx=nginx:1.13.8
deployment.apps/nginx image updated
```

Use --record=true to save what caused the deployment

```bash
kubectl get pods
NAME                     READY   STATUS              RESTARTS   AGE
nginx-76d56bc6fb-cdrdl   0/1     ContainerCreating   0          3s
nginx-8f4745b9c-4lbwn    1/1     Running             0          5m51s
nginx-8f4745b9c-8rflb    1/1     Running             0          5m51s
```

### Another option to upgrade is to patch deployment

Patch nginx deployment with latest version

```bash
kubectl patch deployment nginx --type json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"nginx:latest"}]'
deployment.apps/nginx patched
```

Lets check patching result

```bash
kubectl get deployments.apps nginx -o json | jq ".spec.template.spec.containers[0].image"
"nginx:latest"
```

Lets check deployment history

```bash
kubectl rollout history deployment nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
3         kubectl set image deployment/nginx nginx=nginx:1.14.8 --record=true
4         kubectl set image deployment/nginx nginx=nginx:1.13.8 --record=true
5         kubectl set image deployment/nginx nginx=nginx:1.13.8 --record=true
6         kubectl set image deployment/nginx nginx=nginx:1.13.8 --record=true
```

## Rollback

### Lets make faulty deployment

Upgrade nginx to 1.14.8 which doesn't exist

```bash
kubectl set image deployment/nginx nginx=nginx:1.14.8 --record
```

### Check upgrade status

```bash
kubectl rollout status deployment nginx
Waiting for deployment "nginx" rollout to finish: 1 out of 2 new replicas have been updated...
```

kubectl is waiting for deployment to finish which will not happen due to incorrect image name. So, we need to rollback the deployment. Press Ctrl+C to stop waiting for `kubectl rollout status` update.

### Rollback latest deployment

Undo the current deployment

```bash
kubectl rollout undo deployment nginx
deployment.apps/nginx rolled back
```

### Check deployment history

```bash
kubectl rollout history deployment nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
4         kubectl set image deployment/nginx nginx=nginx:1.13.8 --record=true
5         kubectl set image deployment/nginx nginx=nginx:1.13.8 --record=true
7         kubectl set image deployment/nginx nginx=nginx:1.14.8 --record=true
8         kubectl set image deployment/nginx nginx=nginx:1.13.8 --record=true

```

Notice that `undo` command moved revision record 6 to record 8 in history of deployment. So, it tell operators that rollback was applied.
