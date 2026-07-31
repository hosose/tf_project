#############################################
# WEB/WAS EC2를 각각 최소 2대 유지하도록 구성
# CPU 측정(트레픽 나름 비례) -> 50% 기준 설정(사내별 상이함) 
# -> Ec2의 개수를 증감(최대 4대(설정)까지):Scaling -> 자동(Auto) 처리
#############################################
# 증감 등 
resource "aws_autoscaling_group" "web" {
  name = "${local.project}-WEB-ASG"
  # 최소 크기 - 최소 2대는 상시 유지 -> 장애 발생 하더라도 2개로 맞춘다!!
  min_size = 2
  # 최초 디자인된 개수
  desired_capacity = var.web_desired_capacity
  # 최대 확장되는 개수
  max_size = 4

  # 두(n)개 서브넷의 가용 영역별로 구성
  vpc_zone_identifier = [for subnet in aws_subnet.app : subnet.id]
  # 로드밸런서 타겟 그룹 배치
  target_group_arns = [aws_lb_target_group.web.arn]
  # 헬스 체크 ELB(ALB)로 구성
  health_check_type = "ELB"
  # 서버구성후 180초 동안 헬스 체크 실패는 무시( 최초 구성시 로드, 업데이트등 정상 x)
  health_check_grace_period = 180

  # ec2를 launch_template 이용하여 구성하겠다 (상세 구성 내용-런치 템플릿(기존 ec2.tf))
  launch_template {
    # 커스텀으로 구성한 런치 탬플릿 참조
    id = aws_launch_template.web.id
    # 런치 템플릿의 최신버전
    version = "$Latest"
  }
  # 내용변경(버전변경) -> 교체(순차)
  instance_refresh {
    # 장애/업그레이드등 이슈로 교체시 -> 순차적 처리 -> (1개 신규 생성 -> 1개 삭제..)
    strategy = "Rolling"
    # 순차 교체 세부 조건
    preferences {
      # 최소 50% 성능 유지(헬스 체크등)
      min_healthy_percentage = 50
    }
  }
  # 태그 - 블록 반복 -> 기존태그(3개) + 신규 태그(2개) 합병하여 동적 eC2에 동적 세팅 샘플
  dynamic "tag" {
    # merge() 합병 - 기존태그(3개) + 신규 태그(2개) 합병
    for_each = merge(local.common_tags, {
      Name = "${local.project}-WEB"
      Tier = "web"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
resource "aws_autoscaling_group" "was" {
  name     = "${local.project}-WAS-ASG"
  min_size = 2
  # 초기 구성 개수 타겟
  desired_capacity    = var.was_desired_capacity
  max_size            = 4
  vpc_zone_identifier = [for subnet in aws_subnet.app : subnet.id]
  # alb 타겟 그룹 다름
  target_group_arns = [aws_lb_target_group.was.arn]
  health_check_type = "ELB"
  # 240초 동안 헬스 체크 오류는 무시. was가 구성상 더 시간이 소요됨
  health_check_grace_period = 240
  launch_template {
    # ec2 구성 상이
    id      = aws_launch_template.was.id
    version = "$Latest"
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  dynamic "tag" {
    for_each = merge(local.common_tags, {
      Name = "${local.project}-WAS"
      Tier = "was"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
# CPU 측정등
resource "aws_autoscaling_policy" "web_cpu" {
  name                   = "${local.project}-WEB-CPU-50"
  autoscaling_group_name = aws_autoscaling_group.web.name
  # 정책 타입 : 목표 추적 방식으로 스케일링 처리
  policy_type = "TargetTrackingScaling"
  # 설정 목표
  # 목적 : 설정된 지표가 목표값 근처에 유지되도록 ec2 수를 조정
  target_tracking_configuration {
    # 평가 기준
    predefined_metric_specification {
      # AWS 제공하는 지표 활용 => CPU 사용량
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    # 타겟값 50=> 평균 CPU 사용량 50% 높음(낮음) -> EC2 증가(감소) 자동 스케일링 진행
    # 2 ~ 4 사이에 구성
    target_value = 50
  }
}
resource "aws_autoscaling_policy" "was_cpu" {
  name                   = "${local.project}-WAS-CPU-50"
  autoscaling_group_name = aws_autoscaling_group.was.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}
