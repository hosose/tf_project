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

variable "instance_type" {
  description = "WEB/WAS EC 인스턴스 유형"
  type        = string
  default     = "t3.micro"
}
variable "web_desired_capacity" {
  description = "WEB ASG 기본 인스턴스 수"
  type        = number
  default     = 2
}
variable "was_desired_capacity" {
  description = "WAS ASG 기본 인스턴스 수"
  type        = number
  default     = 2
}
variable "db_instance_class" {
  description = "DB 인스턴스 클레스"
  type        = string
  default     = "db.t3.micro"
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
