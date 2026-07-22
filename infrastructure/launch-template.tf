# MediCore Application Launch Template

resource "aws_launch_template" "application" {

  name_prefix = "medicore-application-"

  image_id      = data.aws_ami.ubuntu_2604.id
  instance_type = "t3.micro"

  key_name = var.bastion_key_name

  user_data = base64encode(<<-EOF
    #!/bin/bash

    apt-get update -y
    apt-get install -y nginx

    systemctl enable nginx
    systemctl start nginx

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>MediCore Application</title>
    </head>
    <body>
      <h1>MediCore Application Server</h1>
      <p>Secure clinical cloud infrastructure</p>
      <p>Server hostname: $(hostname)</p>
    </body>
    </html>
    HTML
  EOF
  )

  vpc_security_group_ids = [
    aws_security_group.application.id
  ]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = false
  }

  block_device_mappings {

    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = 8
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {

    resource_type = "instance"

    tags = {
      Name = "medicore-application"
      Tier = "Application"
      Role = "Web"
    }
  }

  tags = {
    Name = "medicore-launch-template"
  }
}