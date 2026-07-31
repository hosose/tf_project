#################################
# public ALB : Internet <-> ALB <-> WEB ASG
#################################
resource "aws_lb" "public" {
  name               = "${local.project}-public-alb"
  internal           = false
  load_balancer_type = "application"
  # 보안그룹 - 퍼블릭 ALB
  security_groups = [aws_security_group.public_alb.id]
  # 퍼블릭 서브넷 2개 (가용영역별 a, c) 각각 id를 추출(리스트 컴프리핸션 방식 문법) 반영
  subnets = [for subnet in aws_subnet.public : subnet.id]
  tags    = { Name = "${local.project}-PUBLIC-ALB" }
}
# ALB가 주기적으로 대상 EC2의 상태를 체크하는 설정(헬스체크등)
resource "aws_lb_target_group" "web" {
  name        = "${local.project}-web-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  # 주기적으로 대상 EC2 점검 -> 요청 -> 응답에 대한 규칙 설정
  health_check {
    enabled             = true      # 헬스 체크 사용 여부
    path                = "/health" # 상태 체크하는 URL 값(경로)
    protocol            = "HTTP"    # 통신 방식
    matcher             = "200"     # 정상 응답 코드 값
    interval            = 30        # 헬스 체크 간격 (초)          
    timeout             = 5         # 응답 대기 시간 (초)
    healthy_threshold   = 2         # 연속 몇번(2번) 성공해야 정상 상태로 인지(상태변경)
    unhealthy_threshold = 2         # 연속 몇번(2번) 실패해야 비정상 상태로 인지(상태변경)
  }
  tags = { Name = "${local.project}-WEB-TG" }
}
# ALB가 80포트로 받은 HTTP 요청을 web target_group으로 전달하도록 설정(리슨)
# 아래 구성을 통해서 헬스 체크가 작동됨
resource "aws_lb_listener" "public_http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

#################################
# internal ALB : WEB ASG <-> Internal ALB <-> WAS ASG
#################################
resource "aws_lb" "internal" {
  name               = "${local.project}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  # APP 프라이빗 서브넷 2개 (가용영역별 a, c) 각각 id를 추출(리스트 컴프리핸션 방식 문법) 반영
  subnets = [for subnet in aws_subnet.app : subnet.id]
  tags    = { Name = "${local.project}-INTERNAL-ALB" }
}
# was 직접 점검 => 8000번 접속, 모두 상위 설정값과 동일
resource "aws_lb_target_group" "was" {
  name        = "${local.project}-was-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = { Name = "${local.project}-WAS-TG" }
}
# 포트제외, 대상제외 구성 모두 동일함
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 8000
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.was.arn
  }
}
