# 각종 정보 출력, 통상 terraform apply 수행의 결과를 출력하는 용도로 활용
# EC2 구성이라면 -> EIP 값, 인스턴스 값

# 임시코드, vpc, subnets 출력
output "default_vpc_id" {
  value       = aws_vpc.DE-AI-07-COMPANY.id
  description = "개인  VPC의 id"
}

output "default_subnets_ids" {
  value       = aws_subnet.public.id
  description = "개인 VPC의 서브넷 id"
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

# 퍼블릭 IP 출력
output "public_ip" {
  value       = aws_eip.DE-AI-07-IaC-TF-EIP.public_ip
  description = "EC2 퍼블릭 IP"
}

# EC2 인스턴스 ID 출력
output "instance_id" {
  value       = aws_instance.DE-AI-07-IaC-TF.id
  description = "EC2 인스턴스 ID"
}
