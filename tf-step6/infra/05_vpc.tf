# 전체 EKS/RDS 서비스가 들어갈 네트워크 구성
# ────────────────────────────────────────────────
# VPC
# ────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${local.cluster_name}-vpc"
  }
}

# ────────────────────────────────────────────────
# IGW
# ────────────────────────────────────────────────
# Intervet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.cluster_name}-igw"
  }
}

# ────────────────────────────────────────────────
# subnet
# ────────────────────────────────────────────────
# Public Subnets - Public ALB, NAT Gateway
resource "aws_subnet" "public" {
  #반복데이터 세팅 (cidr)
  for_each = local.public_subnets # 동적으로 구성된 az별 가용영역명, cidr 값

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.cluster_name}-public-${lower(each.key)}"
    # 쿠버네티스 관련
    # 쿠버네티스가 외부용 로드밸런서 서브넷으로 식별할 수 있도록 태그 구성
    # EKS Auto Mode 구성시 인터넷 접근이 가능한 로드밸런서 구성할 때 해당 서브넷 사용해도 좋다 라는 표식

    # 작동
    # EKS는 아래 태그 값을 가진 서브넷을 찾아서 인터넷 공개용 ALB등을 배치
    "kubernetes.io/role/elb" = "1"
  }
}


# Private Application Subnets - EKS Auto Mode 의 Nods/pod 등 배치
# 쿠버네티스가 해당 서브넷을 내부 적용 ALB등을 만들 때 해당 서브넷 사용하도록 하는 태그 표식 추가
resource "aws_subnet" "app" {
  #반복데이터 세팅 (cidr)
  for_each = local.app_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
  tags = {
    Name                              = "${local.cluster_name}-app-${lower(each.key)}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Private Database Subnets - RDS
resource "aws_subnet" "db" {
  #반복데이터 세팅 (cidr)
  for_each = local.db_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  map_public_ip_on_launch = false
  tags = {
    Name                              = "${local.cluster_name}-db-${lower(each.key)}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ────────────────────────────────────────────────
# NAT
# ────────────────────────────────────────────────
# AZ별 NAT Gateway에 연결할 고정 공인 - eip
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags = {
    Name = "${local.cluster_name}-nat-eip-${lower(each.key)}"
  }

  # 의존성 명시적 - igw가 반드시 구성되어 있어야 한다.
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id # IP를 가용영역별로 세팅
  subnet_id     = each.value.id            # 가용영역별 퍼블릿 서브넷
  tags = {
    Name = "${local.cluster_name}-nat-${lower(each.key)}"
  }
  depends_on = [
    aws_internet_gateway.main
  ]
}

# ────────────────────────────────────────────────
# Route Table/Association
# ────────────────────────────────────────────────

# Public Route Table/Association
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.cluster_name}-public-rt"
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

# Private App Route Table/association
resource "aws_route_table" "app" {
  #반복데이터 세팅 (cidr)
  for_each = aws_subnet.app
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = {
    Name = "${local.cluster_name}-app-rt-${each.key}"
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
  for_each = aws_subnet.db
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${local.cluster_name}-db-rt-${each.key}"
  }
}
resource "aws_route_table_association" "db" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db[each.key].id
}

