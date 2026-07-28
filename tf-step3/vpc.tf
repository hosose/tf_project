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
