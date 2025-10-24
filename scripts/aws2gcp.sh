#!/bin/bash

# Test connectivity from AWS EC2 to GCP VM
# This script connects to AWS EC2 and tests connectivity to GCP

set -e

echo "==================================================================="
echo "  AWS → GCP Connectivity Test"
echo "==================================================================="
echo ""

# Get IPs from terraform
cd "$(dirname "$0")/../provision"
GCP_VM_IP=$(terraform output -raw vm_internal_ip 2>/dev/null || echo "10.10.0.2")
EC2_PRIVATE_IP=$(terraform output -raw ec2_private_ip 2>/dev/null || echo "10.0.1.226")
EC2_PUBLIC_IP=$(terraform output -raw ec2_public_ip 2>/dev/null || echo "")
EC2_NAME=$(terraform output -raw ec2_instance_name 2>/dev/null || echo "bastion-vm")
cd - > /dev/null

echo "Source: AWS EC2 ($EC2_NAME)"
echo "  Private IP: $EC2_PRIVATE_IP"
echo "  Public IP: $EC2_PUBLIC_IP"
echo ""
echo "Target: GCP VM"
echo "  Private IP: $GCP_VM_IP"
echo ""

# Check if we have SSH key
SSH_KEY="${HOME}/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo "❌ SSH key not found at $SSH_KEY"
  echo ""
  echo "Please provide the path to your SSH private key:"
  echo "  export AWS_SSH_KEY=/path/to/your/key.pem"
  echo ""
  echo "Or use the default AWS key pair:"
  echo "  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''"
  echo ""
  exit 1
fi

# Check if public IP is available
if [ -z "$EC2_PUBLIC_IP" ]; then
  echo "❌ EC2 public IP not found. Cannot connect to EC2 instance."
  echo "Please ensure EC2 instance has a public IP assigned."
  exit 1
fi

# Test 1: Ping test
echo "==================================================================="
echo "  Test 1: Ping GCP VM from AWS EC2"
echo "==================================================================="
echo ""
echo "Command: ping -c 4 $GCP_VM_IP"
echo ""

export AWS_PROFILE=truong-bot
ssh -i "$SSH_KEY" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o ConnectTimeout=10 \
  ubuntu@$EC2_PUBLIC_IP \
  "ping -c 4 $GCP_VM_IP"

echo ""
echo "✅ Ping test completed"
echo ""

# Test 2: Route check
echo "==================================================================="
echo "  Test 2: Check routing table on AWS EC2"
echo "==================================================================="
echo ""
echo "Looking for routes to GCP network (10.10.0.0/16)..."
echo ""

ssh -i "$SSH_KEY" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  ubuntu@$EC2_PUBLIC_IP \
  "ip route show | grep -E '(default|10\.10\.)' || ip route show"

echo ""
echo "✅ Route check completed"
echo ""

# Test 3: Traceroute
echo "==================================================================="
echo "  Test 3: Traceroute to GCP VM"
echo "==================================================================="
echo ""
echo "Command: traceroute -n -m 10 $GCP_VM_IP"
echo ""

ssh -i "$SSH_KEY" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  ubuntu@$EC2_PUBLIC_IP \
  "which traceroute >/dev/null 2>&1 || (echo 'Installing traceroute...' && sudo apt-get update -qq && sudo apt-get install -y traceroute -qq); traceroute -n -m 10 $GCP_VM_IP"

echo ""
echo "✅ Traceroute completed"
echo ""

# Test 4: TCP connectivity test (optional)
echo "==================================================================="
echo "  Test 4: TCP Port Scan (optional)"
echo "==================================================================="
echo ""
echo "Testing common ports on GCP VM..."
echo ""

ssh -i "$SSH_KEY" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  ubuntu@$EC2_PUBLIC_IP \
  "for port in 22 80 443; do timeout 2 bash -c 'cat < /dev/null > /dev/tcp/$GCP_VM_IP/\$port' 2>/dev/null && echo \"Port \$port: OPEN\" || echo \"Port \$port: CLOSED\"; done"

echo ""
echo "==================================================================="
echo "  AWS → GCP Test Summary"
echo "==================================================================="
echo ""
echo "✅ All connectivity tests completed from AWS to GCP"
echo "   Source: $EC2_PRIVATE_IP (AWS)"
echo "   Target: $GCP_VM_IP (GCP)"
echo ""
echo "If ping was successful, the VPN tunnel is working correctly!"
echo ""
