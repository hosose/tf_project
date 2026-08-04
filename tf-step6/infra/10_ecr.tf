# ────────────────────────────────────────────────
# WEB ECR 저장소
# ────────────────────────────────────────────────
resource "aws_ecr_repository" "web" {
  # 저장소 이름 "de-ai-25-eks-auto-dev/web"
  name = "${local.cluster_name}/web"

  # 이미지 태그
  # 같은 이미지 태그를 다시 push 할수 있다. -> 실습/개발할때 유용
  # 운영 환경에서는 버전번호, Commit ID등 을 활용하여 구분하는게 적절(안전)
  image_tag_mutability = "MUTABLE"

  # 테라폼 명령으로 destroy 실행시 이미지 부분 저장소와 함께 삭제할것인가?
  # 운영시에는 달라질수 있음
  force_delete = true

  # 이미지 push 할때 알려진 취약점들 자동 검사 처리
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.cluster_name}-ecr-web-repo"
  }
}

# ────────────────────────────────────────────────
# WAS ECR 저장소
# ────────────────────────────────────────────────
resource "aws_ecr_repository" "was" {
  name = "${local.cluster_name}/was"

  tags = {
    Name = "${local.cluster_name}-ecr-was-repo"
  }
}

# ────────────────────────────────────────────────
# ECR 저장소관련 Lifecycle Policy
# ────────────────────────────────────────────────
# 1. 위에서 생성한 저장소 한 묶음 구성
locals {
  aws_ecr_repositories = {
    web = aws_ecr_repository.web.name
    was = aws_ecr_repository.was.name
  }
}

# 2. 정책 : 태그와 상관ㅇ벗이 최근 push된 이미지 10개만 유지
#           오래된 이미지는 만료(CI/CD 적용이후 확인) -> 회사 상황에 따라 정책 다를 수 있음
resource "aws_ecr_lifecycle_policy" "main" {
  # 반복 데이터 (저장소 이름) 설정
  for_each = local.aws_ecr_repositories

  # 위 "for_each" 설정의 키 값을 현재 설정중인 리소스의 이름으로 사용
  repository = each.value

  # 정책 구성 => 현재 작성은 HCL 문법으로 작성 -> ECR의 요구사항 JSON 형태로 변환 구성
  policy = jsonencode({
    "rules" : [
      {
        # lifecycle 규칙 실행 우선순위
        "rulePriority" : 1,
        # 설명
        "description" : "Keep only the latest 10 images",
        # 선택
        "selection" : {
          # 태그 존재여부 상관없다. 모든 이미지 대상
          "tagStatus" : "any",
          # 기준
          "countNumber" : 10,
          # 저장된 이미지 개수가 기준을 초과하면 오래된 이미지를 제외 -> 최신순 
          "countType" : "imageCountMoreThan",
          "tagPrefixList" : [],
        },
        # 액션 : 만료 처리
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
}
