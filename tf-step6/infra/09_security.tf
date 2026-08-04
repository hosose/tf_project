# ────────────────────────────────────────────────
# RDS 보안그룹
# ────────────────────────────────────────────────
resource "aws_security_group" "rds" {
  # 보안 그룹 이름
  name = "${local.cluster_name}-rds-sg"
  # eks 클러스터에서만 rds에 접근 가능
  description = "Mysql access only from eks cluster sg"
  # vpc
  vpc_id = aws_vpc.main.id

  # 인바운드
  ingress {
    description = "MySQL from EKS Auto Mode Node and WAS Pods"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # EKS 자동 생성한 보안그룹 (auto mode로 인해, vpc config 구성에 의해 구성) 아니면 sg 생성해야함
    security_groups = [
      aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
    ]
  }

  # 아웃바운드
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.cluster_name}-rds-sg"
  }
}
