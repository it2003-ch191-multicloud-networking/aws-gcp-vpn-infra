# Multi-Cloud VPN Setup: GCP ↔ AWS

This setup creates VM instances in both GCP and AWS clouds connected via VPN tunnels for secure cross-cloud communication.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                    GCP (asia-northeast1)                         │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ gcp-vm                                                  │   │
│   │ • e2-small (2 vCPU, 2GB RAM)                           │   │
│   │ • Ubuntu 24.04 LTS                                     │   │
│   │ • Private IP: 10.10.0.x                                │   │
│   │ • SSH via IAP (no public IP)                           │   │
│   └──────────────────┬──────────────────────────────────────┘   │
│                      │                                           │
│   ┌──────────────────▼──────────────────────────────────────┐   │
│   │ VPC: gcp-net (10.10.0.0/16)                            │   │
│   │ Subnet: 10.10.0.0/18                                   │   │
│   └──────────────────┬──────────────────────────────────────┘   │
│                      │                                           │
│   ┌──────────────────▼──────────────────────────────────────┐   │
│   │ HA VPN Gateway + Cloud Router                          │   │
│   │ • BGP ASN: 64514                                       │   │
│   │ • 4 IPsec Tunnels                                      │   │
│   └──────────────────┬──────────────────────────────────────┘   │
└──────────────────────┼──────────────────────────────────────────┘
                       │
                       │  🔐 VPN Tunnels (IPsec + BGP)
                       │
┌──────────────────────▼──────────────────────────────────────────┐
│                    AWS (ap-southeast-1)                          │
│                                                                  │
│   ┌──────────────────┬──────────────────────────────────────┐   │
│   │ Transit Gateway + Virtual Private Gateway              │   │
│   │ • BGP ASN: 64515                                       │   │
│   │ • 4 VPN Connections                                    │   │
│   └──────────────────┬──────────────────────────────────────┘   │
│                      │                                           │
│   ┌──────────────────▼──────────────────────────────────────┐   │
│   │ VPC: aws-net (10.0.0.0/16)                             │   │
│   │ Private Subnet: 10.0.1.0/24                            │   │
│   └──────────────────┬──────────────────────────────────────┘   │
│                      │                                           │
│   ┌──────────────────▼──────────────────────────────────────┐   │
│   │ aws-ec2                                                │   │
│   │ • t3.micro (1 vCPU, 1GB RAM)                           │   │
│   │ • Ubuntu 24.04 LTS                                     │   │
│   │ • Private IP: 10.0.1.x                                 │   │
│   │ • Public IP: enabled (for SSH)                         │   │
│   └────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

## Resources Summary

| Resource | GCP | AWS |
|----------|-----|-----|
| **VM Instance** | gcp-vm (e2-small) | aws-ec2 (t3.micro) |
| **OS** | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |
| **Specs** | 2 vCPU, 2GB RAM | 1 vCPU, 1GB RAM |
| **VPC CIDR** | 10.10.0.0/16 | 10.0.0.0/16 |
| **Subnet** | 10.10.0.0/18 | 10.0.1.0/24 |
| **Private IP** | 10.10.0.x | 10.0.1.x |
| **Public IP** | No (IAP access) | Yes (for SSH) |
| **Region/Zone** | asia-northeast1-a | ap-southeast-1a |
| **BGP ASN** | 64514 | 64515 |
| **VPN Tunnels** | 4 (HA VPN Gateway) | 4 (Transit Gateway + VPG) |

## Deployment

```bash
cd provision
terraform init
terraform plan
terraform apply
```

## Accessing the VMs

### GCP VM (via IAP)

```bash
gcloud compute ssh gcp-vm --zone=asia-northeast1-a --tunnel-through-iap
```

### AWS EC2 (via SSH)

```bash
ssh -i /path/to/your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

Get the public IP from Terraform output:
```bash
terraform output ec2_public_ip
```

## Testing VPN Connectivity

### From GCP VM to AWS EC2

1. SSH into GCP VM:
```bash
gcloud compute ssh gcp-vm --zone=asia-northeast1-a --tunnel-through-iap
```

2. Get AWS EC2 private IP:
```bash
# From your local machine
terraform output ec2_private_ip
```

3. Test connectivity from GCP VM:
```bash
# Ping AWS EC2
ping <AWS_EC2_PRIVATE_IP>

# Check routes
ip route show | grep 10.0

# Test HTTP (if web server running on EC2)
curl http://<AWS_EC2_PRIVATE_IP>
```

### From AWS EC2 to GCP VM

1. SSH into AWS EC2:
```bash
ssh -i /path/to/key.pem ubuntu@<EC2_PUBLIC_IP>
```

2. Get GCP VM private IP:
```bash
# From your local machine
terraform output vm_internal_ip
```

3. Test connectivity from AWS EC2:
```bash
# Ping GCP VM
ping <GCP_VM_PRIVATE_IP>

# Check routes
ip route show | grep 10.10

# Test HTTP (if web server running on GCP VM)
curl http://<GCP_VM_PRIVATE_IP>
```

### Verify VPN Status

```bash
# Check GCP VPN tunnels
gcloud compute vpn-tunnels list

# Check GCP router BGP status
gcloud compute routers get-status vpn-router --region=asia-northeast1

# Check AWS VPN connections (from AWS Console or CLI)
aws ec2 describe-vpn-connections
```