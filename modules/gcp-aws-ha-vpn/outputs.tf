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

output "gcp_vpn_gateway_id" {
  description = "GCP HA VPN Gateway ID"
  value       = google_compute_ha_vpn_gateway.gwy.id
}

output "gcp_router_name" {
  description = "GCP Cloud Router name"
  value       = google_compute_router.router.name
}

output "aws_transit_gateway_id" {
  description = "AWS Transit Gateway ID"
  value       = aws_ec2_transit_gateway.tgw.id
}

output "vpn_tunnel_ids" {
  description = "GCP VPN tunnel IDs"
  value       = [for tunnel in google_compute_vpn_tunnel.tunnel : tunnel.id]
}

output "aws_vpn_connection_ids" {
  description = "AWS VPN connection IDs"
  value       = [for conn in aws_vpn_connection.vpn_conn : conn.id]
}

output "gcp_route_to_aws" {
  description = "GCP route to AWS CIDR"
  value       = google_compute_route.to_aws.id
}
