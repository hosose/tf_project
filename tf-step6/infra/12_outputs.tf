# ────────────────────────────────────────────────
# EKS 설정 관련 변수
# ────────────────────────────────────────────────
output "aws_region" {
  value = var.aws_region
}

output "cluster_name" {
  # 임시세팅
  value = local.cluster_name
}

# ────────────────────────────────────────────────
# VPC 설정 관련 변수
# ────────────────────────────────────────────────
output "public_subnets" {
  # 임시 세팅
  value = local.public_subnets
}
