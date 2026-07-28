variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 키 페어 이름"
  type        = string
  default     = "de-ai-07-rsa"
}
# 리전, 인스턴스유형, 키이름 변수로 지정 -> 다른 tf에서 사용 가능
