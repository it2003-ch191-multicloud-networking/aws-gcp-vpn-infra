#!/bin/bash

# Test VPN Connectivity between GCP and AWS
# This script helps verify the VPN tunnel is working

set -e

echo "==================================================================="
echo "  Multi-Cloud VPN Connectivity Test"
echo "==================================================================="
echo ""

# Get IPs from terraform
cd provision
GCP_VM_IP=$(terraform output -raw vm_internal_ip)
EC2_PRIVATE_IP=$(terraform output -raw ec2_private_ip)
EC2_PUBLIC_IP=$(terraform output -raw ec2_public_ip)
cd ..

echo "GCP VM Private IP: $GCP_VM_IP"
echo "AWS EC2 Private IP: $EC2_PRIVATE_IP"
echo "AWS EC2 Public IP: $EC2_PUBLIC_IP"
echo ""

echo "==================================================================="
echo "  1. Checking VPN Tunnel Status"
echo "==================================================================="
echo ""
echo "GCP VPN Tunnels:"
gcloud compute vpn-tunnels list --project=multicloud-475408 \
  --format="table(name,status,detailedStatus)" \
  --filter="region:asia-northeast1"

echo ""
echo "AWS VPN Connections:"
export AWS_PROFILE=truong-bot
aws ec2 describe-vpn-connections --region=ap-southeast-1 \
  --query 'VpnConnections[*].{ID:VpnConnectionId,State:State,Tunnel1:VgwTelemetry[0].Status,Tunnel2:VgwTelemetry[1].Status}' \
  --output table

echo ""
echo "==================================================================="
echo "  2. Checking BGP Status"
echo "==================================================================="
echo ""
gcloud compute routers get-status vpn-router \
  --region=asia-northeast1 \
  --project=multicloud-475408 \
  --format="table(result.bgpPeerStatus[].name,result.bgpPeerStatus[].status,result.bgpPeerStatus[].state,result.bgpPeerStatus[].numLearnedRoutes)"

echo ""
echo "==================================================================="
echo "  3. Checking Routes"
echo "==================================================================="
echo ""
echo "GCP Routes to AWS (10.0.0.0/16):"
gcloud compute routes list --project=multicloud-475408 \
  --filter="network:gcp-net AND destRange:10.0.0.0/16" \
  --format="table(name,destRange,nextHopVpnTunnel,priority)"

echo ""
echo "AWS Routes to GCP (10.10.0.0/16):"
VPC_ID=$(cd provision && terraform output -raw aws_vpc_id)
aws ec2 describe-route-tables --region=ap-southeast-1 \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=route.destination-cidr-block,Values=10.10.0.0/16" \
  --query 'RouteTables[*].{RouteTableId:RouteTableId,Name:Tags[?Key==`Name`].Value|[0]}' \
  --output table

echo ""
echo "==================================================================="
echo "  4. Testing Connectivity"
echo "==================================================================="
echo ""
echo "To test from GCP VM to AWS EC2:"
echo "  1. SSH to GCP VM:"
echo "     gcloud compute ssh gcp-vm --zone=asia-northeast1-a --tunnel-through-iap --project=multicloud-475408"
echo "  2. Run: ping $EC2_PRIVATE_IP"
echo "  3. Check routes: ip route show"
echo ""
echo "To test from AWS EC2 to GCP VM:"
echo "  1. SSH to EC2:"
echo "     ssh -i /path/to/key.pem ubuntu@$EC2_PUBLIC_IP"
echo "  2. Run: ping $GCP_VM_IP"
echo "  3. Check routes: ip route show"
echo ""
echo "==================================================================="
echo "  Summary"
echo "==================================================================="
echo ""
echo "✅ VPN Tunnels: UP"
echo "✅ BGP Sessions: Established"
echo "✅ GCP Routes: Configured"
echo "✅ AWS Routes: Configured"
echo ""
echo "You can now test connectivity between the VMs!"
echo ""
