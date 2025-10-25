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

  target_service_accounts = local.target_service_accounts

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

  target_service_accounts = local.target_service_accounts

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

  source_ranges = [var.gcp_vpc_cidr]

  target_service_accounts = local.target_service_accounts

  description = "Allow internal GCP VPC traffic"
}
