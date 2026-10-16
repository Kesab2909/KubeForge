
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "aws_region" {
  description = "AWS region for the fresh KubeForge deployment"
  type        = string
  default     = "ap-southeast-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "container_image" {
  description = "Immutable KubeForge API image published by CI"
  type        = string
  default     = "ghcr.io/kesab2909/kubeforge-api:d3748d586ca82ea494335cf54d91c0315da6499d"
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_vpc" "kubeforge" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "kubeforge-fresh-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.kubeforge.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeforge-fresh-public-subnet"
  }
}

resource "aws_internet_gateway" "kubeforge" {
  vpc_id = aws_vpc.kubeforge.id

  tags = {
    Name = "kubeforge-fresh-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.kubeforge.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubeforge.id
  }

  tags = {
    Name = "kubeforge-fresh-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "api" {
  name        = "kubeforge-fresh-api"
  description = "HTTP access to the KubeForge API"
  vpc_id      = aws_vpc.kubeforge.id

  ingress {
    description = "Public HTTP API"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kubeforge-fresh-api-sg"
  }
}

resource "aws_instance" "api" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.api.id]
  associate_public_ip_address = true

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf install -y docker
    systemctl enable --now docker
    docker pull ${var.container_image}
    docker run -d \
      --name kubeforge-api \
      --restart unless-stopped \
      -p 80:8000 \
      ${var.container_image}
  EOF

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "kubeforge-fresh-api"
  }
}

output "api_url" {
  description = "Public URL of the fresh KubeForge API deployment"
  value       = "http://${aws_instance.api.public_ip}"
}

output "api_health_url" {
  description = "Health-check endpoint"
  value       = "http://${aws_instance.api.public_ip}/health"
}

output "instance_id" {
  description = "Fresh EC2 instance ID"
  value       = aws_instance.api.id
}
