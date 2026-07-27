# 1. 현재 리전의 VPC 서비스 중 default 정보 조회 ( data )
#    - 현재 리전의 VPC 서비스 중 default 정보 조회 하라 -> data.aws_vpc.default.id 참조
data "aws_vpc" "default" {
  default = true
}

# 2. 기본 VPC의 서비스 정보 조회 하라 (data)
#    n개의 서브넷이 존재하므로 이를 values에 담아라
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 3. 보안그룹 생성 선언 - EC2 진입 하는데 인바운드 IP/포트, 아웃바운드 IP/포트 설정 => 접근 제한!!
resource "aws_security_group" "DE-AI-07-IaC-TF-GROUP" {
  # 메타 정보
  name = "terraform-07-sg2"
  # ASCII만 지원
  description = "de-ai-07 security group"
  # 보안 그룹은 VPC에 종속되어서 구성됨
  # id => 리소스명-해시값(중복x, 고유값)
  vpc_id = data.aws_vpc.default.id
  # 인바운드   (외부 트레픽이 내부로 들어옴) -> 일단 필요한 만큼 생성 -> 추후 반복문?등 문법효율적 활용을 통해 구성
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    description = "SSH"
    # 0.0.0.0/0 => 각자리가 256개 표현(0~255).().().()/앞에서부터 고정값(비트수:0,8,16,24,32)
    # 256*256*256*256 개 주소 표현
    # 10.0.0.0/8 => 맨 앞에 1자리는 고정 => 10은 고정 나머지 3자리에서 모두 가능 => 256*256*256 주소 가능함
    # 0.0.0.0/0 => Anywhere IPV4 (전세계 어디서든 접근 가능 -> 보안에 좋진 않다)
    # 222.108.125.33/32 => 오직 이 IP만 접속 가는함!! ~/32(4자리 모두 고정)
    cidr_blocks = ["222.108.125.33/32"]
  }
  ingress { # HTTP 구성 실습
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"] # 전세계로 개방
  }
  # 아웃바운드 (내부 트레픽이 외부로 나감)
  egress {
    # 모든 프로토콜 개발
    protocol = "-1"
    # 모든 포트 개방
    from_port = 0
    to_port   = 0
    # 전세계로 개방
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 아마존 리눅스 AMI의 ID 조회
data "aws_ami" "amazon_linux" {
  # 최신 설정
  most_recent = true
  # 소유자
  owners = ["amazon"]
  # 필터링
  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
  # 프리티어를 사용할려면 필터를 추가해야함 -> ec2에서 인스턴스 유형이 t2/t3.micro등 선택되어야 확정됨
  # 필터 추가
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 4. EC2 생성 선언
resource "aws_instance" "DE-AI-07-IaC-TF" {
  # AMI -> OS
  ami = data.aws_ami.amazon_linux.id
  # 인스턴스 유형
  instance_type = var.instance_type
  # 키 페어
  key_name = var.key_name
  # 서브넷
  subnet_id = data.aws_subnets.default.ids[0] # a,b,c,d중 첫번재 선택(a)
  # 보안그룹
  vpc_security_group_ids = [
    aws_security_group.DE-AI-07-IaC-TF-GROUP.id
  ]
  # 스토리지 생략
  # 고급 설정 생략
  # 태그
  tags = {
    Name = "DE-AI-07-IaC-TF-EC2"
  }
  # IP는 임시로 자동할당 (현재 EIP 사용 x)

  # TODO: 동일 스펙으로 2개 생성
  count = 2
}

# 5. Elastic IP 생성 선언 -> EC2 연결 (차후 IP를 미리 확보하고 ec2 생성되면 연결하는 방식 진화)
# resource "aws_eip" "DE-AI-07-IaC-TF-EIP" {
#   # TODO: 인스턴스 2개 => EIP 2개
#   count = 2

#   # TODO: EC2 인스턴스[ count.index ] => 순서대로 세팅되게 구성
#   instance = aws_instance.DE-AI-07-IaC-TF[ count.index ].id
#   # 네트워크
#   domain = "vpc"
# }
