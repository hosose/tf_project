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

## EC2 구성