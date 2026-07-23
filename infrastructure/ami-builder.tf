# Temporary public EC2 instance used to build the application AMI

resource "aws_instance" "ami_builder" {
  ami                         = data.aws_ami.ubuntu_2604.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.ami_builder.id]
  key_name                    = var.bastion_key_name
  associate_public_ip_address = true

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>MediCore Health Systems</title>
    </head>
    <body>
      <h1>MediCore Health Systems</h1>
      <h2>Secure Clinical Cloud Infrastructure</h2>
      <p>The MediCore application server is running successfully.</p>
    </body>
    </html>
    HTML

    systemctl enable nginx
    systemctl restart nginx


  EOF

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name        = "medicore-ami-builder"
    Project     = "MediCore"
    Environment = "temporary"
    Purpose     = "Golden AMI creation"
  }
}

output "ami_builder_public_ip" {
  description = "Public IP address of the temporary AMI builder"
  value       = aws_instance.ami_builder.public_ip
}

output "ami_builder_instance_id" {
  description = "Instance ID of the temporary AMI builder"
  value       = aws_instance.ami_builder.id
}
