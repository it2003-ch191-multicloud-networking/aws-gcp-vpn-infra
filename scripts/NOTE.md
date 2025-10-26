# Scripts Usage Guide

## Available Scripts

### connect-ec2.sh
Connect to AWS EC2 instance via SSH.

```bash
./connect-ec2.sh
```

### connect-vm.sh
Connect to GCP VM instance via SSH.

```bash
./connect-vm.sh
```

### demo2-gcp-to-eks.sh
Demonstrate connectivity from GCP to AWS EKS cluster.

```bash
./demo2-gcp-to-eks.sh
```

### show-info.sh
Display infrastructure information (IPs, endpoints, etc.).

```bash
./show-info.sh
```

## Prerequisites

- Make scripts executable:
  ```bash
  chmod +x *.sh
  ```

- Ensure you have:
  - AWS CLI configured
  - GCP CLI (gcloud) configured
  - Proper SSH keys in place
  - Required permissions for both clouds