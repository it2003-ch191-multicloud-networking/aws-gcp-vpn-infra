resource "google_service_account" "vm_sa" {
  count = var.create_service_account ? 1 : 0

  account_id   = "${var.vm_name}-sa"
  display_name = "Service Account for ${var.vm_name}"
  description  = "Service account for GCP VM instance with VPN connectivity"
}

# Determine which service account to use
locals {
  service_account_email = var.create_service_account ? google_service_account.vm_sa[0].email : (
    var.service_account_email != "" ? var.service_account_email : null
  )
  target_service_accounts = var.create_service_account ? [google_service_account.vm_sa[0].email] : []
}