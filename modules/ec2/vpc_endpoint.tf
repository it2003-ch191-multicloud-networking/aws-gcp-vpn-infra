# Security Group for EC2 Instance Connect Endpoint
resource "aws_security_group" "eic_endpoint_sg" {
  count = var.aws_create_vpc_endpoints ? 1 : 0

  name        = "${var.instance_name}-eic-endpoint-sg"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic (EIC Endpoint needs to connect to EC2 instances)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.instance_name}-eic-endpoint-sg"
    Environment = var.environment
    Purpose     = "ec2-instance-connect"
  }
}

# EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "eic" {
  count = var.aws_create_vpc_endpoints ? 1 : 0

  subnet_id          = var.subnet_id
  security_group_ids = [aws_security_group.eic_endpoint_sg[0].id]
  preserve_client_ip = var.preserve_client_ip

  tags = {
    Name        = "${var.instance_name}-eic-endpoint"
    Environment = var.environment
    Purpose     = "ssh-via-private-ip"
  }
}
