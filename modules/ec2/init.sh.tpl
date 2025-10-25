#!/bin/bash
# EC2 User Data Init Script
# Instance: ${instance_name}
# Environment: ${environment}

set -e

# Log all output to a file
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "========================================="
echo "Starting EC2 initialization at $(date)"
echo "Instance: ${instance_name}"
echo "Environment: ${environment}"
echo "========================================="

# Update system
echo "[$(date)] Updating system packages..."
apt-get update
apt-get upgrade -y

# Install useful tools
echo "[$(date)] Installing network tools..."
apt-get install -y iputils-ping traceroute net-tools curl wget htop jq

# Configure SSH keys
%{ if length(ssh_keys) > 0 ~}
echo "[$(date)] Configuring additional SSH keys..."
mkdir -p /home/ubuntu/.ssh
touch /home/ubuntu/.ssh/authorized_keys
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

# Add each SSH key
%{ for idx, key in ssh_keys ~}
%{ if idx > 0 ~}
echo "${key}" >> /home/ubuntu/.ssh/authorized_keys
echo "[$(date)] Added SSH key ${idx}"
%{ endif ~}
%{ endfor ~}

chown -R ubuntu:ubuntu /home/ubuntu/.ssh
echo "[$(date)] SSH keys configured successfully"
%{ else ~}
echo "[$(date)] No additional SSH keys to configure"
%{ endif ~}

# Enable IP forwarding for VPN
echo "[$(date)] Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Create welcome file
echo "[$(date)] Creating welcome file..."
cat > /home/ubuntu/welcome.txt <<EOL
========================================
Welcome to ${instance_name}
========================================
Environment: ${environment}
Started at: $(date)
AWS VPC CIDR: ${aws_vpc_cidr}
GCP VPC CIDR: ${gcp_vpc_cidr}

This instance is configured for VPN connectivity testing.
========================================
EOL
chown ubuntu:ubuntu /home/ubuntu/welcome.txt

# Log startup completion
echo "[$(date)] EC2 instance ${instance_name} initialization completed successfully"
echo "========================================="