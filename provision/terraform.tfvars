project_id                  = "multicloud-475408"
impersonate_service_account = "github-actions-terraform@multicloud-475408.iam.gserviceaccount.com"
network_name                = "gcp-net"
subnet_regions              = ["asia-northeast1", "asia-northeast1"]
vpn_gwy_region              = "asia-northeast1"
gcp_router_asn              = "64514"
aws_vpc_cidr                = "10.0.0.0/16"
aws_router_asn              = "64515"
num_tunnels                 = 4
shared_secret               = "this_is_a_very_secure_and_random_string_hehe"

# VM Configuration
vm_name         = "test-gcp-vm"
vm_machine_type = "e2-small"
vm_zone         = "asia-northeast1-a"
vm_image        = "ubuntu-os-cloud/ubuntu-2404-noble-amd64-v20251014"
environment     = "production"

# EC2 Configuration
ec2_instance_name    = "test-aws-vm"
ec2_instance_type    = "t3.micro"
ec2_enable_public_ip = true
ec2_key_name         = null # Set to your AWS key pair name if you want SSH access

# SSH Keys (applied to both GCP VM and AWS EC2)
ssh_public_keys = [
  "truongtbn:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHc1s1f6fcKib1MkFW02GJm6QFJvDu8W7VsbXhchoVSC truongtbn"
  # Add more keys in format: "username:ssh-rsa AAAA... user@host" for GCP
  # Or just: "ssh-rsa AAAA... user@host" for AWS-only keys
]