#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
  echo ""
  echo -e "${CYAN}===================================================================${NC}"
  echo -e "${CYAN}  $1${NC}"
  echo -e "${CYAN}===================================================================${NC}"
  echo ""
}

print_step() {
  echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ $1${NC}"
}

# Function to pause for demo
pause_demo() {
  if [ "${DEMO_AUTO:-false}" != "true" ]; then
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
  else
    sleep 2
  fi
}

# Change to project root
cd "$(dirname "$0")/.."

print_header "Multi-Cloud VPN Lab Demonstration"
echo "This demo will show you:"
echo "  1. Architecture overview"
echo "  2. Infrastructure status"
echo "  3. VPN tunnel status"
echo "  4. BGP routing"
echo "  5. Route configuration"
echo ""
print_info "Set DEMO_AUTO=true to run without pausing"
pause_demo

# Step 1: Architecture Overview
print_header "Step 1: Architecture Overview"
print_step "Displaying network architecture..."
echo ""
cat << 'EOF'
┌─────────────────────────────────────────┐     ┌─────────────────────────────────────────┐
│  GCP (asia-northeast1)                  │     │  AWS (ap-southeast-1)                   │
│  ┌───────────────────────────────────┐  │     │  ┌───────────────────────────────────┐  │
│  │ VPC: 10.10.0.0/16                 │  │     │  │ VPC: 10.0.0.0/16                  │  │
│  │  ┌─────────────────────────────┐  │  │     │  │  ┌─────────────────────────────┐  │  │
│  │  │          GCP VM             │  │  │     │  │  │          AWS EC2            │  │  │
│  │  │ e2-small, Ubuntu 24.04      │  │  │     │  │  │ t3.micro, Ubuntu 24.04      │  │  │
│  │  └─────────────────────────────┘  │  │     │  │  └─────────────────────────────┘  │  │
│  └───────────────┬───────────────────┘  │     │  └───────────────┬───────────────────┘  │
│                  │                      │     │                  │                      │
│  ┌───────────────▼───────────────────┐  │     │  ┌───────────────▼───────────────────┐  │
│  │ HA VPN Gateway (2 interfaces)     │  │     │  │ Transit Gateway + VPN             │  │
│  │ Cloud Router (BGP ASN: 64514)  m  │  │     │  │ (BGP ASN: 64515)                  │  │
│  └───────────────┬───────────────────┘  │     │  └───────────────┬───────────────────┘  │
└──────────────────┼────────────────── ───┘     └──────────────────┼──────────────────────┘
                   │                                               │
                   └────────────►   4 IPsec Tunnels  ◄─────────────┘
                                  BGP Dynamic Routing
EOF
echo ""
print_success "Architecture displayed"
pause_demo

# Step 2: Infrastructure Status
print_header "Step 2: Infrastructure Status"
print_step "Checking deployed resources..."
echo ""

cd provision

print_info "GCP Resources:"
terraform output vm_instance_name 2>/dev/null | sed 's/^/  VM Name: /'
terraform output vm_internal_ip 2>/dev/null | sed 's/^/  VM IP: /'
terraform output vm_zone 2>/dev/null | sed 's/^/  Zone: /'
echo ""

print_info "AWS Resources:"
terraform output ec2_instance_name 2>/dev/null | sed 's/^/  EC2 Name: /'
terraform output ec2_private_ip 2>/dev/null | sed 's/^/  Private IP: /'
terraform output ec2_public_ip 2>/dev/null | sed 's/^/  Public IP: /'
echo ""

print_info "VPN Resources:"
terraform output gcp_vpn_gateway_id 2>/dev/null | sed 's/^/  GCP VPN Gateway: /'
terraform output transit_gateway_id 2>/dev/null | sed 's/^/  AWS Transit Gateway: /'
terraform output gcp_router_name 2>/dev/null | sed 's/^/  GCP Router: /'

cd ..

print_success "Infrastructure status retrieved"
pause_demo

# Step 3: VPN Tunnel Status
print_header "Step 3: VPN Tunnel Status"
print_step "Checking VPN tunnels..."
echo ""

print_info "GCP HA VPN Tunnels (4 tunnels expected):"
gcloud compute vpn-tunnels list --project=multicloud-475408 \
  --format="table(name,status,detailedStatus)" \
  --filter="region:asia-northeast1" 2>/dev/null || print_error "Failed to get GCP tunnel status"
echo ""

print_info "AWS VPN Connections:"
export AWS_PROFILE=truong-bot
aws ec2 describe-vpn-connections --region=ap-southeast-1 \
  --query 'VpnConnections[*].{ID:VpnConnectionId,State:State,Tunnel1_IP:VgwTelemetry[0].OutsideIpAddress,Tunnel1_Status:VgwTelemetry[0].Status,Tunnel2_IP:VgwTelemetry[1].OutsideIpAddress,Tunnel2_Status:VgwTelemetry[1].Status}' \
  --output table 2>/dev/null || print_error "Failed to get AWS VPN status"

print_success "VPN tunnel status checked"
pause_demo

# Step 4: BGP Routing Status
print_header "Step 4: BGP Routing Status"
print_step "Checking BGP peer status..."
echo ""

print_info "GCP Cloud Router BGP Status (4 peers expected):"
gcloud compute routers get-status vpn-router \
  --region=asia-northeast1 \
  --project=multicloud-475408 \
  --format="table(result.bgpPeerStatus[].name,result.bgpPeerStatus[].ipAddress,result.bgpPeerStatus[].peerIpAddress,result.bgpPeerStatus[].status,result.bgpPeerStatus[].state,result.bgpPeerStatus[].numLearnedRoutes)" 2>/dev/null | grep -v "^$" || print_error "Failed to get BGP status"

print_success "BGP status checked - All peers should be UP"
pause_demo

# Step 5: Route Configuration
print_header "Step 5: Route Configuration"
print_step "Checking route tables..."
echo ""

print_info "GCP Routes to AWS (10.0.0.0/16):"
gcloud compute routes list --project=multicloud-475408 \
  --filter="network:gcp-net AND destRange:10.0.0.0/16" \
  --format="table(name,destRange,nextHopVpnTunnel,priority)" 2>/dev/null || print_error "Failed to get GCP routes"
echo ""

print_info "AWS Routes to GCP (10.10.0.0/16):"
VPC_ID=$(cd provision && terraform output -raw aws_vpc_id 2>/dev/null)
if [ -n "$VPC_ID" ]; then
  aws ec2 describe-route-tables --region=ap-southeast-1 \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=route.destination-cidr-block,Values=10.10.0.0/16" \
    --query 'RouteTables[*].{RouteTableId:RouteTableId,Destination:Routes[?DestinationCidrBlock==`10.10.0.0/16`].DestinationCidrBlock|[0],TransitGateway:Routes[?DestinationCidrBlock==`10.10.0.0/16`].TransitGatewayId|[0]}' \
    --output table 2>/dev/null || print_error "Failed to get AWS routes"
else
  print_error "Could not get VPC ID"
fi

print_success "Route configuration verified"

echo ""
print_header "Demo Completed"