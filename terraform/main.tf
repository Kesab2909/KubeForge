
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "image_name" {
  description = "Container image built by the KubeForge CI pipeline"
  type        = string
  default     = "ghcr.io/kesab2909/kubeforge-api:latest"
}

output "container_image" {
  description = "KubeForge container image reference"
  value       = var.image_name
}

resource "aws_instance" "kubeforge" {
  ami                    = "ami-0587b5bb1bc9eab99"
  instance_type          = "t3.micro"
  subnet_id              = "subnet-07b22f5b57f48957c"
  vpc_security_group_ids = ["sg-092e4342da2fadf47"]
  key_name               = "kubeforge-key"

  tags = {
    Name = "kubeforge-server"
  }

  lifecycle {
    prevent_destroy = true
  }
}