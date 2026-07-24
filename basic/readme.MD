# 개요
- 기본 구성
- EC2 구성
- 문법

# 작업
## 기본 구성
- 기본 파일 생성
```powershell
# 파일 생성 코드
$path = "C:\Users\NT551_11TH\OneDrive\Desktop\workspace\tf_project\basic"; New-Item -ItemType Directory -Path $path -Force; 'provider.tf', 'main.tf', 'variables.tf', 'outputs.tf', 'terraform.tfvars', '.gitignore' | ForEach-Object { New-Item -ItemType File -Path (Join-Path $path $_) -Force }
```
```
provider.tf
main.tf
variables.tf
outputs.tf
terraform.tfvars
.gitignore
```

- provider.tf 작성

- 인프라구성 step1 : 테라폼 초기화 (init)
```powershell
terraform init
---
성공 후 결과물
-> .terraform
-> .terraform.lock.hcl : 프로바이더의 모듈의 정확한 버전, 해시값 잠금 -> 안정성, 자동생성 시 체킹 파일
```

- step2 : 문법 검사(체킹) (validate)
```
terraform validate
---
Success! The configuration is valid.
```

- step3 : 실행 계획 확인 (플래닝, 시뮬레이션)
```
terraform plan
---
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
--- 실제
provider -> resource(보안그룹, VPC, EIP,...) 생성 계획
```

- step4 : 적용(실제 생성) (apply)
```
terraform apply
--- (현재는 인프라 구성 내용 x)
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
---
실제 : ec2 경우 1~2분, 쿠버네티스 등 10분 이내 등등
```

- step 5 : 인프라 삭제 (destroy)
```
terraform destroy
--- (삭제된 것 없음, 만든 것이 없어서)
No changes. No objects need to be destroyed.

Either you have not created any objects yet or the existing objects were already deleted outside of Terraform.

Destroy complete! Resources: 0 destroyed.
```
## EC2 구성
### 최종 형태
```
Internet
     │
Elastic IP          <- 리소스 생성 후 주소 확인용으로 사용
     │
┌──────────────┐
│     EC2      │
│ AmazonLinux2 │    <- 아마존 리눅스 사용/ec2-user
└──────────────┘
     │
Security Group      <- 보안그룹 전용 생성/0.0.0.0/0 개방/인바운드(ssh-22), 아웃바운드(전체)
     │
VPC(Default)        <- 기본 VPC 사용, 별도 생성 x 

---
pem 파일, 스토리지, 리전, 이름, ... 
```