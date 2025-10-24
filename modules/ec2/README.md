# EC2 Module

This Terraform module creates an AWS EC2 instance configured to communicate with GCP resources through the VPN tunnel.

## Features

- Ubuntu 24.04 LTS (latest AMI)
- t3.micro instance (1 vCPU, 1GB RAM)
- Configured security groups for VPN traffic
- Automatic system updates on first boot
- Pre-installed networking tools

## Usage

```hcl
module "ec2" {
  source = "../modules/ec2"
  
  instance_name   = "aws-ec2"
  instance_type   = "t3.micro"
  vpc_id          = "vpc-xxxxx"
  subnet_id       = "subnet-xxxxx"
  gcp_vpc_cidr    = "10.10.0.0/16"
  aws_vpc_cidr    = "10.0.0.0/16"
  enable_public_ip = true
}
```

## Security Groups

The module creates security group rules that allow:
- SSH from anywhere (for testing)
- All traffic from GCP VPC CIDR
- All traffic within AWS VPC
- All outbound traffic

## Variables

See `variables.tf` for all available configuration options.

## Outputs

- `instance_id` - EC2 instance ID
- `private_ip` - Private IP address
- `public_ip` - Public IP address (if enabled)
- `ssh_command` - Command to SSH into the instance
