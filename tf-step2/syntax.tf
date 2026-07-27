variable "name" {
  # 문자열 타입
  default = "테라폼"
}
variable "age" {
  # 수치 타입
  default = 25
}
variable "is_mz" {
  # 불리언 타입
  default = true
}
variable "books" {
  # 리스트 타입
  default = ["1", "2"]
}
variable "stations" {
  # 맵 타입
  default = {
    A = "신도림",
    B = "사당",
  }
}

# 출력
output "name" {
  value = var.name
}

output "age" {
  value = var.age
}

output "is_mz" {
  value = var.is_mz
}

output "books" {
  value = var.books
}

output "stations" {
  value = var.stations
}


######################################
#tfvars 테스트
######################################
variable "environment" {
  type        = string
  default     = "dev"
  description = "배포 환경 (dev -> stage -> prod)"
}
variable "instance_count" {
  type        = number
  default     = 1
  description = "생성할 인스턴스 개수"
}

output "environment" {
  value = var.environment
}
output "instance_count" {
  value = var.instance_count
}
