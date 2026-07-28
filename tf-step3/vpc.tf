# 특정 기업/개인/단체등 전용 VPC 생성 선언
resource "aws_vpc" "DE-AI-07-COMPANY" {
  # CIDR 규칙 지정 65536개 IP를 구성할수 있다. 10.0.0.0/16s
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "DE-AI-07-COMPANY"
  }
}

# 서브넷 (public)
resource "aws_subnet" "public" {
  # 암묵적 의존성 -> 서브넷 구성을 위해서는 반드시 vpc가 먼저 생성되어야함
  vpc_id = aws_vpc.DE-AI-07-COMPANY.id
  # CIDR 가용영역 설정, VPC보다 작게
  cidr_block = "10.0.1.0/24"
  # 리전마다 가용영역이 a,b,c,d or a,b,c 제한 => 데이터센터 동수
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "DE-AI-07-COMPANY-public-subnet"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "company" {
  # 암묵적 의존성 -> 게이트웨이 구성을 위해서는 반드시 vpc가 먼저 생성되어야함
  vpc_id = aws_vpc.DE-AI-07-COMPANY.id
  tags = {
    Name = "DE-AI-07-COMPANY-igw"
  }
}

# 라우트 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.DE-AI-07-COMPANY.id
  # 모든 IP 대역 => IGW 전달(연결)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.company.id
  }
  tags = {
    Name = "DE-AI-07-COMPANY-public-rt"
  }
}
