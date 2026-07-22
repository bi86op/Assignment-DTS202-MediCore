# Bastion Security Group

resource "aws_security_group" "bastion" {
  name        = "medicore-bastion-sg"
  description = "Allows SSH to the bastion from the authorised administrator IP only"
  vpc_id      = aws_vpc.medicore.id

  ingress {
    description = "SSH from authorised administrator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "Allow outbound traffic from the bastion"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medicore-bastion-sg"
    Tier = "Management"
  }
}

# Application Load Balancer Security Group

resource "aws_security_group" "alb" {
  name        = "medicore-alb-sg"
  description = "Allows public HTTP and HTTPS traffic to the load balancer"
  vpc_id      = aws_vpc.medicore.id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow traffic to application targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medicore-alb-sg"
    Tier = "Public"
  }
}

# Application Security Group

resource "aws_security_group" "application" {
  name        = "medicore-application-sg"
  description = "Restricts access to the private application tier"
  vpc_id      = aws_vpc.medicore.id

  ingress {
    description     = "HTTP from the load balancer only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH from the bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow outbound application traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medicore-application-sg"
    Tier = "Application"
  }
}

# Database Security Group

resource "aws_security_group" "database" {
  name        = "medicore-database-sg"
  description = "Allows PostgreSQL only from the application tier"
  vpc_id      = aws_vpc.medicore.id

  ingress {
    description     = "PostgreSQL from application tier only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  ingress {
    description     = "SSH from Bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  tags = {
    Name = "medicore-database-sg"
    Tier = "Database"
  }
}
