# 각종 정보 출력, 통상 terraform apply 수행의 결과를 출력하는 용도로 활용
# EC2 구성이라면 -> EIP 값, 인스턴스 값

# 임시코드, vpc, subnets 출력
output "default_vpc_id" {
  value       = data.aws_vpc.default.id
  description = "서울 리전의 기본 VPC의 id"
}

output "default_subnets_ids" {
  value       = data.aws_subnets.default.ids
  description = "서울 리전의 기본 VPC의 서브넷 ids"
}

# 현재 위치 확인 (~/basic)
# 출력결과 확인 (init -> plan -> 'apply' -> destroy 순서로 수행)

# 알파벳 순으로 출력된다 (작성 순서 무관)
output "aws_ami_amazon_linux_id" {
  value       = data.aws_ami.amazon_linux.id
  description = "아마존 리눅스 AMI 아이디 조회"
}
output "aws_ami_amazon_linux_info" {
  value       = data.aws_ami.amazon_linux
  description = "아마존 리눅스 AMI 아이디 조회"
}
