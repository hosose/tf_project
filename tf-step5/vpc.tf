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
resource "aws_subnet" "public" {
  #반복데이터 세팅 (cidr)
  for_each = local.public_subnets

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
  # 키 값이 a면 a에 맞는 값들로 구성, c도 동일함
  availability_zone = local.azs[each.key]

  map_public_ip_on_launch = true
  tags = {
    Name = "${local.project}-PUBLIC-${upper(each.key)}"
    # 커스텀 태그
    Tier = "public"
  }
}
# Private Application Subnets - WEB, WAS internal ALB
resource "aws_subnet" "app" {
  #반복데이터 세팅 (cidr)
  for_each = local.app_subnets

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
  # 키 값이 a면 a에 맞는 값들로 구성, c도 동일함
  availability_zone = local.azs[each.key]

  map_public_ip_on_launch = false
  tags = {
    Name = "${local.project}-APP-${upper(each.key)}"
    # 커스텀 태그
    Tier = "application"
  }
}

# Private Database Subnets - RDS
resource "aws_subnet" "db" {
  #반복데이터 세팅 (cidr)
  for_each = local.db_subnets

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
  # 키 값이 a면 a에 맞는 값들로 구성, c도 동일함
  availability_zone = local.azs[each.key]

  map_public_ip_on_launch = false
  tags = {
    Name = "${local.project}-DB-${upper(each.key)}"
    # 커스텀 태그
    Tier = "database"
  }
}

# Public Route Table/Association

# NAT Gateway - eip

# Private App Route Table/Association - WEB, WAS

# Private DB Route Table/Association - RDS
