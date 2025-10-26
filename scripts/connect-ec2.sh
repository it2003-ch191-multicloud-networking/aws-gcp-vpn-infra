#!/bin/bash
# EC2 Instance Connect - Quick Connection Script
# Requires: AWS CLI v2.12.0+

set -e

# Configuration
INSTANCE_ID="${1:-i-04d69611b9bce7773}"
SSH_KEY="${2:-${HOME}/.ssh/id_ed25519}"
SSH_USER="${3:-ubuntu}"
AWS_PROFILE="${AWS_PROFILE:-truong-bot}"

echo "======================================"
echo "EC2 Instance Connect via EIC Endpoint"
echo "======================================"
echo "Instance ID: $INSTANCE_ID"
echo "SSH User:    $SSH_USER"
echo "SSH Key:     $SSH_KEY"
echo "AWS Profile: $AWS_PROFILE"
echo "======================================"
echo ""

# Check AWS CLI version
echo "Checking AWS CLI version..."
AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
echo "AWS CLI version: $AWS_VERSION"
echo ""

# Verify instance exists and is running
echo "Verifying instance status..."
INSTANCE_STATE=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$INSTANCE_STATE" = "NOT_FOUND" ]; then
    echo "❌ Error: Instance $INSTANCE_ID not found!"
    exit 1
fi

echo "Instance state: $INSTANCE_STATE"

if [ "$INSTANCE_STATE" != "running" ]; then
    echo "⚠️  Warning: Instance is not running!"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if EIC Endpoint exists
echo ""
echo "Checking EIC Endpoint..."
EIC_COUNT=$(aws ec2 describe-instance-connect-endpoints \
  --filters "Name=state,Values=create-complete" \
  --query "length(InstanceConnectEndpoints)" \
  --output text 2>/dev/null || echo "0")

if [ "$EIC_COUNT" = "0" ]; then
    echo "❌ Error: No EC2 Instance Connect Endpoint found!"
    echo ""
    echo "To create an EIC Endpoint:"
    echo "1. Set 'aws_create_vpc_endpoints = true' in terraform.tfvars"
    echo "2. Run: terraform apply"
    exit 1
fi

echo "✅ EIC Endpoint found"
echo ""

echo ""
echo "Connect using OpenSSH ProxyCommand"
ssh -i "$SSH_KEY" \
  -o ProxyCommand="aws ec2-instance-connect open-tunnel --instance-id $INSTANCE_ID" \
  -o StrictHostKeyChecking=no \
  "$SSH_USER@$INSTANCE_ID"