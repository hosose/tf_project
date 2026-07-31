########################################################
# tf 전체에서 사용할 변수 8개(컨셉) 정의
########################################################
variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "us-east-2"
}
variable "environment" {
  description = "구동 환경"
  type        = string
  default     = "dev"
}
variable "instance_type" {
  description = "WEB/WAS EC2 인스턴스 유형"
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
  description = "DB 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"
}
variable "db_name" {
  description = "초기 생성 DB 이름"
  type        = string
  default     = "appdb"
}
variable "db_username" {
  description = "RDS 관리자 이름"
  type        = string
  default     = "adminuser"
}
