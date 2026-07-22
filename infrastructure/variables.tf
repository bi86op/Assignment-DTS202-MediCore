variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "MediCore"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "Development"
}

variable "admin_cidr" {
  description = "Administrator public IP"
  type        = string
}

variable "bastion_key_name" {
  description = "Existing EC2 Key Pair for Bastion"
  type        = string
  default     = "medicore-bastion-key"
}

variable "db_name" {
  description = "Name of the MediCore PostgreSQL database"
  type        = string
  default     = "medicore"
}

variable "db_username" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "medicoreadmin"
}

variable "db_password" {
  description = "Administrator password for PostgreSQL"
  type        = string
  sensitive   = true
}