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
    Tier = upper("public")
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
    Tier = upper("application")
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
    Tier = upper("database")
  }
}

# Public Route Table/Association
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.project}-PUBLIC-RT"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway - eip
resource "aws_eip" "nat" {
  for_each = local.azs
  domain   = "vpc"
  tags = {
    Name = "${local.project}-NAT-EIP-${upper(each.key)}"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each      = local.azs
  allocation_id = aws_eip.nat[each.key].id       # ..nat['A']..., ..nat['C']... -> 가용영역별로 생성
  subnet_id     = aws_subnet.public[each.key].id # public 서브넷에 생성 -> public 서브넷의 cidr를 사용
  tags = {
    Name = "${local.project}-NAT-GW-${upper(each.key)}"
  }
  depends_on = [
    aws_internet_gateway.main
  ]
}

# Private App Route Table/association
resource "aws_route_table" "app" {
  for_each = local.azs
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = {
    Name = "${local.project}-APP-RT"
  }
}
resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app[each.key].id
}
# Private Db Route Table/association
# RDS 서비스 사용 -> 기존 EC2 기반 NAT 구성과 상이함
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.project}-DB-RT"
  }
}
resource "aws_route_table_association" "db" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db.id
}
