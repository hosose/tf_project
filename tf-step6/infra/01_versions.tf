# 테라폼 CLI, AWS Provider 최소 호환 버전 고정
terraform {
  required_version = ">=1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}
