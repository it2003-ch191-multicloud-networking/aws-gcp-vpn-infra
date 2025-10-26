#!/bin/bash
# Connect to GCP VM via IAP Tunnel

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VM_NAME="${1:-gcp-vm}"
ZONE="${2:-asia-northeast1-a}"
SSH_USER="${3:-truongtbn}"
PROJECT_ID="${4:-multicloud-475408}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GCP VM Connection via IAP Tunnel${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Step 1: Check gcloud CLI
echo -e "${YELLOW}[1/5] Checking gcloud CLI...${NC}"
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI not found${NC}"
    echo "Please install gcloud CLI: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

GCLOUD_VERSION=$(gcloud version --format="value(core)" 2>/dev/null || echo "unknown")
echo -e "${GREEN}✓ gcloud CLI version: $GCLOUD_VERSION${NC}"
echo ""

# Step 2: Get GCP Project ID
echo -e "${YELLOW}[2/5] Getting GCP project...${NC}"
if [ -z "$PROJECT_ID" ]; then
    # Try to get from terraform output
    if [ -f "../provision/terraform.tfstate" ]; then
        PROJECT_ID=$(cd ../provision && terraform output -raw gcp_project_id 2>/dev/null || echo "")
    fi
    
    # If still empty, get from gcloud config
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
    fi
fi

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Could not determine GCP project ID${NC}"
    echo "Please set project: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo -e "${GREEN}✓ Using project: $PROJECT_ID${NC}"
echo ""

# Step 3: Check authentication
echo -e "${YELLOW}[3/5] Checking GCP authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GCP${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
echo -e "${GREEN}✓ Authenticated as: $ACTIVE_ACCOUNT${NC}"
echo ""

# Step 4: Verify VM exists and is running
echo -e "${YELLOW}[4/5] Checking VM status...${NC}"
VM_STATUS=$(gcloud compute instances describe "$VM_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT_ID" \
    --format="value(status)" 2>/dev/null || echo "NOT_FOUND")

if [ "$VM_STATUS" = "NOT_FOUND" ]; then
    echo -e "${RED}Error: VM '$VM_NAME' not found in zone '$ZONE'${NC}"
    echo ""
    echo "Available VMs:"
    gcloud compute instances list --project="$PROJECT_ID" --format="table(name,zone,status)"
    exit 1
fi

if [ "$VM_STATUS" != "RUNNING" ]; then
    echo -e "${RED}Error: VM is not running (status: $VM_STATUS)${NC}"
    echo "Please start the VM first:"
    echo "  gcloud compute instances start $VM_NAME --zone=$ZONE"
    exit 1
fi

INTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT_ID" \
    --format="value(networkInterfaces[0].networkIP)")

echo -e "${GREEN}✓ VM Status: $VM_STATUS${NC}"
echo -e "${GREEN}✓ Internal IP: $INTERNAL_IP${NC}"
echo ""

# Step 5: Connect via IAP tunnel
echo -e "${YELLOW}[5/5] Connecting to VM via IAP tunnel...${NC}"
echo -e "${GREEN}Command: gcloud compute ssh $SSH_USER@$VM_NAME --zone=$ZONE --tunnel-through-iap${NC}"
echo ""

# Connect
gcloud compute ssh "$SSH_USER@$VM_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT_ID" \
    --tunnel-through-iap \
    --ssh-flag="-o StrictHostKeyChecking=no"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Disconnected from GCP VM${NC}"
echo -e "${GREEN}========================================${NC}"