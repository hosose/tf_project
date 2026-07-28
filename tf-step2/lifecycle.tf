terraform {
  required_version = ">=1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}
provider "aws" {
  region = "ap-northeast-2"
}
data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "web" {
  # 이름 충돌 방지 처리
  # name_prefix ~ lifecycle 혼합으로 사용
  name_prefix = "web-sg-25-" # web-sg-25-해시값
  vpc_id      = data.aws_vpc.default.id
  lifecycle {
    create_before_destroy = true
  }
  # 최초는 아래 내용 없이 수행 -> 이후 주석 풀고 수행
  #   ingress { # HTTP 구성 실습
  #     protocol    = "tcp"
  #     from_port   = 80
  #     to_port     = 80
  #     description = "HTTP"
  #     cidr_blocks = ["0.0.0.0/0"] # 전세계로 개방
  #   }
}
