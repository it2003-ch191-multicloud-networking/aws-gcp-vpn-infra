# Multi-Cloud networking between GCP and AWS

High-availability VPN network infrastructure connecting Google Cloud Platform and Amazon Web Services using Terraform.

## Architecture

```
┌─────────────────────────┐        VPN Tunnels        ┌─────────────────────────┐
│   GCP (Tokyo)           │◄────────────────────────►│   AWS (Singapore)       │
│   10.10.0.0/16          │    4 IPsec + BGP         │   10.0.0.0/16           │
│   ASN: 64514            │                          │   ASN: 64515            │
└─────────────────────────┘                          └─────────────────────────┘
```

**Key Components:**
- **GCP**: HA VPN Gateway, Cloud Router, Compute Engine VM (10.10.0.2)
- **AWS**: Transit Gateway, VPN Connections, EC2 Instance (10.0.1.226)
- **VPN**: 4 redundant IPsec tunnels with BGP dynamic routing
- **Security**: Firewall rules, security groups, encrypted traffic

## Quick Start

```bash
cd provision
terraform init
terraform plan
terraform apply
```

## Infrastructure Details

| Component | GCP | AWS |
|-----------|-----|-----|
| **Region** | asia-northeast1 (Tokyo) | ap-southeast-1 (Singapore) |
| **VPC CIDR** | 10.10.0.0/16 | 10.0.0.0/16 |
| **VPN Gateway** | HA VPN (2 interfaces) | Transit Gateway |
| **BGP ASN** | 64514 | 64515 |
| **VM/Instance** | e2-small (10.10.0.2) | t3.micro (10.0.1.226) |
| **OS** | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |

## Requirements

- **Terraform** >= 1.0
- **Google Cloud SDK** (`gcloud`)
- **AWS CLI** (version 2+)
- **Credentials**: GCP service account, AWS IAM access

## Documentation

- **[GUIDE.md](GUIDE.md)** - Complete setup guide and troubleshooting
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture with diagrams

## Estimated Costs

| Service | Monthly Cost |
|---------|--------------|
| GCP HA VPN Gateway | ~$150 |
| GCP VM (e2-small) | ~$15 |
| AWS Transit Gateway | ~$50 |
| AWS EC2 (t3.micro) | ~$10 |
| **Total** | **~$225** |

---

**For detailed setup instructions, see [GUIDE.md](GUIDE.md)**

