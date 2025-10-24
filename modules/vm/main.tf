# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Service account for the VM instance
resource "google_service_account" "vm_sa" {
  account_id   = "${var.vm_name}-sa"
  display_name = "Service Account for ${var.vm_name}"
  description  = "Service account for GCP VM instance with VPN connectivity"
}

# Firewall rule to allow IAP SSH access
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.vm_name}-allow-iap-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP IP range for SSH
  source_ranges = ["35.235.240.0/20"]
  
  target_service_accounts = [google_service_account.vm_sa.email]
  
  description = "Allow SSH access from IAP"
}

# Firewall rule to allow internal traffic from AWS VPC CIDR
resource "google_compute_firewall" "allow_aws_traffic" {
  name    = "${var.vm_name}-allow-aws-traffic"
  network = var.network

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.aws_vpc_cidr]
  
  target_service_accounts = [google_service_account.vm_sa.email]
  
  description = "Allow traffic from AWS VPC through VPN tunnel"
}

# Firewall rule to allow internal GCP traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vm_name}-allow-internal"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.10.0.0/16"]
  
  target_service_accounts = [google_service_account.vm_sa.email]
  
  description = "Allow internal GCP VPC traffic"
}

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

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
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

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update system
    apt-get update
    
    # Install useful tools
    apt-get install -y iputils-ping traceroute net-tools curl wget
    
    # Enable IP forwarding (if needed for routing)
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    
    # Log startup
    echo "VM ${var.vm_name} started at $(date)" > /var/log/vm-startup.log
  EOF
}
