##############################################
# Security Group Rules (반복관련)
##############################################
locals {
  security_groups = {
    web = {
      ingress = {
        ssh = {
          port = 22,           # 포트 값 표현
          cidr = ["0.0.0.0/0"] # n개 나올 수 있는 허가된 IP값 나열(리스트)
        }
        http = {
          port = 80,           # 포트 값 표현
          cidr = ["0.0.0.0/0"] # n개 나올 수 있는 허가된 IP값 나열(리스트)
        }
      }
    }
    was = {
      ingress = {
        ssh = {
          port = 22,           # 포트 값 표현
          cidr = ["0.0.0.0/0"] # n개 나올 수 있는 허가된 IP값 나열(리스트)
        }
        # 오직 web -> was 로만 접근해야함. 취지 벗어남 (다른 방식으로 구성)
        #   tcp = {
        #     port = 8000,         # 포트 값 표현
        #     cidr = ["0.0.0.0/0"] # n개 나올 수 있는 허가된 IP값 나열(리스트)
        #   }
      }
    }
    db = {
      ingress = {
        ssh = {
          port = 22,           # 포트 값 표현
          cidr = ["0.0.0.0/0"] # n개 나올 수 있는 허가된 IP값 나열(리스트)
        }

        # 오직 was -> db 로만 접근해야함. 취지 벗어남 (다른 방식으로 구성)
        # tcp = {
        #   port = 3306,         # 포트 값 표현
        #   cidr = ["0.0.0.0/0"] # n개 나올 수 있는 허가된 IP값 나열(리스트)
        # }
      }
    }
  }
}

##############################################
# Security Groups 생성 선언
##############################################
resource "aws_security_group" "sg" {
  # 반복 데이터로 구성한 locals 주입(세팅) -> web, was,db 총 3개의 멤버를 가짐
  for_each = local.security_groups
  # for_each에 Map 타입으로 주입 => each.key, each.value 형태로 반복적, 순서대로 획득
  # 이름 => DE-AI-07-web-SG, DE-AI-07-was-SG, DE-AI-07-db-SG
  name_prefix = "DE-AI-07-${each.key}-SG-"
  description = "${upper(each.key)} Security Group"

  # 보안 그룹은 VPC에 종속되어서 구성됨
  vpc_id = aws_vpc.DE-AI-07-COMPANY.id

  # ingress 동적 생성 => 블록 반복 구성 => dynamic ingress
  dynamic "ingress" {
    # 반복 데이터
    for_each = each.value.ingress
    content {
      protocol    = "tcp"              # 고정값
      from_port   = ingress.value.port # 80, 22
      to_port     = ingress.value.port # 80, 22
      cidr_blocks = ingress.value.cidr # ["0.0.0.0/0"]
    }
  }

  # 아웃바운드 고정
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "DE-AI-07-${each.key}-SG"
  }
}

##############################################
# Web -> Was 룰 적용, 포트 8000 오픈, 룰 생성 선언
##############################################
resource "aws_security_group_rule" "web-to-was" {
  type = "ingress"
  # 소스(web) 보안 그룹
  source_security_group_id = aws_security_group.sg["web"].id
  # 타겟(was) 보안 그룹
  security_group_id = aws_security_group.sg["was"].id
  # 포트
  from_port = 8000
  to_port   = 8000
  # 프로토콜
  protocol = "tcp"
}
##############################################
# Was -> Db 룰 적용, 포트 3306 오픈, 룰 생성 선언
##############################################
resource "aws_security_group_rule" "web-to-db" {
  type = "ingress"
  # 소스(was) 보안 그룹
  source_security_group_id = aws_security_group.sg["was"].id
  # 타겟(db) 보안 그룹
  security_group_id = aws_security_group.sg["db"].id
  # 포트
  from_port = 3306
  to_port   = 3306
  # 프로토콜
  protocol = "tcp"
}
