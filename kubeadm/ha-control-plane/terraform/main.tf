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

## Latest ubuntu AMI
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

##
## Control plane
## * aws_launch_template(LT) - define instance parameters
## * aws_autoscaling_group(ASG) - use LT and define VPC subnets
## * aws_autoscaling_attachment - connect TG with ASG
## * aws_lb_target_group(TG) - define vpc
## * aws_lb(LB) - define subnets
## * aws_lb_listener - connect LB with TG

resource "aws_launch_template" "master" {
  name_prefix   = "master"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  
  key_name = "xps"
  user_data = filebase64("${path.module}/../../scripts/install-kubeadm.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "kubernetes master"
      Terraform = "1"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.kubernetes_master.id]
  }
}

resource "aws_autoscaling_group" "master" {
  desired_capacity   = 2
  max_size           = 3
  min_size           = 1
  vpc_zone_identifier = module.vpc.public_subnets

  launch_template {
    id      = aws_launch_template.master.id
    version = "$Latest"
  }
}

resource "aws_lb_target_group" "master" {
  name     = "master-lb-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_autoscaling_attachment" "master" {
  alb_target_group_arn   = aws_lb_target_group.master.arn
  autoscaling_group_name = aws_autoscaling_group.master.id
}

resource "aws_lb" "master" {
  name               = "control-plane-lb"
  internal           = false
  subnets            = module.vpc.public_subnets
  load_balancer_type = "network"

  enable_deletion_protection = false

  tags = {
    Environment = "dev"
    Terraform = "1"
  }
}


resource "aws_lb_listener" "master" {
  load_balancer_arn = aws_lb.master.arn
  port              = "6443"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.master.arn
  }
}

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
    cidr_blocks = [module.vpc.vpc_cidr_block,"0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##
## Worker nodes 
## * aws_launch_template(LT) - define instance parameters
## * aws_autoscaling_group(ASG) - use LT and define VPC subnets

resource "aws_launch_template" "worker" {
  name_prefix   = "worker"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  
  key_name = "xps"
  user_data = filebase64("${path.module}/../../scripts/install-kubeadm.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "kubernetes worker"
      Terraform = "1"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.kubernetes_worker.id]
  }
}

resource "aws_autoscaling_group" "worker" {
  desired_capacity   = 1
  max_size           = 3
  min_size           = 1
  vpc_zone_identifier = module.vpc.public_subnets

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }
}

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