data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# EC2 Instance
resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = length(var.ssh_public_keys) > 0 ? aws_key_pair.ec2_key[0].key_name : var.key_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  associate_public_ip_address = var.enable_public_ip

  root_block_device {
    volume_type = "gp3"
    volume_size = var.disk_size
    encrypted   = true
  }

  # Use template file for user data with SSH keys
  user_data = templatefile("${path.module}/init.sh.tpl", {
    instance_name = var.instance_name
    environment   = var.environment
    ssh_keys      = var.ssh_public_keys
    aws_vpc_cidr  = var.aws_vpc_cidr
    gcp_vpc_cidr  = var.gcp_vpc_cidr
  })

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Purpose     = "vpn-connectivity-test"
  }
}
