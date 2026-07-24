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
## EC2 구성