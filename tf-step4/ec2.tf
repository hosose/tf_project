# 반복된 내용 locals 구성

# ami 조회
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
# aws_instance 생성 선언 -> 반복

# 오직 web용 EC2만 EIP 생성 선언
resource "aws_eip" "DE-AI-07-IaC-TF-EIP" {
  # EC2 인스턴스 
  instance = aws_instance..id
  # 네트워크
  domain = "vpc"
}
