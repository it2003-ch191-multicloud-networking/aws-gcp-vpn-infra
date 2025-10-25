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

# Read SSH private key file
locals {
  ssh_private_key = fileexists(var.ssh_private_key_file) ? file(var.ssh_private_key_file) : ""
}

module "network" {
  source         = "../modules/network"
  network_name   = var.network_name
  subnet_regions = var.subnet_regions
}

module "gcp-aws-ha-vpn" {
  source = "../modules/gcp-aws-ha-vpn"

  prefix              = "vpn"
  num_tunnels         = var.num_tunnels
  aws_router_asn      = var.aws_router_asn
  aws_vpc_cidr        = var.aws_vpc_cidr
  gcp_vpc_cidr        = var.gcp_vpc_cidr
  gcp_router_asn      = var.gcp_router_asn
  project_id          = var.project_id
  vpn_gwy_region      = var.vpn_gwy_region
  shared_secret       = var.shared_secret
  aws_private_subnets = module.network.aws_private_subnets
  aws_vpc_id          = module.network.aws_vpc_id
  gcp_network         = module.network.gcp_network
}

module "vm" {
  source = "../modules/vm"

  vm_name                = var.vm_name
  machine_type           = var.vm_machine_type
  zone                   = var.vm_zone
  image                  = var.vm_image
  network                = module.network.gcp_network
  subnetwork             = module.network.gcp_subnets[0]
  aws_vpc_cidr           = var.aws_vpc_cidr
  environment            = var.environment
  ssh_keys               = var.ssh_public_keys
  ssh_private_key        = local.ssh_private_key
  create_service_account = false

  depends_on = [module.network]
}

module "ec2" {
  source = "../modules/ec2"

  instance_name    = var.ec2_instance_name
  instance_type    = var.ec2_instance_type
  vpc_id           = module.network.aws_vpc_id
  subnet_id        = module.network.aws_private_subnets[0]
  gcp_vpc_cidr     = var.gcp_vpc_cidr
  aws_vpc_cidr     = var.aws_vpc_cidr
  enable_public_ip = var.ec2_enable_public_ip
  key_name         = var.ec2_key_name
  environment      = var.environment
  ssh_public_keys  = [for key in var.ssh_public_keys : replace(key, "/^[^:]+:/", "")]
  ssh_private_key  = local.ssh_private_key
  
  # EC2 Instance Connect Endpoint
  aws_create_vpc_endpoints = var.aws_create_vpc_endpoints

  depends_on = [module.network]
}
