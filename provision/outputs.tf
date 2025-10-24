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

# Network Outputs
output "gcp_network_name" {
  description = "GCP VPC network name"
  value       = module.network.gcp_network
}

output "gcp_subnets" {
  description = "GCP subnet self links"
  value       = module.network.gcp_subnets
}

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = module.network.aws_vpc_id
}

output "aws_private_subnets" {
  description = "AWS private subnet IDs"
  value       = module.network.aws_private_subnets
}

# VPN Outputs
output "transit_gateway_id" {
  description = "AWS Transit Gateway ID"
  value       = module.gcp-aws-ha-vpn.aws_transit_gateway_id
}

output "gcp_vpn_gateway_id" {
  description = "GCP HA VPN Gateway ID"
  value       = module.gcp-aws-ha-vpn.gcp_vpn_gateway_id
}

output "gcp_router_name" {
  description = "GCP Cloud Router name"
  value       = module.gcp-aws-ha-vpn.gcp_router_name
}

# VM Outputs
output "vm_instance_name" {
  description = "GCP VM instance name"
  value       = module.vm.instance_name
}

output "vm_internal_ip" {
  description = "GCP VM internal IP address"
  value       = module.vm.internal_ip
}

output "vm_zone" {
  description = "GCP VM zone"
  value       = module.vm.zone
}

output "vm_iap_ssh_command" {
  description = "Command to SSH into the VM via IAP"
  value       = module.vm.iap_ssh_command
}

output "vm_service_account" {
  description = "Service account email for the VM"
  value       = module.vm.service_account_email
}

# EC2 Outputs
output "ec2_instance_name" {
  description = "AWS EC2 instance name"
  value       = module.ec2.instance_name
}

output "ec2_private_ip" {
  description = "AWS EC2 private IP address"
  value       = module.ec2.private_ip
}

output "ec2_public_ip" {
  description = "AWS EC2 public IP address (if enabled)"
  value       = module.ec2.public_ip
}

output "ec2_ssh_command" {
  description = "Command to SSH into the EC2 instance"
  value       = module.ec2.ssh_command
}

# Connection Information
output "connection_info" {
  description = "Information for connecting and testing the VPN setup"
  value       = <<-EOT
    
    =================================================================
    GCP to AWS VPN Connection Setup Complete
    =================================================================
    
    GCP Router ASN: ${var.gcp_router_asn}
    AWS Router ASN: ${var.aws_router_asn}
    
    GCP VM Instance: ${module.vm.instance_name}
    GCP VM Internal IP: ${module.vm.internal_ip}
    GCP VM Zone: ${module.vm.zone}
    
    AWS EC2 Instance: ${module.ec2.instance_name}
    AWS EC2 Private IP: ${module.ec2.private_ip}
    AWS EC2 Public IP: ${module.ec2.public_ip}
    
    To connect to the GCP VM via IAP:
    ${module.vm.iap_ssh_command}
    
    To connect to the AWS EC2 instance:
    ${module.ec2.ssh_command}
    
    AWS VPC CIDR: ${var.aws_vpc_cidr}
    GCP VPC CIDR: 10.10.0.0/16
    
    To test VPN connectivity:
    
    From GCP VM to AWS:
    1. SSH into GCP VM: ${module.vm.iap_ssh_command}
    2. Ping AWS EC2: ping ${module.ec2.private_ip}
    3. Check routes: ip route show
    
    From AWS EC2 to GCP:
    1. SSH into EC2: ${module.ec2.ssh_command}
    2. Ping GCP VM: ping ${module.vm.internal_ip}
    3. Check routes: ip route show
    
    =================================================================
  EOT
}
