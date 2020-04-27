# Practical guide to PodSecurityPolicy

This is short version of [PSP RBAC Example](https://github.com/kubernetes/examples/blob/master/staging/podsecuritypolicy/rbac/README.md) adapted to use with Minikube.

## What is PodSecurityPolicy 
PodSecurityPolicy(PSP) is a Container level of security defence which follow after Cloud and Cluster security levels.

## PSP main control aspects
* Running of privileged containers
* Usage of host resources(processes, network, filesystem)
* Usage of security profiles(AppArmor, SELinux, seccomp)

## Enable PodSecurityPolicy admission controller
On Minikube to enable PodSecurityPolicy admission plugin use --extra-config:
```bash
minikube start --extra-config=apiserver.enable-admission-plugins=PodSecurityPolicy
```
>For most of the public cloud Kubernetes offering PodSecurityPolicy admission controller should be enabled by default.

## Creating the policies, roles and binding

### Create "restricted" and "privileged" policies
Privileged policy will allow any type of pod. It will be available for cluster operators to run privileged containers.

Restricted policy will be available for cluster users(e.g. developers). It will limit the scope of container security privileges and enforce security practices adopted in a company.

```yaml
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: privileged
spec:
  fsGroup:
    rule: RunAsAny
  privileged: true
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - '*'
  allowedCapabilities:
  - '*'
  hostPID: true
  hostIPC: true
  hostNetwork: true
  hostPorts:
  - min: 1
    max: 65536
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  fsGroup:
    rule: RunAsAny
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - 'emptyDir'
  - 'secret'
  - 'downwardAPI'
  - 'configMap'
  - 'persistentVolumeClaim'
  - 'projected'
  hostPID: false
  hostIPC: false
  hostNetwork: false
```

```bash
kubectl create -f https://github.com/vorozhko/cka-exam-prep/security/podsecuritypolicy/policies.yaml
```

### Roles and bindings
In order to create a pod, either the creating user or the service account specified by the pod must be authorized to use a PodSecurityPolicy object that allows the pod, within the pod's namespace.

* ClusterRole "restricted-psp-user" allows the use verb on the restricted policy only.
* ClusterRole "privileged-psp-user" allows the use verb on the privileged policy only
* ClusterRoleBinding "privileged-psp-user": this user is bound to the privileged-psp-user role and restricted-psp-user role which gives users access to both policies.
* ClusterRoleBinding "restricted-psp-user": this user is bound to the restricted-psp-user role.

```
kubectl create -f https://github.com/vorozhko/cka-exam-prep/security/podsecuritypolicy/roles.yaml
kubectl create -f https://github.com/vorozhko/cka-exam-prep/security/podsecuritypolicy/bindings.yaml
```

## Testing PodSecurityPolicy
### Restricted user can create non-privileged pods
Create pod
```
kubectl --as=restricted-psp-user create -f https://github.com/vorozhko/cka-exam-prep/security/podsecuritypolicy/pod.yaml
pod "nginx" created
```

Check the PSP that allowed the pod
```
kubectl get pod nginx -o yaml |grep psp
    kubernetes.io/psp: restricted
```

### Restricted user cannot create privileged pods
Delete the existing pod
```
kubectl delete pod nginx
```

Create the privileged pod
```
kubectl --as=restricted-psp-user create -f https://github.com/vorozhko/cka-exam-prep/security/podsecuritypolicy/pod_priv.yaml
Error from server (Forbidden): error when creating "pod_priv.yaml": pods "nginx" is forbidden: unable to validate against any pod security policy: [spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed]
```
### Privileged user can create non-privileged pods
Create pod
```
kubectl --as=privileged-psp-user create -f https://github.com/vorozhko/cka-exam-prep/security/podsecuritypolicy/pod.yaml
```

Check the PSP that allowed the pod 
```
kubectl get pod nginx -o yaml | egrep "psp|privileged"
    kubernetes.io/psp: privileged
```

### Privileged user can create privileged pods
Delete the existing pod
```
kubectl delete pod nginx
```

Create pod
```
kubectl --as=privileged-psp-user create -f https://github.com/vorozhko/cka-exam-prep/security/podsecuritypolicy/pod_priv.yaml
```

Check the PSP that allowed the pod 
```
kubectl get pod nginx -o yaml | egrep "psp|privileged"
    kubernetes.io/psp: privileged
      privileged: true
```
