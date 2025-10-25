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

variable "vm_name" {
  type        = string
  description = "Name of the GCP VM instance"
  default     = "gcp-vm"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the VM instance"
  default     = "e2-small"
}

variable "zone" {
  type        = string
  description = "Zone where the VM will be created"
}

variable "image" {
  type        = string
  description = "Boot disk image for the VM"
  default     = "ubuntu-os-cloud/ubuntu-2404-noble-amd64-v20251014"
}

variable "disk_size" {
  type        = number
  description = "Boot disk size in GB"
  default     = 10
}

variable "disk_type" {
  type        = string
  description = "Boot disk type"
  default     = "pd-standard"
}

variable "network" {
  type        = string
  description = "VPC network name"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork self link"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR for firewall rules"
}

variable "environment" {
  type        = string
  description = "Environment label"
  default     = "production"
}

variable "ssh_keys" {
  type        = list(string)
  description = "List of SSH public keys to add to the VM (format: 'username:ssh-rsa AAAA... user@host')"
  default     = []
}

variable "create_service_account" {
  description = "Whether to create a new service account or use existing one"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Existing service account email to use (if create_service_account is false)"
  type        = string
  default     = ""
}

variable "gcp_vpc_cidr" {
  type        = string
  description = "GCP VPC CIDR for documentation and scripts"
  default     = "10.10.0.0/16"
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable Google Cloud Ops Agent for monitoring"
  default     = false
}

variable "custom_commands" {
  type        = string
  description = "Custom shell commands to run during startup"
  default     = ""
}