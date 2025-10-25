variable "instance_name" {
  type        = string
  description = "Name of the EC2 instance"
  default     = "aws-ec2"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the instance will be created"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the instance will be created"
}

variable "gcp_vpc_cidr" {
  type        = string
  description = "GCP VPC CIDR for security group rules"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR for security group rules"
}

variable "enable_public_ip" {
  type        = bool
  description = "Enable public IP for the instance"
  default     = true
}

variable "disk_size" {
  type        = number
  description = "Root volume size in GB"
  default     = 8
}

variable "environment" {
  type        = string
  description = "Environment label"
  default     = "production"
}

variable "key_name" {
  type        = string
  description = "AWS key pair name for SSH access (optional, ignored if ssh_public_keys is provided)"
  default     = null
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "List of SSH public keys to add to the EC2 instance (format: 'ssh-rsa AAAA... user@host')"
  default     = []
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to add to the EC2 instance (format: 'ssh-rsa AAAA... user@host')"
  default     = null
}

# EC2 Instance Connect Endpoint Configuration
variable "aws_create_vpc_endpoints" {
  type        = bool
  description = "Create EC2 Instance Connect Endpoint to SSH to EC2 instances via private IP"
  default     = false
}

variable "preserve_client_ip" {
  type        = bool
  description = "Preserve client IP address when connecting through EIC Endpoint"
  default     = false
}
