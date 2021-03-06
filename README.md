# Kubernetes Certified Admnisitration Practical Guide

This is a collection of **Practical guides** to Kubernetes Certified Admnisitration exam. For each Kubernetes exam curriculum section I have made one or more scripts to help understand practical side of exam. 

I have used **Terraform** to provision infrastructure and **bash** scripts to pre-install software.

## Installation, Configuration and Validation 12%

For Terraform templates to work you need to prepare default aws profile and adjust AWS region in **variables.tf**(default us-east-1).

### Install single control palne Kubernetes with kubeadm

See [Practical guide to Kubernetes Single control plane with Kubeadm](kubeadm/single-control-plane/README.md)

If you prefer Vagrant box see [how to run Kubernetes Single control plane using Vagrant](vagrant/kubernetes/README.md)

### Configure High Available Kubernetes cluster

See [Practical guide to High Available Kubernetes control plane with Terraform](kubeadm/ha-control-plane/README.md)

### Upgrade Kubernetes cluster

See [Practical guide to Kubernetes cluster upgrade](kubeadm/upgrade-cluster/README.md)

### Configure secure cluster communications

See [Practical guide to secure cluster communications](guides/secure-cluster-communications.md)

## Core Concepts 19%

### Understanding Services and other network primitives

See [Testing ELB http/https support, access logs, Proxy mode and connection draining](apps/nginx/README.md)

## Security 12%

### Container security with PodSecurityPolicy

See [Practical guide to PodSecurityPolicy](security/podsecuritypolicy/README.md)

### Declare a NetworkPolicy

See [Quick test of NetworkPolicy](security/networkpolicy/README.md)

### Manage TLS Certificates in a Cluster

See [Practical guide to secure cluster communications](guides/secure-cluster-communications.md)

### Configure Security Context for a Pod

See [Quick test of Security Context for a Pod](security/securitycontext/README.md)

## Networking 11%

TBD

## Cluster Maintenance 11%

* [Building Kubernetes control plane image with Packer](packer/README.md)

## Troubleshooting 10%

* [Checking Kubernetes cluster health](guides/kubernetes-cluster-health.md)

## Storage 7%

TBD

## Application Lifecycle Management 8%

* [Practical guide to application deployment upgrade process](guides/Application%20life%20cycle%20management.md)

## Scheduling 5%

TBD

## Logging/Monitoring 5%

TBD
