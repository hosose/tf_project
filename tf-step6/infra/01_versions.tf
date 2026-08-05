# 테라폼 CLI, AWS Provider 최소 호환 버전 고정
# AWS Provider : 테라폼(Terraform)이 AWS(Amazon Web Services)와 소통할 수 있도록 연결해 주는 '공식 통역사(또는 플러그인)'
terraform {
  required_version = ">=1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}
