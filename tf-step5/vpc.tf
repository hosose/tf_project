# Vpc
resource "aws_vpc" "company_vpc" {
  # 65536개 IP
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "DE-AI-07-COMPANY"
  }
}

# Intervet Gateway

# Public Subnets - Public ALB, NAT Gateway

# Private Application Subnets - WEB, WAS internal ALB

# Private Database Subnets - RDS

# Public Route Table/Association

# NAT Gateway - eip

# Private App Route Table/Association - WEB, WAS

# Private DB Route Table/Association - RDS
