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

variable "impersonate_service_account" {
  type = string
}

variable "project_id" {
  type = string
}

variable "network_name" {
  type = string
}

variable "subnet_regions" {
  type = list(string)
}

variable "vpn_gwy_region" {
  type = string
}

variable "gcp_router_asn" {
  type = string
}

variable "aws_router_asn" {
  type = string
}

variable "aws_vpc_cidr" {
  type = string
}

variable "gcp_vpc_cidr" {
  type = string
}


variable "shared_secret" {
  type = string
}

variable "num_tunnels" {
  type = number
  validation {
    condition     = var.num_tunnels % 2 == 0
    error_message = "number of tunnels needs to be in multiples of 2."
  }
  validation {
    condition     = var.num_tunnels >= 4
    error_message = "min 4 tunnels required for high availability."
  }
  description = <<EOF
    Total number of VPN tunnels. This needs to be in multiples of 2.
  EOF
}

# VM Configuration Variables
variable "vm_name" {
  type        = string
  description = "Name of the GCP VM instance"
  default     = "gcp-vm"
}

variable "vm_machine_type" {
  type        = string
  description = "Machine type for the VM instance"
  default     = "e2-small"
}

variable "vm_zone" {
  type        = string
  description = "Zone where the VM will be created"
}

variable "vm_image" {
  type        = string
  description = "Boot disk image for the VM"
  default     = "ubuntu-os-cloud/ubuntu-2404-noble-amd64-v20251014"
}

variable "environment" {
  type        = string
  description = "Environment label for resources"
  default     = "production"
}

# EC2 Configuration Variables
variable "ec2_instance_name" {
  type        = string
  description = "Name of the EC2 instance"
  default     = "aws-ec2"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ec2_enable_public_ip" {
  type        = bool
  description = "Enable public IP for EC2 instance"
  default     = true
}

variable "ec2_key_name" {
  type        = string
  description = "AWS key pair name for EC2 SSH access (optional, ignored if ssh_public_keys is provided)"
  default     = null
}

# SSH Keys Configuration
variable "ssh_public_keys" {
  type        = list(string)
  description = "List of SSH public keys to add to both GCP VM and AWS EC2"
  default     = []
}

variable "ssh_private_key_file" {
  type        = string
  description = "Path to SSH private key file to install on instances for inter-instance connectivity"
  default     = "../ssh-key/id_ed25519"
}

variable "aws_create_vpc_endpoints" {
  type        = bool
  description = "Create EC2 Instance Connect Endpoint to SSH to EC2 instances via private IP"
  default     = false
}

# Cloud NAT Configuration
variable "enable_cloud_nat" {
  type        = bool
  description = "Enable Cloud NAT for GCP VMs to access internet without public IP"
  default     = true
}

variable "cloud_nat_region" {
  type        = string
  description = "Region for Cloud NAT (defaults to vpn_gwy_region if not specified)"
  default     = ""
}