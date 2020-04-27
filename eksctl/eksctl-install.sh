#!/bin/bash

# Create cluster
# Adjust --ssh-public-key
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


