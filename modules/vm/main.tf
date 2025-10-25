# GCP VM Instance
resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    # No external IP - access via IAP only
  }

  dynamic "service_account" {
    for_each = local.service_account_email != null ? [1] : []
    content {
      email  = local.service_account_email
      scopes = ["cloud-platform"]
    }
  }

  metadata = {
    enable-oslogin = length(var.ssh_keys) > 0 ? "FALSE" : "TRUE"
    ssh-keys       = length(var.ssh_keys) > 0 ? join("\n", var.ssh_keys) : null
  }

  tags = ["${var.vm_name}", "vpn-enabled"]

  labels = {
    environment = var.environment
    purpose     = "vpn-connectivity"
  }

  # Use template file for startup script with SSH keys
  metadata_startup_script = templatefile("${path.module}/init.sh.tpl", {
    vm_name           = var.vm_name
    environment       = var.environment
    zone              = var.zone
    ssh_keys          = var.ssh_keys
    aws_vpc_cidr      = var.aws_vpc_cidr
    gcp_vpc_cidr      = var.gcp_vpc_cidr
    enable_monitoring = var.enable_monitoring
    custom_commands   = var.custom_commands
    private_key       = var.ssh_private_key
  })
}
