# ────────────────────────────────────────────────
# RDS Subnet Group - 서로 다른 AZ의 DB 서브넷 사용
# ────────────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name = "${local.cluster_name}-db-subnet-group"
  # a존, c존 프라이빗 서브넷 설정
  subnet_ids = values(aws_subnet.db)[*].id

  tags = { Name = "${local.cluster_name}-db-subnet-group" }
}

# ────────────────────────────────────────────────
# RDS MySQL Multi-AZ
# manage_master_user_password=true:
# 비밀번호를 코드에 저장하지 않고 AWS Secrets Manager가 관리
# ────────────────────────────────────────────────
resource "aws_db_instance" "mysql" {
  identifier = "${local.cluster_name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  # 기본 저장공간 20gb, 최대 100gb, gp3타입 사용, 암호화 사용
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  multi_az               = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  backup_window           = "18:00-19:00"
  maintenance_window      = "sun:19:00-sun:20:00"

  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = { Name = "${local.cluster_name}-mysql" }
}

