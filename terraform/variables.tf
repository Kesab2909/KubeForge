
variable "aws_region" {
  description = "AWS region for KubeForge infrastructure"
  type        = string
  default     = "ap-southeast-2"
}

variable "ami_id" {
  description = "Amazon Linux AMI ID for the target AWS region"
  type        = string
  default     = "ami-0587b5bb1bc9eab99"
}

variable "instance_type" {
  description = "EC2 instance type for KubeForge"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
  default     = "kubeforge-key"
}

variable "ssh_cidr" {
  description = "IPv4 CIDR allowed to SSH into the instance"
  type        = string
  default     = "202.131.133.53/32"

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0))
    error_message = "ssh_cidr must be a valid IPv4 or IPv6 CIDR."
  }
}

