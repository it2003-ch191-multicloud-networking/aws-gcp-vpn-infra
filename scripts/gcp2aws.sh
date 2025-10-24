#!/bin/bash

# Test connectivity from GCP VM to AWS EC2
# This script connects to GCP VM and tests connectivity to AWS

set -e

echo "==================================================================="
echo "  GCP → AWS Connectivity Test"
echo "==================================================================="
echo ""

# Get IPs from terraform
cd "$(dirname "$0")/../provision"
GCP_VM_IP=$(terraform output -raw vm_internal_ip 2>/dev/null || echo "10.10.0.2")
EC2_PRIVATE_IP=$(terraform output -raw ec2_private_ip 2>/dev/null || echo "10.0.1.226")
VM_ZONE=$(terraform output -raw vm_zone 2>/dev/null || echo "asia-northeast1-a")
VM_NAME=$(terraform output -raw vm_instance_name 2>/dev/null || echo "test-gcp-vm")
cd - > /dev/null

echo "Source: GCP VM ($VM_NAME)"
echo "  Private IP: $GCP_VM_IP"
echo "  Zone: $VM_ZONE"
echo ""
echo "Target: AWS EC2"
echo "  Private IP: $EC2_PRIVATE_IP"
echo ""

# Test 1: Ping test
echo "==================================================================="
echo "  Test 1: Ping AWS EC2 from GCP VM"
echo "==================================================================="
echo ""
echo "Command: ping -c 4 $EC2_PRIVATE_IP"
echo ""

gcloud compute ssh $VM_NAME \
  --zone=$VM_ZONE \
  --tunnel-through-iap \
  --project=multicloud-475408 \
  --command="ping -c 4 $EC2_PRIVATE_IP"

echo ""
echo "✅ Ping test completed"
echo ""

# Test 2: Route check
echo "==================================================================="
echo "  Test 2: Check routing table on GCP VM"
echo "==================================================================="
echo ""
echo "Looking for routes to AWS network (10.0.0.0/16)..."
echo ""

gcloud compute ssh $VM_NAME \
  --zone=$VM_ZONE \
  --tunnel-through-iap \
  --project=multicloud-475408 \
  --command="ip route show | grep -E '(default|10\.0\.)' || ip route show"

echo ""
echo "✅ Route check completed"
echo ""

# Test 3: Traceroute
echo "==================================================================="
echo "  Test 3: Traceroute to AWS EC2"
echo "==================================================================="
echo ""
echo "Command: traceroute -n -m 10 $EC2_PRIVATE_IP"
echo ""

gcloud compute ssh $VM_NAME \
  --zone=$VM_ZONE \
  --tunnel-through-iap \
  --project=multicloud-475408 \
  --command="traceroute -n -m 10 $EC2_PRIVATE_IP 2>/dev/null || echo 'Traceroute not installed, installing...' && sudo apt-get update -qq && sudo apt-get install -y traceroute -qq && traceroute -n -m 10 $EC2_PRIVATE_IP"

echo ""
echo "✅ Traceroute completed"
echo ""

# Test 4: TCP connectivity test (optional)
echo "==================================================================="
echo "  Test 4: TCP Port Scan (optional)"
echo "==================================================================="
echo ""
echo "Testing common ports on AWS EC2..."
echo ""

gcloud compute ssh $VM_NAME \
  --zone=$VM_ZONE \
  --tunnel-through-iap \
  --project=multicloud-475408 \
  --command="for port in 22 80 443; do timeout 2 bash -c 'cat < /dev/null > /dev/tcp/$EC2_PRIVATE_IP/\$port' 2>/dev/null && echo \"Port \$port: OPEN\" || echo \"Port \$port: CLOSED\"; done"

echo ""
echo "==================================================================="
echo "  GCP → AWS Test Summary"
echo "==================================================================="
echo ""
echo "✅ All connectivity tests completed from GCP to AWS"
echo "   Source: $GCP_VM_IP (GCP)"
echo "   Target: $EC2_PRIVATE_IP (AWS)"
echo ""
echo "If ping was successful, the VPN tunnel is working correctly!"
echo ""
