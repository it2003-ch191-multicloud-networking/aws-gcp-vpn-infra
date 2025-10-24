# GCP VM Module

This Terraform module creates a GCP VM instance configured to connect through the VPN tunnel to AWS.

## Features

- Creates a GCP VM instance with Ubuntu 24.04 LTS
- Configured with e2-small machine type
- SSH access enabled via IAP (Identity-Aware Proxy)
- No external IP - secure access only through IAP
- Firewall rules configured for:
  - IAP SSH access
  - AWS VPC traffic through VPN tunnel
  - Internal GCP VPC traffic
- Service account with cloud-platform scope
- OS Login enabled for secure access
- Startup script with useful networking tools

## Usage

```hcl
module "vm" {
  source = "../modules/vm"
  
  vm_name      = "gcp-vm"
  machine_type = "e2-small"
  zone         = "asia-northeast1-a"
  image        = "ubuntu-os-cloud/ubuntu-2404-noble-amd64-v20251014"
  network      = "gcp-net"
  subnetwork   = "projects/PROJECT_ID/regions/REGION/subnetworks/SUBNET_NAME"
  aws_vpc_cidr = "10.0.0.0/16"
}
```

## SSH Access via IAP

To connect to the VM instance:

```bash
gcloud compute ssh gcp-vm --zone=asia-northeast1-a --tunnel-through-iap
```

## Testing VPN Connectivity

Once connected to the VM, you can test connectivity to AWS resources:

```bash
# Ping AWS private IP
ping 10.0.1.10

# Test connection to AWS service
curl http://10.0.1.10:8080
```

## Variables

See `variables.tf` for all available configuration options.

## Outputs

- `instance_id` - The instance ID
- `instance_name` - The instance name
- `internal_ip` - The internal IP address
- `iap_ssh_command` - Command to SSH via IAP
