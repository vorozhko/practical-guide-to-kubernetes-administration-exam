# Kubernetes audit policy

## Audit log

Enable audit log and set the audit log output file.

```bash
--audit-log-path=/var/log/kube-apiserver-audit.log
--audit-policy-file=/etc/kubernetes/audit-policies/policy.yaml
```

## Example of audit policy.yaml

```yaml
apiVersion: audit.k8s.io/v1 # This is required.
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      # Resource "pods" doesn't match requests to any subresource of pods,
      # which is consistent with the RBAC policy.
      resources: ["pods"]
  # Log "pods/log", "pods/status" at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]

  # Don't log requests to a configmap called "controller-leader"
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]

  # Don't log watch requests by the "system:kube-proxy" on endpoints or services
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]

  # Don't log authenticated requests to certain non-resource URL paths.
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"

  # Log the request body of configmap changes in kube-system.
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    # This rule only applies to resources in the "kube-system" namespace.
    # The empty string "" can be used to select non-namespaced resources.
    namespaces: ["kube-system"]

  # Log configmap and secret changes in all other namespaces at the Metadata level.
  - level: Metadata
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]

  # Log all other resources in core and extensions at the Request level.
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.

  # A catch-all rule to log all other requests at the Metadata level.
  - level: Metadata
    # Long-running requests like watches that fall under this rule will not
    # generate an audit event in RequestReceived.
    omitStages:
      - "RequestReceived"

```

## Attach policy configuration to kube-apiserver

To inject config file into kube-apiserver container you can use following options:

* mount host path
* mount config map

In this guide I was using HostPath option.

Add mount path to /etc/kubernetes/manifests/kube-apiserver.yaml

```yaml
#....
    - mountPath: /etc/kubernetes/audit-policies
      name: audit-policies
      readOnly: true
#....
  - hostPath:
      path: /etc/kubernetes/audit-policies
      type: DirectoryOrCreate
    name: audit-policies
```

At this point policy.yaml is available inside container under /etc/kubernetes/audit-policies/policy.yaml path.

## Log rotation options

```bash
# --audit-log-maxage defined the maximum number of days to retain old audit log files
--audit-log-maxage=7
# --audit-log-maxbackup defines the maximum number of audit log files to retain
--audit-log-maxbackup=2
# --audit-log-maxsize defines the maximum size in megabytes of the audit log file before it gets rotated
--audit-log-maxsize=10
```

## Setup log collectors

Extract audit logs from kube-apiserver container using fluentd or logstash. See [log collectors examples](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/#log-collector-examples)
