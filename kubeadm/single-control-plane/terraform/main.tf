terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "dev-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  #private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = false
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

## EC2 instances for Kubernetes cluster
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "kubernetes_master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.kubernetes_master.id]
  subnet_id = module.vpc.public_subnets[0]
  key_name = "xps"
  user_data = filebase64("${path.module}/../../scripts/install-kubeadm.sh")
  tags = {
    Name = "kubernetes master"
  }
}

# resource "aws_instance" "kubernetes_worker" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t3.small"
#   vpc_security_group_ids = [aws_security_group.kubernetes_worker.id]
#   subnet_id = module.vpc.public_subnets[0]
#   key_name = "xps"
#   user_data = filebase64("${path.module}/../../scripts/install-kubeadm.sh")
#   tags = {
#     Name = "kubernetes worker"
#   }
# }


#Add all necessary ports for Kubernetes control plan: 6443* 2379-2380 10250 10251 10252
resource "aws_security_group" "kubernetes_master" {
  name_prefix = "kubernetes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    description = "Control plane ports"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  ingress {
    description = "Control plane ports"
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  ingress {
    description = "Control plane ports"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Add all necessary ports for Kubernetes worker nodes: 10250 30000-32767
resource "aws_security_group" "kubernetes_worker" {
  name_prefix = "kubernetes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    description = "Worker ports"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  ingress {
    description = "Worker ports"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}