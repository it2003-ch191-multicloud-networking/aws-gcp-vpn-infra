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