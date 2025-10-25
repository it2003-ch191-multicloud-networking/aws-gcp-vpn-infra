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

########################################################################
################ AWS Network ###########################################
########################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # add version constraint
  version = "~> 5.21.0"

  name = var.aws_vpc_name
  cidr = "${var.aws_vpc_cidr}"

  azs             = var.aws_azs
  private_subnets = var.aws_private_subnets
  public_subnets  = var.aws_public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
}

