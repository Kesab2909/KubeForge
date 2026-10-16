
variable "aws_region" {
  description = "AWS region for KubeForge infrastructure"
  type        = string
  default     = "ap-southeast-2"
}

variable "instance_id" {
  description = "ID of the existing KubeForge EC2 instance"
  type        = string
  default     = "i-0ebb2d25fc51abb69"
}
