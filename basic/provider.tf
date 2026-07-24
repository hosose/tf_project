terraform {
  required_version = ">=1.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>6.0"
    }
  }
}

provider "aws" {
    region = "ap-northeast-2"  
}
# 공급자 설명, 버전
# AWS Provider 버전 설명, 서울 리전 지정
# 변수가 없으므로 하드코딩 했음 => 리전