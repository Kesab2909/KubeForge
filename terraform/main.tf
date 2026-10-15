terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
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
