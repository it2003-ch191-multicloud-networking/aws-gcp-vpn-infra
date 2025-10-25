#!/bin/bash
# GCP VM Startup Script
# Instance: ${vm_name}
# Environment: ${environment}

set -e

# Log all output to a file
exec > >(tee /var/log/startup-script.log)
exec 2>&1

echo "========================================="
echo "Starting GCP VM initialization at $(date)"
echo "Instance: ${vm_name}"
echo "Environment: ${environment}"
echo "Zone: ${zone}"
echo "========================================="

# Update system
echo "[$(date)] Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install useful tools
echo "[$(date)] Installing network and monitoring tools..."
apt-get install -y \
  iputils-ping \
  traceroute \
  net-tools \
  curl \
  wget \
  htop \
  jq \
  dnsutils \
  tcpdump \
  iperf3

# Configure SSH keys (GCP handles this via metadata, but we can add custom logic here)
%{ if length(ssh_keys) > 0 ~}
echo "[$(date)] SSH keys configured via GCP metadata"
echo "[$(date)] Total SSH keys: ${length(ssh_keys)}"

# Log SSH key users
%{ for idx, key in ssh_keys ~}
echo "[$(date)] SSH key ${idx + 1}: $(echo '${key}' | cut -d':' -f1)"
%{ endfor ~}
%{ else ~}
echo "[$(date)] OS Login enabled - no custom SSH keys"
%{ endif ~}

# Add private key for inter-instance SSH (VPN testing)
echo "[$(date)] Installing shared private key for VPN connectivity testing..."

# Get the primary user from SSH keys or use default
%{ if length(ssh_keys) > 0 ~}
PRIMARY_USER=$(echo '${ssh_keys[0]}' | cut -d':' -f1)
%{ else ~}
PRIMARY_USER="ubuntu"
%{ endif ~}

# Ensure user exists
if ! id "$PRIMARY_USER" &>/dev/null; then
  echo "[$(date)] User $PRIMARY_USER does not exist, using root to create .ssh directory"
  # For some GCP images, user might not exist yet
  # Try common users
  for user in ubuntu debian admin; do
    if id "$user" &>/dev/null; then
      PRIMARY_USER="$user"
      break
    fi
  done
fi

# Create .ssh directory for the user
USER_HOME=$(eval echo ~$PRIMARY_USER)
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"

# Install private key
cat > "$USER_HOME/.ssh/id_ed25519" <<'PRIVATEKEY'
${private_key}
PRIVATEKEY
chmod 600 "$USER_HOME/.ssh/id_ed25519"
chown -R $PRIMARY_USER:$PRIMARY_USER "$USER_HOME/.ssh"
echo "[$(date)] Private key installed for user $PRIMARY_USER at $USER_HOME/.ssh/id_ed25519"

# Enable IP forwarding for VPN routing
echo "[$(date)] Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# Get instance metadata
echo "[$(date)] Fetching instance metadata..."
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
ZONE_METADATA=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d'/' -f4)
PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/project-id)

# Create welcome file
echo "[$(date)] Creating welcome file..."
cat > /home/ubuntu/welcome.txt <<EOL
========================================
Welcome to ${vm_name}
========================================
Environment: ${environment}
Started at: $(date)
Internal IP: $INTERNAL_IP
Zone: $ZONE_METADATA
Project: $PROJECT_ID

GCP VPC CIDR: ${gcp_vpc_cidr}
AWS VPC CIDR: ${aws_vpc_cidr}

This instance is configured for VPN connectivity testing.
========================================
EOL

# Set proper ownership (try both ubuntu and default compute user)
if id "ubuntu" &>/dev/null; then
  chown ubuntu:ubuntu /home/ubuntu/welcome.txt 2>/dev/null || true
else
  # For Debian-based GCP images, user might be named differently
  DEFAULT_USER=$(ls /home | head -n 1)
  if [ -n "$DEFAULT_USER" ]; then
    cp /home/ubuntu/welcome.txt /home/$DEFAULT_USER/welcome.txt 2>/dev/null || true
    chown $DEFAULT_USER:$DEFAULT_USER /home/$DEFAULT_USER/welcome.txt 2>/dev/null || true
  fi
fi

# Log startup completion
echo "[$(date)] GCP VM ${vm_name} initialization completed successfully"
echo "========================================="