# ────────────────────────────────────────────────
# 공통 환경 변수
# ────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "us-east-2"
}
variable "project_name" {
  description = "리소스명에 사용할 프로젝트명"
  type        = string
  default     = "de-ai-07-eks-auto"
}
variable "environment" {
  description = "구동 환경"
  type        = string
  default     = "dev"
}




variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}
variable "availability_zones" {
  description = "Multi-AZ 구성에 사용할 가용영역 2개"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2c"]
  # 유효성 검사 표기
  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "본 구성은 정확하게 2개의 가용영역을 사용합니다."
  }
}
variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "app_subnet_cidrs" {
  description = "EKS Auto Mode Node/Pod용 프라이빗 서브넷 CIDR 목록"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}
variable "db_subnet_cidrs" {
  description = "RDS 전용 Private Subnet CIDR 목록"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

# ────────────────────────────────────────────────
# EKS 설정 관련 변수
# ────────────────────────────────────────────────
variable "kubernetes_version" {
  description = "EKS Kuberbnetes 버전"
  type        = string
  # 보수적으로 최신버전 바로 하위 버전 사용(현재 사용 컨셉상 최신 버전 문제 없음)
  default = "1.35"
}
variable "cluster_endpoint_public_access_cidrs" {
  description = "EKS Public API 접근 CIDR. 용도에 따라 제한할 수 있음"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
variable "addtional_admin_role_arns" {
  description = "EKS 추가 관리자 IAM ROLE ARN 목록"
  type        = set(string)
  default     = []
}

# ────────────────────────────────────────────────
# RDS 설정 관련 변수
# ────────────────────────────────────────────────
variable "db_instance_class" {
  description = "DB 인스턴스 클레스"
  type        = string
  default     = "db.t3.micro"
}
variable "db_allocated_storage" {
  description = "RDS 초기 스토리지 용량(GB)"
  type        = number
  default     = 20
}
variable "db_name" {
  description = "초기 생성 데이터베이스 이름"
  type        = string
  default     = "appdb"
}
variable "db_username" {
  description = "RDS 관리자 이름"
  type        = string
  default     = "adminuser"
}
