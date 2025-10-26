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

variable "network_name" {
  type = string
}

variable "subnet_regions" {
  type = list(string)
}

variable "gcp_vpc_cidr" {
  type = string
  default = "10.10.0.0/16"
}

variable "aws_vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  type = bool
  default = true
}

variable "enable_vpn_gateway" {
  type = bool
  default = false
}

variable "aws_azs" {
  type = list(string)
  default = [ "ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c" ]
}

variable "aws_private_subnets" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "aws_public_subnets" {
  type = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "aws_vpc_name" {
  type = string
  default = "aws-net"
}

# Cloud NAT Configuration
variable "enable_cloud_nat" {
  type        = bool
  description = "Enable Cloud NAT for GCP VMs to access internet without public IP"
  default     = true
}

variable "cloud_nat_region" {
  type        = string
  description = "Region for Cloud NAT (should match VM region)"
  default     = ""
}

variable "cloud_nat_router_asn" {
  type        = number
  description = "ASN for Cloud NAT router (must be different from VPN router)"
  default     = 64520
}
