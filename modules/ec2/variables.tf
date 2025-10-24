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
