# 구성 버전
## V1 
- infrastructure Enginnering : 운영 가능한 인프라 구축
```
Terraform -> Production AWS -> 3-tier -> Multi AZ(멀티존) -> ALB(어플리케이션 로드밸런서) -> ASG(오토스케일링그룹) -> RDS

SSM System Manager를 통해서 ec2에 접속 (pem 배제)
```

## V2
- Plafrom Enginnering : 컨테이너 플랫폼 구축 -> 쿠버네티스 기반으로 전체 재구성
```
Terraform -> EKS -> Container -> Deployment -> Serive -> ingress 
```

## V3
- Devops : CI/CD
```
Github -> GitAction/ArgoCD -> ECR -> EKS
```

## V4
- Obserability : 운영 및 모니터링
```
Prometheus -> Grafana -> Metrics -> Alert (슬랙등..)
```