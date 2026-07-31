# Vpc
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${local.project}-VPC"
  }
}

# Intervet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.project}-IGW"
  }
}

# Public Subnets - Public ALB, NAT Gateway

# Private Application Subnets - WEB, WAS internal ALB

# Private Database Subnets - RDS

# Public Route Table/Association

# NAT Gateway - eip

# Private App Route Table/Association - WEB, WAS

# Private DB Route Table/Association - RDS
