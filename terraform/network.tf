
resource "aws_vpc" "kubeforge" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "kubeforge_public" {
  vpc_id                  = aws_vpc.kubeforge.id
  cidr_block              = "172.31.32.0/20"
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_internet_gateway" "kubeforge" {
  vpc_id = aws_vpc.kubeforge.id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table" "kubeforge_public" {
  vpc_id = aws_vpc.kubeforge.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubeforge.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_security_group" "kubeforge" {
  name        = "launch-wizard-1"
  description = "launch-wizard-1 created 2026-10-16T07:31:03.474Z"
  vpc_id      = aws_vpc.kubeforge.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["202.131.133.53/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    prevent_destroy = true
  }
}
