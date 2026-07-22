# MediCore RDS database subnet group
# DB subnet group for the MediCore PostgreSQL database
# The RDS instance can be placed in one of the restricted database subnets.

resource "aws_db_subnet_group" "medicore" {
  name = "medicore-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_db_a.id,
    aws_subnet.private_db_b.id,
    aws_subnet.private_db_c.id
  ]

  tags = {
    Name = "medicore-db-subnet-group"
    Tier = "Database"
  }
}

# Managed PostgreSQL database for MediCore

resource "aws_db_instance" "medicore" {
  identifier = "medicore-postgresql"

  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 5432

  db_subnet_group_name = aws_db_subnet_group.medicore.name

  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  publicly_accessible = false
  multi_az            = false

  # Enables automated backups and point-in-time recovery.
  backup_retention_period = 1
  backup_window           = "02:00-03:00"

  maintenance_window = "sun:03:00-sun:04:00"

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  # Avoid additional monitoring costs 
  monitoring_interval          = 0
  performance_insights_enabled = false

  # Allows the academic environment to be removed without retaining
  # an additional chargeable final snapshot.
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "medicore-postgresql"
    Tier = "Database"
    Role = "ManagedDatabase"
  }
}