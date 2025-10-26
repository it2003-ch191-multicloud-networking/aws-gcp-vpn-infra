# Multi-Cloud VPN Infrastructure - AI Agent Guide

## Project Overview

This is a **production-ready Terraform project** that establishes a high-availability VPN connection between Google Cloud Platform (GCP) and Amazon Web Services (AWS) using HA VPN Gateway and Transit Gateway with BGP routing.

**Architecture**: GCP (Tokyo) ↔ 4 IPsec Tunnels + BGP ↔ AWS (Singapore)
- GCP: 10.10.0.0/16 (ASN 64514) - HA VPN Gateway, Cloud Router, Compute Engine VM
- AWS: 10.0.0.0/16 (ASN 64515) - Transit Gateway, VPN Connections, EC2 Instance
- VPN: 4 redundant tunnels with dynamic BGP routing for high availability

## Working Directory

**Always work from `provision/` for Terraform operations:**
```bash
cd provision
terraform init
terraform plan
terraform apply
```

## Critical Architecture Decisions

### 1. Dual Provider Authentication Pattern
```terraform
# provision/provider.tf - Service account impersonation for GCP
provider "google" {
  alias = "impersonation"  # Used to get token
}

data "google_service_account_access_token" "default" {
  provider = google.impersonation
  target_service_account = var.impersonate_service_account  # Required
}

provider "google" {
  access_token = data.google_service_account_access_token.default.access_token
}
```
- **Always configure** `impersonate_service_account` in `terraform.tfvars`
- AWS uses standard AWS CLI credentials (AWS_PROFILE or ~/.aws/credentials)

### 2. SSH Key Dual Format Handling
```hcl
# terraform.tfvars - GCP requires "username:" prefix
ssh_public_keys = [
  "truongtbn:ssh-ed25519 AAAA... user@host",
  "ubuntu:ssh-ed25519 BBBB... shared@key"
]

# provision/main.tf - Strip prefix for AWS
ssh_public_keys = [for key in var.ssh_public_keys : replace(key, "/^[^:]+:/", "")]
```
- **GCP format**: `username:ssh-ed25519 ...`
- **AWS format**: `ssh-ed25519 ...` (username prefix auto-stripped)
- Private key at `../ssh-key/id_ed25519` is embedded in VMs for cross-cloud SSH

### 3. VPN Tunnel Count Validation
```terraform
# Must be multiples of 2, minimum 4 for HA
validation {
  condition = var.num_tunnels % 2 == 0 && var.num_tunnels >= 4
}
```
- **4 tunnels** = 2 GCP HA VPN interfaces × 2 AWS customer gateways
- Each tunnel has BGP session (see `modules/gcp-aws-ha-vpn/gcp.tf` locals)

### 4. Module Dependency Chain
```
network → gcp-aws-ha-vpn → vm/ec2 (parallel)
        ↘ (Cloud NAT created with network)
```
- **Network module** creates both GCP VPC + AWS VPC in single module
- **VPN module** requires network outputs (gcp_network, aws_vpc_id, aws_private_subnets)
- **VM/EC2 modules** depend on network but NOT on VPN (VPN routes auto-propagate via BGP)

## Key Configuration Files

### `provision/terraform.tfvars` - The Single Source of Truth
**Required variables:**
- `project_id`, `impersonate_service_account` (GCP auth)
- `shared_secret` (generate with `openssl rand -base64 32`)
- `gcp_router_asn = "64514"`, `aws_router_asn = "64515"` (do NOT change)
- `ssh_public_keys` (with username prefix for GCP)

**Optional but recommended:**
- `aws_create_vpc_endpoints = true` (enable EC2 Instance Connect Endpoint for private SSH)
- `enable_cloud_nat = true` (GCP VMs internet access without public IP)
- `ec2_enable_public_ip = false` (access via VPN only, more secure)

### Module-Specific Patterns

