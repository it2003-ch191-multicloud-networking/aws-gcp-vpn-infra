resource "google_compute_network" "net" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "subnet" {
  count = length(var.subnet_regions)

  ip_cidr_range            = cidrsubnets(var.gcp_vpc_cidr, 2, 2)[count.index]
  name                     = "snet-${count.index}"
  network                  = google_compute_network.net.name
  region                   = var.subnet_regions[count.index]
  private_ip_google_access = true
}

resource "google_compute_router" "nat_router" {
  count = var.enable_cloud_nat ? 1 : 0

  name    = "${var.network_name}-nat-router"
  region  = var.cloud_nat_region
  network = google_compute_network.net.id

  bgp {
    asn = var.cloud_nat_router_asn
  }
}

# Cloud NAT Gateway
resource "google_compute_router_nat" "nat_gateway" {
  count = var.enable_cloud_nat ? 1 : 0

  name                               = "${var.network_name}-nat-gateway"
  router                             = google_compute_router.nat_router[0].name
  region                             = var.cloud_nat_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  # Advanced settings
  min_ports_per_vm                 = 64
  enable_endpoint_independent_mapping = true

  depends_on = [google_compute_router.nat_router]
}
