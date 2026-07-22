# Latest Canonical Ubuntu Server 26.04 LTS AMI
# Region is inherited from provider.tf: eu-west-2


data "aws_ami" "ubuntu_2604" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"
    ]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# MediCore Bastion Host

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu_2604.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.bastion_key_name
  associate_public_ip_address = true

  # Basic CloudWatch monitoring only, avoiding detailed-monitoring charges.
  monitoring = false

  # Require Instance Metadata Service Version 2.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Encrypted root volume.
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "medicore-bastion"
    Tier = "Management"
    Role = "Bastion"
  }
}