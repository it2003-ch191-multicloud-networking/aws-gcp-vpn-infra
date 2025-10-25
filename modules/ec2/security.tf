resource "aws_security_group" "ec2_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  # Allow SSH from anywhere (or restrict to your IP)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from EIC Endpoint (if enabled)
  dynamic "ingress" {
    for_each = var.aws_create_vpc_endpoints ? [1] : []
    content {
      description     = "SSH from EC2 Instance Connect Endpoint"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [aws_security_group.eic_endpoint_sg[0].id]
    }
  }

  # Allow ICMP from GCP VPC
  ingress {
    description = "ICMP from GCP VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  # Allow all TCP traffic from GCP VPC
  ingress {
    description = "All TCP from GCP VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  # Allow all UDP traffic from GCP VPC
  ingress {
    description = "All UDP from GCP VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  # Allow ICMP from AWS VPC
  ingress {
    description = "ICMP from AWS VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  # Allow all TCP traffic from AWS VPC
  ingress {
    description = "All TCP from AWS VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  # Allow all UDP traffic from AWS VPC
  ingress {
    description = "All UDP from AWS VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.instance_name}-sg"
    Environment = var.environment
  }
}