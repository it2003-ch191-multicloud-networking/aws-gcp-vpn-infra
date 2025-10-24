# Setup Guide

Complete guide for deploying and managing the GCP-AWS VPN infrastructure.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [Testing](#testing)
6. [Management](#management)
7. [Troubleshooting](#troubleshooting)
8. [Cleanup](#cleanup)

---

## Prerequisites

### Required Tools

Install the following tools before proceeding:

1. **Terraform CLI** (version 1.0 or later)
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **Google Cloud SDK** (`gcloud`)
   ```bash
   # macOS
   brew install --cask google-cloud-sdk
   
   # Linux
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   ```

3. **AWS CLI** (version 2+)
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

### Verify Installation

```bash
terraform --version  # Should be >= 1.0.0
gcloud --version     # Should show gcloud SDK
aws --version        # Should be >= 2.0.0
```

---

## Initial Setup

### 1. Configure GCP Credentials

#### Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable iamcredentials.googleapis.com
```

#### Authenticate with Service Account

```bash
# Authenticate with service account impersonation
gcloud auth application-default login \
  --impersonate-service-account=github-actions-terraform@multicloud-475408.iam.gserviceaccount.com
```

**Required Permissions:**
- Your user account needs `roles/iam.serviceAccountTokenCreator` role
- Service account needs: `Compute Admin`, `Compute Network Admin`, `Service Account User`

#### Alternative: Direct Authentication

```bash
# If not using service account impersonation
gcloud auth application-default login
```

### 2. Configure AWS Credentials

#### Using AWS Configure

```bash
aws configure
```

You'll be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `ap-southeast-1`
- Default output format: `json`

#### Using Environment Variables

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

#### Using AWS Profiles

```bash
# Configure named profile
aws configure --profile your-profile-name

# Use profile
export AWS_PROFILE=your-profile-name
```

**Required Permissions:**
- `ec2:*` (VPC, Subnet, Security Group, EC2)
- `ec2:CreateVpnConnection`, `ec2:CreateTransitGateway`
- `ec2:CreateRoute`, `ec2:ModifyVpcAttribute`

---

## Configuration

### 1. Navigate to Provision Directory

```bash
cd provision
```

### 2. Edit `terraform.tfvars`

Create or edit the `terraform.tfvars` file with your configuration:

```hcl
# GCP Configuration
project_id                  = "your-gcp-project-id"
impersonate_service_account = "your-service-account@project.iam.gserviceaccount.com"
network_name                = "gcp-net"
subnet_regions              = ["asia-northeast1", "asia-northeast1"]
vpn_gwy_region              = "asia-northeast1"
gcp_router_asn              = "64514"

# AWS Configuration
aws_vpc_cidr                = "10.0.0.0/16"
aws_router_asn              = "64515"

# VPN Configuration
num_tunnels                 = 4
shared_secret               = "your-very-secure-random-string-here"

# VM Configuration
vm_name                     = "test-gcp-vm"
vm_machine_type             = "e2-small"
vm_zone                     = "asia-northeast1-a"
vm_image                    = "ubuntu-2404-noble-amd64-v20251014"

# EC2 Configuration
ec2_instance_name           = "bastion-vm"
ec2_instance_type           = "t3.micro"
ec2_enable_public_ip        = true

# SSH Keys
ssh_public_keys = [
  "username:ssh-ed25519 AAAAC3... your-email@domain.com"
]
```

### 3. Generate Secure Shared Secret

```bash
# Generate random 32-character string
openssl rand -base64 32

# Or use a password generator
# Use this value for 'shared_secret' in terraform.tfvars
```

### 4. Add SSH Keys

Generate SSH key if you don't have one:

```bash
# Generate ed25519 key (recommended)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "your-email@domain.com"

# Get public key
cat ~/.ssh/id_ed25519.pub
```

Add to `terraform.tfvars`:
```hcl
ssh_public_keys = [
  "username:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-email@domain.com"
]
```

**Note**: GCP format requires `username:` prefix, but it's handled automatically by the module.

---

## Deployment

### 1. Initialize Terraform

```bash
terraform init
```

This will:
- Download required provider plugins (Google, AWS)
- Initialize backend configuration
- Download module dependencies

### 2. Validate Configuration

```bash
terraform validate
```

Should return: `Success! The configuration is valid.`

### 3. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

Review the plan carefully. You should see:
- **GCP Resources**: VPC, subnets, HA VPN gateway, Cloud Router, VM, firewall rules, routes
- **AWS Resources**: VPC, subnets, Transit Gateway, VPN connections, EC2, security groups, routes
- **Total Resources**: ~40-50 resources

### 4. Apply Configuration

```bash
terraform apply tfplan
```

**Deployment Time**: Approximately 5-10 minutes

The VPN tunnels may take a few minutes to establish after initial creation.

### 5. Save Outputs

```bash
terraform output > ../outputs.txt
```

---

## Testing

### Automated Tests

Run from the project root directory:

```bash
# Full connectivity test suite
./scripts/test-connectivity.sh

# Test GCP → AWS connectivity
./scripts/gcp2aws.sh

# Test AWS → GCP connectivity
./scripts/aws2gcp.sh

# Interactive demo (step-by-step)
./scripts/demo.sh
```

### Manual Testing

#### 1. Verify VPN Tunnels

**GCP:**
```bash
gcloud compute vpn-tunnels list --project=your-project-id
```

Expected: 4 tunnels with `ESTABLISHED` status

**AWS:**
```bash
aws ec2 describe-vpn-connections \
  --region=ap-southeast-1 \
  --query 'VpnConnections[*].{ID:VpnConnectionId,State:State,T1:VgwTelemetry[0].Status,T2:VgwTelemetry[1].Status}'
```

Expected: All tunnels with `UP` status

#### 2. Verify BGP Status

```bash
gcloud compute routers get-status vpn-router \
  --region=asia-northeast1 \
  --project=your-project-id \
  --format="table(result.bgpPeerStatus[].name,result.bgpPeerStatus[].status,result.bgpPeerStatus[].numLearnedRoutes)"
```

Expected: 4 peers with `UP` status, each learning routes

#### 3. Verify Routes

**GCP Routes:**
```bash
gcloud compute routes list \
  --project=your-project-id \
  --filter="destRange:10.0.0.0/16"
```

Expected: Route to AWS CIDR via VPN tunnel

**AWS Routes:**
```bash
aws ec2 describe-route-tables \
  --region=ap-southeast-1 \
  --filters "Name=route.destination-cidr-block,Values=10.10.0.0/16" \
  --query 'RouteTables[*].RouteTableId'
```

Expected: Multiple route tables with routes to GCP CIDR

#### 4. Test Connectivity

**From GCP to AWS:**
```bash
# SSH into GCP VM
gcloud compute ssh test-gcp-vm \
  --zone=asia-northeast1-a \
  --tunnel-through-iap \
  --project=your-project-id

# Ping AWS EC2
ping 10.0.1.226

# Check routes
ip route show
```

**From AWS to GCP:**
```bash
# SSH into AWS EC2 (replace with your public IP)
ssh -i ~/.ssh/id_ed25519 ubuntu@<EC2_PUBLIC_IP>

# Ping GCP VM
ping 10.10.0.2

# Check routes
ip route show
```

---

## Management

### View Terraform State

```bash
terraform show
```

### View Specific Outputs

```bash
terraform output vm_internal_ip
terraform output ec2_public_ip
terraform output connection_info
```

### Update Infrastructure

```bash
# Make changes to terraform.tfvars or *.tf files
terraform plan -out=tfplan
terraform apply tfplan
```

### Create VM and EC2

The VM and EC2 instances are created automatically when you run `terraform apply`. However, if you need to recreate them or manage them separately:

### Recreate Both Instances

```bash
# Destroy both instances
terraform destroy -target=module.vm -target=module.ec2

# Recreate them
terraform apply -target=module.vm -target=module.ec2
```

### Force Recreation (without destroying first)

```bash
# Taint and recreate GCP VM
terraform taint module.vm.google_compute_instance.vm
terraform apply

# Taint and recreate AWS EC2
terraform taint module.ec2.aws_instance.ec2
terraform apply

# Taint both
terraform taint module.vm.google_compute_instance.vm
terraform taint module.ec2.aws_instance.ec2
terraform apply
```

### Add New SSH Keys

Edit `terraform.tfvars`:
```hcl
ssh_public_keys = [
  "user1:ssh-ed25519 AAAA... user1@domain.com",
  "user2:ssh-ed25519 BBBB... user2@domain.com"
]
```

Then apply:
```bash
terraform apply
```

### Restart VMs

**GCP VM:**
```bash
gcloud compute instances stop test-gcp-vm --zone=asia-northeast1-a
gcloud compute instances start test-gcp-vm --zone=asia-northeast1-a
```

**AWS EC2:**
```bash
aws ec2 stop-instances --instance-ids <instance-id>
aws ec2 start-instances --instance-ids <instance-id>
```

---

## Troubleshooting

### VPN Tunnels Not Establishing

**Check tunnel status:**
```bash
# GCP
gcloud compute vpn-tunnels describe vpn-tunnel-0 \
  --region=asia-northeast1 \
  --project=your-project-id

# AWS
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <vpn-connection-id> \
  --region=ap-southeast-1
```

**Common Issues:**
- ❌ **Shared secrets don't match**: Verify `shared_secret` in terraform.tfvars
- ❌ **Firewall blocking**: Check GCP firewall rules and AWS security groups
- ❌ **Wrong ASN configuration**: Verify `gcp_router_asn` and `aws_router_asn`

**Solution:**
```bash
terraform destroy -target=module.gcp-aws-ha-vpn
terraform apply
```

### BGP Sessions Not UP

**Check BGP status:**
```bash
gcloud compute routers get-status vpn-router \
  --region=asia-northeast1 \
  --project=your-project-id
```

**Common Issues:**
- ❌ **Tunnels down**: Fix tunnel establishment first
- ❌ **Wrong ASN**: Must be 64514 (GCP) and 64515 (AWS)
- ❌ **BGP configuration mismatch**: Check router configuration

### Ping Fails Between VMs

**Verify routes exist:**
```bash
# GCP routes to AWS
gcloud compute routes list --filter="destRange:10.0.0.0/16"

# AWS routes to GCP
aws ec2 describe-route-tables \
  --filters "Name=route.destination-cidr-block,Values=10.10.0.0/16"
```

**If routes are missing:**
```bash
# Re-apply routing module
terraform destroy -target=module.gcp-aws-ha-vpn.google_compute_route.to_aws
terraform destroy -target=module.gcp-aws-ha-vpn.aws_route.to_gcp
terraform apply
```

**Check firewall rules:**
```bash
# GCP - should allow from 10.0.0.0/16
gcloud compute firewall-rules describe allow-from-aws

# AWS - should allow from 10.10.0.0/16
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Cannot SSH to GCP VM

**Test IAP connectivity:**
```bash
gcloud compute ssh test-gcp-vm \
  --zone=asia-northeast1-a \
  --tunnel-through-iap \
  --dry-run
```

**Check firewall rule:**
```bash
gcloud compute firewall-rules describe allow-iap-ssh
```

**If missing, recreate:**
```bash
terraform destroy -target=module.vm.google_compute_firewall.allow_iap
terraform apply
```

### Cannot SSH to AWS EC2

**Check security group allows SSH:**
```bash
aws ec2 describe-security-groups \
  --group-ids <sg-id> \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]'
```

**Verify public IP exists:**
```bash
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].PublicIpAddress'
```

**Check SSH key:**
```bash
# Verify key file permissions
chmod 400 ~/.ssh/id_ed25519

# Test connection
ssh -v -i ~/.ssh/id_ed25519 ubuntu@<public-ip>
```

### Terraform State Issues

**State lock error:**
```bash
# Force unlock (use carefully)
terraform force-unlock <lock-id>
```

**Corrupted state:**
```bash
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Pull fresh state from backend
terraform state pull > terraform.tfstate
```

### High Costs

**Check running resources:**
```bash
# GCP
gcloud compute instances list
gcloud compute vpn-gateways list

# AWS
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
aws ec2 describe-transit-gateways
```

**Cost optimization:**
- Stop VMs when not in use
- Use smaller instance types (f1-micro for GCP, t2.micro for AWS free tier)
- Delete VPN gateway when testing is complete

---

## Cleanup

### Destroy All Resources

```bash
cd provision

# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**Warning**: This will permanently delete all resources. Make sure you have backups if needed.

### Selective Destruction

**Destroy only VMs:**
```bash
terraform destroy -target=module.vm -target=module.ec2
```

**Destroy only VPN:**
```bash
terraform destroy -target=module.gcp-aws-ha-vpn
```

### Verify Cleanup

**GCP:**
```bash
gcloud compute instances list
gcloud compute vpn-gateways list
gcloud compute routers list
```

**AWS:**
```bash
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
aws ec2 describe-transit-gateways
aws ec2 describe-vpn-connections
```

### Remove Terraform State

```bash
# Remove local state files
rm -rf .terraform
rm terraform.tfstate*
rm tfplan
```

---

## Additional Resources

### Documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architecture diagrams
- [NETWORK.md](NETWORK.md) - Network design and IP allocation
- [VM_SETUP.md](VM_SETUP.md) - VM configuration details

### Official Documentation
- [GCP HA VPN Guide](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview)
- [AWS Transit Gateway Guide](https://docs.aws.amazon.com/vpc/latest/tgw/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Scripts
- `scripts/demo.sh` - Interactive demonstration
- `scripts/test-connectivity.sh` - VPN status checker
- `scripts/gcp2aws.sh` - GCP → AWS connectivity test
- `scripts/aws2gcp.sh` - AWS → GCP connectivity test

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) for design details
3. Open an issue on the GitHub repository
4. Check cloud provider documentation for specific services