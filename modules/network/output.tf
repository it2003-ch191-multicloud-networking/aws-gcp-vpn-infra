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

output "aws_private_subnets" {
  value = module.vpc.private_subnets
}

output "aws_vpc_id" {
  value = module.vpc.vpc_id
}

output "aws_private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "gcp_network" {
  value = google_compute_network.net.name
}

output "gcp_network_id" {
  value = google_compute_network.net.id
}

output "gcp_subnets" {
  value = google_compute_subnetwork.subnet[*].self_link
}

output "gcp_subnet_names" {
  value = google_compute_subnetwork.subnet[*].name
}

output "gcp_subnet_regions" {
  value = google_compute_subnetwork.subnet[*].region
}

# Cloud NAT Outputs
output "cloud_nat_enabled" {
  description = "Whether Cloud NAT is enabled"
  value       = var.enable_cloud_nat
}

output "cloud_nat_router_name" {
  description = "Name of the Cloud NAT router"
  value       = var.enable_cloud_nat ? google_compute_router.nat_router[0].name : null
}

output "cloud_nat_gateway_name" {
  description = "Name of the Cloud NAT gateway"
  value       = var.enable_cloud_nat ? google_compute_router_nat.nat_gateway[0].name : null
}