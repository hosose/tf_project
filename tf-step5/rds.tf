############################################
# RDS Subnet Group - 서로 다른 AZ의 DB 서브넷 사용
############################################
resource "aws_db_subnet_group" "main" {
  name       = "de-ai-07-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.db : subnet.id]

  tags = { Name = "${local.project}-DB-SUBNET-GROUP" }
}

############################################
# RDS MySQL Multi-AZ
# manage_master_user_password=true:
# 비밀번호를 코드에 저장하지 않고 AWS Secrets Manager가 관리
############################################
resource "aws_db_instance" "mysql" {
  identifier = "de-ai-07-mysql-v1"

  engine         = "mysql"
  instance_class = var.db_instance_class

  allocated_storage     = 20
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

  tags = { Name = "${local.project}-MYSQL" }
}

