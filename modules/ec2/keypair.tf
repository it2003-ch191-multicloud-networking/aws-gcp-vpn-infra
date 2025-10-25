resource "aws_key_pair" "ec2_key" {
  count = length(var.ssh_public_keys) > 0 ? 1 : 0

  key_name   = "${var.instance_name}-key"
  public_key = var.ssh_public_keys[0]

  tags = {
    Name        = "${var.instance_name}-key"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
