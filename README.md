# Guide

This guide provides the steps to provision the multi-cloud network infrastructure using Terraform.

## Prerequisites

Before you begin, ensure you have the following tools installed:

1.  [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli) (version 1.0 or later)
2.  [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
3.  [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Step 1: Configure Cloud Provider Credentials

### Google Cloud Platform (GCP)

1.  Authenticate with the gcloud CLI. This command will open a browser window for you to log in to your Google account.

    ```bash
    gcloud auth application-default login --impersonate-service-account github-actions-terraform@multicloud-475408.iam.gserviceaccount.com
    ```

2.  Ensure the user account you authenticated with has permissions to impersonate the service account defined in your `.tfvars` file. Specifically, it needs the "Service Account Token Creator" (`roles/iam.serviceAccountTokenCreator`) role.

### Amazon Web Services (AWS)

Configure your AWS credentials. The simplest method is to use the `aws configure` command and follow the prompts.

```bash
aws configure
```

This will store your credentials in the default location (`~/.aws/credentials`), which Terraform will automatically use.

## Step 2: Configure Terraform Variables

1.  Navigate to the `provision` directory:
    ```bash
    cd provision
    ```
2.  Open the `terraform.tfvars` file.
3.  Update the placeholder values with your specific settings for both GCP and AWS.

    ```terraform-vars
    provision/terraform.tfvars
    project_id                  = "your-gcp-project-id"
    impersonate_service_account = "your-service-account@your-gcp-project-id.iam.gserviceaccount.com"
    network_name                = "gcp-net"
    subnet_regions              = ["asia-northeast1", "us-central1"] // Example regions
    vpn_gwy_region              = "asia-northeast1"
    gcp_router_asn              = "64514"
    aws_vpc_cidr                = "10.0.1.0/16"
    aws_router_asn              = "64515"
    num_tunnels                 = 2
    shared_secret               = "replace-with-a-strong-random-secret"
    ```

## Step 3: Run Terraform

From within the `provision` directory, execute the following commands:

1.  **Initialize Terraform:**
    This command downloads the necessary provider plugins.

    ```bash
    terraform init
    ```

2.  **Create an Execution Plan:**
    This command shows you what resources Terraform will create, modify, or destroy. Review the plan carefully.

    ```bash
    terraform plan
    ```

3.  **Apply the Configuration:**
    This command provisions the infrastructure as defined in your configuration files. You will be prompted to confirm the action.

    ```bash
    terraform apply
    ```

## Step 4: Clean Up Resources

To tear down all the resources created by this project, run the destroy command from the `provision` directory.

```bash
terraform destroy
```
