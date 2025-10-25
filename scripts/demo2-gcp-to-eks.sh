#!/bin/bash

#################################################################
# Demo 2: GCP to AWS EKS Connectivity Test
# Dynamic script - discovers resources automatically
#################################################################

set -e

# Setup gcloud alias for Windows
alias gcloud="gcloud.cmd"

echo "============================================"
echo "  DEMO 2: GCP → AWS EKS Pod Connectivity"
echo "============================================"
echo ""

# Configuration
GCP_VM_NAME="test-gcp-vm"
GCP_ZONE="asia-northeast1-a"
AWS_REGION="ap-southeast-1"

echo "Step 1: Check VPN Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws ec2 describe-vpn-connections \
  --region $AWS_REGION \
  --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status]' \
  --output table
echo ""

echo "Step 2: Get EKS Cluster Info"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get EKS cluster name dynamically
CLUSTER_NAME=$(aws eks list-clusters --region $AWS_REGION --query 'clusters[0]' --output text)
echo "Found cluster: $CLUSTER_NAME"

# Assume EKS admin role
echo "Assuming EKS admin role..."
CREDS=$(aws sts assume-role \
  --role-arn arn:aws:iam::025066283834:role/reminder-eks-admin-role \
  --role-session-name demo2-test \
  --external-id eks-cluster-access \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

export AWS_ACCESS_KEY_ID=$(echo $CREDS | awk '{print $1}')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | awk '{print $2}')
export AWS_SESSION_TOKEN=$(echo $CREDS | awk '{print $3}')

# Update kubeconfig
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME --alias demo2 > /dev/null

# Get first running pod IP
echo "Getting EKS pod information..."
kubectl get pods -n default -o wide

POD_IP=$(kubectl get pods -n default -o jsonpath='{.items[0].status.podIP}')
POD_NAME=$(kubectl get pods -n default -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_IP" ]; then
    echo "❌ No pods found, deploying test nginx..."
    kubectl run nginx-test --image=nginx:latest --labels="app=nginx-test"
    kubectl wait --for=condition=ready pod/nginx-test --timeout=60s
    POD_IP=$(kubectl get pod nginx-test -o jsonpath='{.status.podIP}')
    POD_NAME="nginx-test"
fi

echo "✅ Target: $POD_NAME ($POD_IP)"
echo ""

# Clear temp credentials for VPN check
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "Step 3: Get GCP VM Info"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
VM_IP=$(gcloud compute instances describe $GCP_VM_NAME \
  --zone=$GCP_ZONE \
  --format="get(networkInterfaces[0].networkIP)")
echo "✅ Source: $GCP_VM_NAME ($VM_IP)"
echo ""

echo "Step 4: Test Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing: GCP VM → EKS Pod ($POD_IP)"
echo ""

# Run connectivity test from GCP VM
gcloud compute ssh $GCP_VM_NAME --zone=$GCP_ZONE --command="
echo '=== Ping Test ==='
ping -c 5 $POD_IP

echo ''
echo '=== HTTP Test ==='
curl -s -o /dev/null -w 'HTTP Status: %{http_code}\nResponse Time: %{time_total}s\n' http://$POD_IP:80

echo ''
echo '=== Application Response ==='
curl -s http://$POD_IP:80 | head -n 3
"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEMO 2 COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Multi-cloud connectivity verified:"
echo "  • GCP VM ($VM_IP) → EKS Pod ($POD_IP)"
echo "  • Region: asia-northeast1 ↔ ap-southeast-1"
echo "  • Protocol: ICMP + HTTP via VPN tunnel"
echo ""
