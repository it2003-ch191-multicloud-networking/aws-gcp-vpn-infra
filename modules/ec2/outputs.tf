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

output "instance_id" {
  description = "The instance ID"
  value       = aws_instance.ec2.id
}

output "instance_name" {
  description = "The instance name"
  value       = aws_instance.ec2.tags["Name"]
}

output "private_ip" {
  description = "The private IP address of the instance"
  value       = aws_instance.ec2.private_ip
}

output "public_ip" {
  description = "The public IP address of the instance (if enabled)"
  value       = aws_instance.ec2.public_ip
}

output "availability_zone" {
  description = "The availability zone where the instance is deployed"
  value       = aws_instance.ec2.availability_zone
}

output "security_group_id" {
  description = "The security group ID attached to the instance"
  value       = aws_security_group.ec2_sg.id
}

output "ami_id" {
  description = "The AMI ID used for the instance"
  value       = aws_instance.ec2.ami
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = var.enable_public_ip ? "ssh -i /path/to/key.pem ubuntu@${aws_instance.ec2.public_ip}" : "Use AWS Systems Manager Session Manager"
}