**modules/gcp-aws-ha-vpn/** - Complex BGP tunnel logic:
```terraform
# gcp.tf - Auto-calculates interface distribution
locals {
  four_interface_ext_gwys = [for i in range(floor(var.num_tunnels / 4)) : ...]
  tunnels = chunklist(flatten([...]), var.num_tunnels)[0]
  bgp_sessions = {for k, v in aws_vpn_connection.vpn_conn : ...}
}
```
- Don't manually edit tunnel distribution logic
- BGP peer IPs auto-extracted from AWS VPN connections

**modules/ec2/vpc_endpoint.tf** - Modern AWS SSH:
```terraform
resource "aws_ec2_instance_connect_endpoint" "eic" {
  count = var.aws_create_vpc_endpoints ? 1 : 0
  # Creates private IP SSH access (no bastion needed)
}
```
- Requires AWS CLI 2.12.0+
- Connect via: `aws ec2-instance-connect ssh --instance-id <id> --connection-type eice`

**modules/vm|ec2/*.tf** - User data templating:
- `init.sh.tpl` files use HCL interpolation: `${var_name}`
- Private keys embedded via `${private_key}` variable (from `fileexists()` in main.tf)
- Both VMs install same private key for bidirectional SSH over VPN

## Testing & Debugging Workflows

### Verify VPN Status (BGP is key!)
```bash
# GCP BGP peers - must show "UP" + learned routes
gcloud compute routers get-status vpn-router \
  --region=asia-northeast1 \
  --format="table(result.bgpPeerStatus[].status,result.bgpPeerStatus[].numLearnedRoutes)"

# AWS VPN tunnels - check Tunnel1/Tunnel2 status
aws ec2 describe-vpn-connections --region=ap-southeast-1 \
  --query 'VpnConnections[*].{State:State,T1:VgwTelemetry[0].Status,T2:VgwTelemetry[1].Status}'
```

### Test Connectivity Scripts (from project root)
```bash
./scripts/test-connectivity.sh  # Full VPN health check
./scripts/gcp2aws.sh           # SSH from GCP → AWS via VPN
./scripts/aws2gcp.sh           # SSH from AWS → GCP via VPN
```

### Common Issues

**VPN tunnels DOWN:**
- Check `shared_secret` matches on both sides
- Verify BGP ASNs are correct (64514 GCP, 64515 AWS)
- Firewall rules must allow from remote CIDR (10.0.0.0/16 ↔ 10.10.0.0/16)

**Cannot SSH between VMs over VPN:**
- Verify private key exists: `cat ../ssh-key/id_ed25519`
- Check VPN tunnels are UP first
- Ping remote IP to verify routing: `ping 10.0.1.x` or `ping 10.10.0.x`

**"No suitable authentication method" errors:**
- Ensure SSH keys use ed25519 format: `ssh-keygen -t ed25519 -f ../ssh-key/id_ed25519`
- Verify `ssh_public_keys` has username prefix for GCP

## File Editing Conventions

### When modifying Terraform:
1. **Always validate module dependencies** - check `depends_on` before removing resources
2. **Test with `terraform plan` before apply** - especially for VPN module changes
3. **Use targeted operations for VMs**: `terraform destroy -target=module.vm` or `terraform destroy -target=module.ec2` (VPN persists)
4. **Never commit** `terraform.tfvars`, `terraform.tfstate`, `../ssh-key/*` (gitignored)

### When updating documentation:
- `ARCHITECTURE.md` - high-level design, cost estimates, security patterns
- `GUIDE.md` - step-by-step operations, troubleshooting commands
- `README.md` - quick start only

## Cost Awareness

**High-cost resources** (always clean up when done):
- GCP HA VPN Gateway: ~$35/month per tunnel pair
- GCP Cloud NAT: ~$45/month + data processing
- AWS Transit Gateway: ~$50/month + attachments
- **Total idle cost: ~$180-225/month**

**Cleanup command**: `cd provision && terraform destroy` (destroys everything)

## Security Constraints

1. **Firewall rules are CIDR-specific** - editing VPC CIDRs requires firewall rule updates
2. **IAP for GCP SSH** - only works from whitelisted IP range (35.235.240.0/20)
3. **EIC Endpoint for AWS** - requires IAM permissions, no public IP needed
4. **Shared secrets in tfvars** - rotate via `terraform apply` after changing shared_secret

## Quick Reference Commands

```bash
# Get connection IPs (from provision/)
terraform output vm_internal_ip    # 10.10.0.x
terraform output ec2_private_ip    # 10.0.1.x

# SSH to instances
gcloud compute ssh gcp-vm --zone=asia-northeast1-a --tunnel-through-iap
aws ec2-instance-connect ssh --instance-id $(terraform output -raw instance_id) --connection-type eice

# Force VPN recreation (if tunnels stuck)
terraform destroy -target=module.gcp-aws-ha-vpn
terraform apply
```

## References to Original Docs
- Full architecture diagrams: `ARCHITECTURE.md` (mermaid diagrams, tables)
- Detailed setup guide: `GUIDE.md` (prerequisites, troubleshooting)
- Network module internals: `modules/network/README.md`
