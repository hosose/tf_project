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

# locals
locals {
  project = "테라폼"
  env     = "pod"
  name    = "${local.project}-${local.env}-${var.environment}"
}
output "local_value" {
  value = local.name
}

# 함수 (다양한 함수 지원 -> 필요시 찾아서 사용)
output "upper" {
  value = upper(local.name)
}

# for_each
# 서비스별 인스턴스 유형 정의 리소스 구성 가정
# web : t3.micro, was:t3.small, db:t3.medium
locals {
  servers = {
    web : "t3.micro",
    was : "t3.small",
    db : "t3.medium",
  }
}
output "for_each_value" {
  value = local.servers
}

# resource "temp_spec" "server" {
#   # 반복적으로 구성될 데이터 세팅 -> 내부적으로 반복
#   for_each = local.servers
#   # 내부에서 자동처리 예시
#   input = {
#     name = each.key
#     type = each.value
#   }
# }
