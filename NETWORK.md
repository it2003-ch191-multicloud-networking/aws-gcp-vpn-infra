# Network Segmentation

AWS:
- CIDR: 10.0.0.0/16
  - azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  - private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  - public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

GCP:
- CIDR: 10.10.0.0/16

VPN Tunnel: GCP open 2 public interface, each GG interface connect to 2 public interface in AWS, then Transit GW in AWS forward them into VPC

Ref: https://cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-aws