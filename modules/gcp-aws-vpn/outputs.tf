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
