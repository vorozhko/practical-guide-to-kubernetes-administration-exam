# Prepare Kubernetes images with Packer

## Pakcer Builders
**Builders** section define base image, EC2 instate type and other settings to build an image.
```json
"source_ami_filter": {
    "filters": {
        "virtualization-type": "hvm",
        "name": "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*",
        "root-device-type": "ebs"
    },
    "owners": ["099720109477"],
    "most_recent": true
},
"instance_type": "t2.medium",
``` 

## Packer Provisioners

### Prepare base image with Docker and Kubernetes 
I have used [install-kubeadm.sh](../kubeadm/scripts/install-kubeadm.sh) script to setup Docker and Kubernetes packages and settings.
```json
{
    "type": "shell",
    "script": "../kubeadm/scripts/install-kubeadm.sh",
    "execute_command": "sudo sh -c '{{ .Vars }} {{ .Path }}'"
}
```

### Create kubelet bootstrap script
Bootstrap Kubernetes kubelet process when instance created from AMI.

Upload kubelet-init.sh in **/var/lib/cloud/scripts/per-instance/** which will be executed first time when server is creted from AMI.
```json
{
    "type": "file",
    "source": "kubelet-init.sh",
    "destination": "/tmp/"
},
{
    "type": "shell",
    "inline": 
    [
    "sudo cp /tmp/kubelet-init.sh /var/lib/cloud/scripts/per-instance/",
    "sudo chmod +x /var/lib/cloud/scripts/per-instance/kubelet-init.sh"
    ]
}
```

## Unanswered questions
**How to provision additioanl control plane nodes and worker nodes which require tokens and certificate keys to join the cluster?**

## References
* [Packer Kuberenetes control plane JSON](master.json)
* [Kubeadm provisioner script install-kubeadm.sh](../kubeadm/scripts/install-kubeadm.sh)
* [kubelet-init.sh](kubelet-init.sh)