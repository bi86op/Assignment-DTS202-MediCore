# MediCore Virtual Private Cloud
resource "aws_vpc" "medicore" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "medicore-vpc"
    Tier = "Network"
  }
}

# Internet Gateway for public internet connectivity
resource "aws_internet_gateway" "medicore" {
  vpc_id = aws_vpc.medicore.id

  tags = {
    Name = "medicore-igw"
    Tier = "Network"
  }
}


# Public subnets
# Public subnet - Availability Zone A

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "medicore-public-subnet-a"
    Tier = "Public"
  }
}

# Public subnet - Availability Zone B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "medicore-public-subnet-b"
    Tier = "Public"
  }
}

# Public subnet - Availability Zone C
resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "medicore-public-subnet-c"
    Tier = "Public"
  }
}


# Private application subnets
# Private application subnet - Availability Zone A

resource "aws_subnet" "private_app_a" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "medicore-private-app-subnet-a"
    Tier = "Application"
  }
}

# Private application subnet - Availability Zone B
resource "aws_subnet" "private_app_b" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "medicore-private-app-subnet-b"
    Tier = "Application"
  }
}

# Private application subnet - Availability Zone C
resource "aws_subnet" "private_app_c" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.13.0/24"
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "medicore-private-app-subnet-c"
    Tier = "Application"
  }
}


# Restricted database subnets
# Restricted database subnet - Availability Zone A

resource "aws_subnet" "private_db_a" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.21.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "medicore-private-db-subnet-a"
    Tier = "Database"
  }
}

# Restricted database subnet - Availability Zone B
resource "aws_subnet" "private_db_b" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.22.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "medicore-private-db-subnet-b"
    Tier = "Database"
  }
}

# Restricted database subnet - Availability Zone C
resource "aws_subnet" "private_db_c" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = "10.0.23.0/24"
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "medicore-private-db-subnet-c"
    Tier = "Database"
  }
}

# Public routing

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.medicore.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.medicore.id
  }

  tags = {
    Name = "medicore-public-route-table"
    Tier = "Public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}