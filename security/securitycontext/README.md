# Quick test of Security Context for a Pod

## Set the security context for a Pod
```yaml 
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  containers:
  - name: sec-ctx-demo
    image: busybox
    command: [ "sh", "-c", "sleep 1h" ]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      allowPrivilegeEscalation: false
```

```bash
kubectl apply -f https://k8s.io/examples/pods/security/security-context.yaml
kubectl get pod security-context-demo
kubectl exec -it security-context-demo -- sh
```

List running processes:
```bash
ps
PID   USER     TIME  COMMAND
    1 1000      0:00 sleep 1h
    6 1000      0:00 sh
   14 1000      0:00 ps
```
The output shows that the processes are running as user 1000, which is the value of runAsUser.


Navigate to /data mount:
```
cd /data
ls -l
drwxrwsrwx    2 root     2000          4096 Apr 30 07:19 demo
```
The output shows that the /data/demo directory has group ID 2000, which is the value of fsGroup.


Create new file in demo folder:
```
cd demo
echo hello > testfile
ls -l
-rw-r--r--    1 1000     2000             6 Apr 30 07:24 testfile
```
The output shows that testfile has group ID 2000, which is the value of fsGroup.


Run following command:
```
id
uid=1000 gid=3000 groups=2000
```
The output shows that the user GID is 3000 which is the same as RunAsGroup.
