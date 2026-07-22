# MediCore Database EC2 instance

resource "aws_instance" "database" {
  ami           = data.aws_ami.ubuntu_2604.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private_db_a.id

  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  key_name = var.bastion_key_name

  associate_public_ip_address = false

  monitoring = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "medicore-database-vm"
    Tier = "Database"
    Role = "Database"
  }
}