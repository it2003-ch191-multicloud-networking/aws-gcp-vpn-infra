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

########################################################################
################ GCP Network ###########################################
########################################################################

resource "google_compute_network" "net" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "subnet" {
  count = length(var.subnet_regions)

  ip_cidr_range            = cidrsubnets("10.10.0.0/16", 2, 2)[count.index]
  name                     = "snet-${count.index}"
  network                  = google_compute_network.net.name
  region                   = var.subnet_regions[count.index]
  private_ip_google_access = true
}

########################################################################
################ AWS Network ###########################################
########################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # add version constraint
  version = "~> 5.21.0"

  name = "aws-net"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
}

