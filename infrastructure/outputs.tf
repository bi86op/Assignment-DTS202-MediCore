output "vpc_id" {
  description = "ID of the MediCore VPC"
  value       = aws_vpc.medicore.id
}

output "bastion_public_ip" {
  description = "Public IPv4 address of the MediCore Bastion Host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IPv4 address of the MediCore Bastion Host"
  value       = aws_instance.bastion.private_ip
}

output "bastion_ami_id" {
  description = "Ubuntu 26.04 LTS AMI used by the MediCore Bastion Host"
  value       = data.aws_ami.ubuntu_2604.id
}