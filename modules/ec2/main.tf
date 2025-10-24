# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create AWS key pair from SSH public keys if provided
resource "aws_key_pair" "ec2_key" {
  count = length(var.ssh_public_keys) > 0 ? 1 : 0

  key_name   = "${var.instance_name}-key"
  public_key = var.ssh_public_keys[0] # AWS key pair only supports one key
  
  tags = {
    Name        = "${var.instance_name}-key"
    Environment = var.environment
  }
}

# Get the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Security group for EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} EC2 instance"
  vpc_id      = var.vpc_id

  # Allow SSH from anywhere (for testing)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP from GCP VPC
  ingress {
    description = "ICMP from GCP VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  # Allow all traffic from GCP VPC
  ingress {
    description = "All traffic from GCP VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  ingress {
    description = "All UDP from GCP VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  # Allow all traffic within AWS VPC
  ingress {
    description = "All traffic from AWS VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
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

# EC2 Instance
resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = length(var.ssh_public_keys) > 0 ? aws_key_pair.ec2_key[0].key_name : var.key_name
  
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
  # Enable public IP for SSH access (optional)
  associate_public_ip_address = var.enable_public_ip

  root_block_device {
    volume_type = "gp3"
    volume_size = var.disk_size
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              apt-get update
              apt-get upgrade -y
              
              # Install useful tools
              apt-get install -y iputils-ping traceroute net-tools curl wget htop
              
              # Add additional SSH keys if provided (beyond the first one in key pair)
              ${length(var.ssh_public_keys) > 1 ? "mkdir -p /home/ubuntu/.ssh" : ""}
              ${length(var.ssh_public_keys) > 1 ? "touch /home/ubuntu/.ssh/authorized_keys" : ""}
              ${join("\n", [for idx, key in var.ssh_public_keys : idx > 0 ? "echo '${key}' >> /home/ubuntu/.ssh/authorized_keys" : "# First key already in key pair"])}
              ${length(var.ssh_public_keys) > 1 ? "chown -R ubuntu:ubuntu /home/ubuntu/.ssh" : ""}
              ${length(var.ssh_public_keys) > 1 ? "chmod 700 /home/ubuntu/.ssh" : ""}
              ${length(var.ssh_public_keys) > 1 ? "chmod 600 /home/ubuntu/.ssh/authorized_keys" : ""}
              
              # Enable IP forwarding
              echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
              sysctl -p
              
              # Log startup
              echo "EC2 instance ${var.instance_name} started at $(date)" > /var/log/instance-startup.log
              
              # Create test file
              echo "Hello from AWS EC2!" > /home/ubuntu/welcome.txt
              chown ubuntu:ubuntu /home/ubuntu/welcome.txt
              EOF

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Purpose     = "vpn-connectivity-test"
  }
}
