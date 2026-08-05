# tf-step6 전체 파일 구조 및 학습 가이드 (File Structure & Learning Guide)

이 문서는 `tf-step6` 프로젝트의 모든 디렉터리와 파일을 하나하나 분석하여, **AWS EKS Auto Mode** 및 **3-Tier (WEB-WAS-RDS)** 클라우드 인프라 구축 흐름을 한눈에 이해하고 학습할 수 있도록 작성되었습니다.

---

## 1. 프로젝트 개요 (Overview)

`tf-step6` 프로젝트는 **Terraform(테라폼)**을 사용하여 AWS의 최신 **EKS Auto Mode** 클러스터, Multi-AZ VPC, ECR, RDS(MySQL) 인프라를 자동으로 생성하고, **Docker + Kubernetes(EKS)**를 통해 WEB(Nginx) / WAS(FastAPI) / DB(RDS) 3-Tier 아키텍처를 자동 배포하는 **완전 자동화(End-to-End) 학습용 예제 프로젝트**입니다.

---

## 2. 디렉터리 트리 (Directory Tree)

```text
tf-step6/
├── apply-all.bat            # Windows용 원클릭 전체 배포 자동화 스크립트
├── destroy-all.bat          # Windows용 전체 자원 일괄 삭제 스크립트
├── render_manifest.py       # K8s 템플릿(app.yaml.tpl) 변수 치환 파이썬 스크립트
├── readme.MD                # 프로젝트 메인 안내 및 실습 가이드 문서
├── 쿠버네티스구조_1.png       # 쿠버네티스 아키텍처 다이어그램 1
├── 쿠버네티스구조_2.png       # 쿠버네티스 아키텍처 다이어그램 2
├── .gitignore               # Git 버전 관리 제외 설정 파일
├── .terraform.lock.hcl      # 테라폼 프로바이더 버전 잠금 파일
│
├── infra/                   # 테라폼(Terraform) AWS 인프라 코드 디렉터리
│   ├── 01_versions.tf       # 테라폼 CLI 및 AWS Provider 최소 버전 설정
│   ├── 02_variables.tf      # 리전, VPC CIDR, EKS 버전, RDS 등 입력 변수 선언
│   ├── 03_locals.tf         # 공통 데이터 가공 (AZ별 서브넷 구조, 공통 태그)
│   ├── 04_provider.tf       # AWS Provider 초기화 및 기본 태그 설정
│   ├── 05_vpc.tf            # Multi-AZ VPC, 서브넷(6개), IGW, NAT GW, Route Table
│   ├── 06_iam.tf            # EKS Cluster Role & EKS Auto Mode Node Role 설정
│   ├── 07_logging.tf        # CloudWatch EKS 컨트롤 플레인 로그 그룹 생성
│   ├── 08_eks.tf            # EKS Auto Mode 클러스터, Addon, Access Entry 설정
│   ├── 09_security.tf       # RDS 전용 보안 그룹 (EKS 파드에서 3306 허용)
│   ├── 10_ecr.tf            # WEB/WAS ECR Repository & Lifecycle Policy (최근 10개 유지)
│   ├── 11_rds.tf            # RDS MySQL Multi-AZ 및 AWS Secrets Manager 연동
│   ├── 12_outputs.tf        # EKS 정보, ECR URL, RDS Endpoint, Kubeconfig 명령어 출력
│   └── terraform.tfvars     # 변수 실제 값 설정 파일
│
├── apps/                    # 애플리케이션 소스 코드 디렉터리
│   ├── was/                 # Backend WAS (FastAPI)
│   │   ├── app.py           # FastAPI 메인 로직 (Health Check, WAS Info, RDS 연동 테스트)
│   │   ├── Dockerfile       # Python 3.11-slim 기반 Docker 컨테이너 빌드 정의
│   │   └── requirements.txt # Python 패키지 의존성 (fastapi, uvicorn, pymysql)
│   │
│   └── web/                 # Frontend Web (Nginx + HTML)
│       ├── index.html       # WAS 및 DB 연동 결과를 보여주는 프론트엔드 UI 웹페이지
│       ├── nginx.conf       # 정적 파일 전달 및 `/api/` 요청 WAS 역프록시(Reverse Proxy) 설정
│       └── Dockerfile       # Nginx 메인 이미지 기반 Docker 컨테이너 빌드 정의
│
└── k8s/                     # 쿠버네티스(Kubernetes) 배포 매니페스트 디렉터리
    ├── app.yaml.tpl         # K8s 종합 배포 템플릿 (Ingress, Deployment, Service, HPA 등)
    └── app.yaml.MD          # K8s 배포 매니페스트 구조 및 EKS Auto Mode 특징 설명 문서
```

---

## 3. 루트 디렉터리 파일 상세 설명 (Root Directory)

### [apply-all.bat](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/apply-all.bat)
- **역할**: 프로젝트의 **전체 자동 배포 파이프라인**을 실행하는 Windows 배치 스크립트입니다.
- **주요 수행 단계 (총 7단계)**:
  1. `terraform apply`로 AWS 인프라(VPC, EKS, RDS, ECR) 자동 생성 후 Output 획득
  2. `aws eks update-kubeconfig`로 로컬 PC의 K8s 접속 인증 갱신 및 Metrics Server 헬스체크
  3. `docker build` & `docker push`로 WEB/WAS 애플리케이션 이미지를 AWS ECR 저장소로 푸시
  4. AWS Secrets Manager에서 RDS 암호를 가져와 K8s Secret(`rds-secret`) 자동 생성
  5. `render_manifest.py`를 호출하여 `app.yaml.tpl`의 환경변수를 치환하고 `kubectl apply`로 K8s 자원 배포
  6. WEB/WAS Deployment의 롤아웃 상태 완료 대기 (`kubectl rollout status`)
  7. 외부 서비스 접근용 AWS ALB Public DNS URL 출력

### [destroy-all.bat](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/destroy-all.bat)
- **역할**: 배포된 모든 AWS 인프라 및 쿠버네티스 자원을 안전하게 **일괄 삭제**하는 스크립트입니다.
- **주요 기능**:
  1. Terraform Output에서 리전과 EKS 클러스터 이름을 읽어옴
  2. K8s Namespace(`de-ai-07`)를 먼저 삭제하여 K8s가 자동 생성한 AWS ALB, TargetGroup 등의 종속 리소스를 정리
  3. `terraform destroy`를 통해 Terraform이 관리하던 AWS 인프라 전체 삭제

### [render_manifest.py](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/render_manifest.py)
- **역할**: 쿠버네티스 매니페스트 템플릿(`k8s/app.yaml.tpl`)을 동적으로 렌더링하는 Python 스크립트입니다.
- **동작 방식**:
  - 환경변수 `APP_NAMESPACE`, `WEB_IMAGE`, `WAS_IMAGE` 세 가지 필수 값이 설정되어 있는지 검증합니다.
  - Python `string.Template`을 이용해 `${WEB_IMAGE}`, `${WAS_IMAGE}`, `${APP_NAMESPACE}` 위치에 실제 ECR 주소와 네임스페이스 값을 주입한 후 표준 출력(stdout)으로 내보냅니다.

### [readme.MD](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/readme.MD)
- **역할**: 프로젝트의 메인 설명서 및 실습 가이드 문서입니다.
- **주요 내용**: EKS Auto Mode 개념, 아키텍처 개요, 네트워크 구성, 3-Tier 파드 구성 방식, 문제 해결(Troubleshooting) 방법이 상세히 설명되어 있습니다.

### [쿠버네티스구조_1.png](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/쿠버네티스구조_1.png) / [쿠버네티스구조_2.png](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/쿠버네티스구조_2.png)
- **역할**: EKS Auto Mode의 전체적인 AWS 네트워크 다이어그램 및 쿠버네티스 파드 배치/트래픽 흐름 시각화 이미지입니다.

---

## 4. `infra/` 디렉터리 상세 설명 (Terraform Infrastructure)

AWS cloud 자원을 생성하는 테라폼 선언문 모음입니다.

### [01_versions.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/01_versions.tf)
- Terraform CLI(>=1.10) 및 AWS Provider(~>6.0)의 최소 요구 버전을 명시하여 환경 호환성을 보장합니다.

### [02_variables.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/02_variables.tf)
- 인프라 구축에 필요한 모든 입력 변수를 선언합니다.
  - AWS 리전(`aws_region`), 프로젝트명(`project_name`), 환경(`environment`)
  - VPC CIDR (`10.0.0.0/16`), 가용영역 2개 (`us-east-2a`, `us-east-2c`)
  - Public Subnet (2개), App Subnet (2개), DB Subnet (2개) 대역
  - EKS 버전 (`1.35`), RDS 사양 (`db.t3.micro`, 초기 20GB, DB명 `appdb`)

### [03_locals.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/03_locals.tf)
- 입력 변수를 재가공하여 여러 테라폼 파일에서 반복 사용할 공통 데이터(Local values)를 정의합니다.
  - `cluster_name`: `${project_name}-${environment}` (예: `de-ai-07-eks-auto-dev`)
  - `public_subnets`, `app_subnets`, `db_subnets`: 가용영역(`a`, `c`) 키를 기준으로 CIDR과 AZ 정보를 맵으로 구조화
  - `common_tags`: 모든 AWS 리소스에 자동 할당될 공통 태그

### [04_provider.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/04_provider.tf)
- AWS 프로바이더를 설정하고, `default_tags`를 지정하여 `infra/`에서 생성되는 모든 AWS 자원에 프로젝트 태그가 자동 부착되도록 합니다.

### [05_vpc.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/05_vpc.tf)
- **AWS 네트워크 기초 인프라**를 구축합니다.
  - **VPC**: `10.0.0.0/16` 대역, DNS Hostname/Support 활성화
  - **Subnets (총 6개)**: 
    - Public Subnets (2개): ALB 및 NAT Gateway 배치용. 쿠버네티스 외부 ALB 작성을 위해 `"kubernetes.io/role/elb" = "1"` 태그 부여
    - Private App Subnets (2개): EKS 노드 및 파드 배치용. `"kubernetes.io/role/internal-elb" = "1"` 태그 부여
    - Private DB Subnets (2개): RDS MySQL 전용 서브넷
  - **Internet Gateway (IGW)**: Public 서브넷의 외부 인터넷 통신용
  - **NAT Gateways (2개)**: 각 AZ별 Public 서브넷에 EIP 1개씩을 할당하여 Private 서브넷 파드들의 아웃바운드 인터넷 접속 지원
  - **Route Tables**: Public/App/DB 서브넷별 라우팅 테이블 생성 및 서브넷 연결(Association)

### [06_iam.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/06_iam.tf)
- **EKS 관련 AWS IAM Role 및 Policy**를 생성합니다.
  - **EKS Cluster Role**: EKS 컨트롤 플레인이 컴퓨팅, 네트워킹, 로드밸런서, 블록 스토리지 리소스를 제어할 수 있도록 관리형 정책(`AmazonEKSClusterPolicy`, `AmazonEKSComputePolicy`, `AmazonEKSLoadBalancingPolicy` 등) 연결
  - **EKS Auto Mode Node Role**: EKS Auto Mode에 의해 자동으로 관리되는 EC2 노드들이 클러스터에 참여하고 ECR 이미지를 Pull 받을 수 있도록 정책(`AmazonEKSWorkerNodeMinimalPolicy`, `AmazonEC2ContainerRegistryPullOnly`) 바인딩

### [07_logging.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/07_logging.tf)
- EKS 컨트롤 플레인의 로그(API, Audit, Authenticator, ControllerManager, Scheduler)를 수집하기 위한 CloudWatch Log Group(`/aws/eks/.../cluster`)을 생성하고 7일 보관 주기를 설정합니다.

### [08_eks.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/08_eks.tf)
- **AWS EKS Auto Mode 핵심 클러스터**를 정의합니다.
  - `compute_config`: Auto Mode 노드 자동 관리(`enabled = true`) 및 노드 풀(`general-purpose`, `system`) 지정
  - `kubernetes_network_config`: Service IPv4 CIDR(`172.20.0.0/16`) 및 ELB 자동 감지 기능 활성화
  - `storage_config`: EBS 기반 블록 스토리지 자동 관리 활성화
  - `aws_eks_addon.metrics_server`: 파드 오토스케일링(HPA) 및 자원 모니터링을 위한 `metrics-server` 애드온 설치
  - `aws_eks_access_entry`: EKS Access Entry API 기반 추가 관리자 권한 할당 구성

### [09_security.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/09_security.tf)
- **RDS 전용 Security Group**을 정의합니다.
  - Ingress: EKS 클러스터 자동 생성 보안 그룹(Cluster SG)으로부터만 3306 포트(MySQL) 트래픽 인바운드 허용

### [10_ecr.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/10_ecr.tf)
- 도커 이미지를 저장할 **AWS ECR Repository** 2개(`.../web`, `.../was`)를 생성합니다.
  - `scan_on_push = true`: 이미지 푸시 시 알려진 보안 취약점 자동 검사
  - `aws_ecr_lifecycle_policy`: 저장소별로 최근 Push된 이미지 10개만 유지하고 오래된 이미지는 자동 만료/삭제하도록 설정

### [11_rds.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/11_rds.tf)
- **Multi-AZ MySQL RDS 인스턴스**를 구축합니다.
  - `manage_master_user_password = true`: DB 루트 암호를 코드에 하드코딩하지 않고 **AWS Secrets Manager가 자동으로 암호를 생성 및 관리**하도록 설정
  - `multi_az = true`: 가용영역 장애 대비 주/예비 DB 이중화 구성

### [12_outputs.tf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/12_outputs.tf)
- 인프라 생성 후 K8s 배포 및 앱 연결에 필요한 모든 핵심 동적 값(AWS Region, EKS Cluster Name, ECR Repositories URL, RDS Endpoint, Secrets Manager ARN, `kubectl update-kubeconfig` 명령어)을 Output으로 출력합니다.

### [terraform.tfvars](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/infra/terraform.tfvars)
- `02_variables.tf`에 선언된 기본값을 프로젝트 요구사항에 맞게 실제로 오버라이드하여 지정하는 파일입니다.

---

## 5. `apps/` 디렉터리 상세 설명 (Application Source)

### `apps/was/` (Backend Application)
- **[app.py](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/apps/was/app.py)**: Python FastAPI 기반 백엔드 애플리케이션
  - `/health`: 파드의 생존/준비 상태(Readiness/Liveness Probe) 체킹용 엔드포인트
  - `/api/info`: 프론트엔드와 WAS 간 내부 통신 테스트 (응답 파드의 Hostname을 반환하여 파드 로드밸런싱 확인)
  - `/api/db`: K8s Secret(`rds-secret`) 환경변수를 이용해 RDS MySQL에 접속하고, `request_counter` 테이블 생성/로그 기록 후 총 요청 횟수와 DB 시간을 반환
- **[Dockerfile](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/apps/was/Dockerfile)**: `python:3.11-slim` 기반 컨테이너 이미지 빌드 정의 (포트 8000 사용, uvicorn 실행)
- **[requirements.txt](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/apps/was/requirements.txt)**: 필요한 파이썬 라이브러리 목록 (`fastapi`, `uvicorn`, `pymysql`)

### `apps/web/` (Frontend Application)
- **[index.html](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/apps/web/index.html)**: 사용자 웹 브라우저 UI
  - WAS 호출 테스트 및 DB 연결 테스트 버튼 제공
  - 파드명, 응답 시간, DB 접속 상태 등을 시각적인 카드로 실시간 표시
- **[nginx.conf](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/apps/web/nginx.conf)**: Nginx 웹서버 설정
  - `/health`: Nginx 웹 서버 자체 헬스체크 (200 web-ok 반환)
  - `/api/`: K8s 내부 DNS인 `was-service:8000`으로 HTTP 역프록시(Reverse Proxy) 처리
  - `/`: 정적 HTML 웹페이지 (`index.html`) 서빙
- **[Dockerfile](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/apps/web/Dockerfile)**: `nginx:1.27-alpine` 기반 컨테이너 이미지 빌드 정의 (`index.html` 및 `nginx.conf` 복사)

---

## 6. `k8s/` 디렉터리 상세 설명 (Kubernetes Manifests)

### [app.yaml.tpl](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/k8s/app.yaml.tpl)
EKS Auto Mode에 3-Tier 앱을 배포하는 쿠버네티스 리소스 정의 템플릿입니다.

1. **IngressClass / IngressClassParams**:
   - EKS Auto Mode의 통합 AWS Application Load Balancer(ALB) 컨트롤러 사용을 정의 (`scheme: internet-facing`)
2. **Namespace**:
   - `${APP_NAMESPACE}` (기본값: `de-ai-07`) 독립 네임스페이스 격리 공간 생성
3. **WAS (Backend) Kubernetes Resources**:
   - `Deployment`: 파드 2개 생성. `topologySpreadConstraints`를 사용하여 **Multi-AZ 가용영역에 균등 분산 배치**
   - `Service`: ClusterIP 전용 서비스 (포트 8000), 내부 파드 간 통신
   - `PodDisruptionBudget (PDB)`: 노드 교체/노드 갱신 시 최소 1개 이상의 WAS 파드 가동 상태 유지 (`minAvailable: 1`)
   - `HorizontalPodAutoscaler (HPA)`: CPU 사용률 60% 초과 시 파드를 최대 6개까지 자동 증설
4. **WEB (Frontend) Kubernetes Resources**:
   - `Deployment`: 파드 2개 생성, Nginx 컨테이너 가동 (포트 80)
   - `Service`: ClusterIP 전용 서비스 (포트 80)
   - `PDB` & `HPA`: 최소 가동 보장 및 오토스케일링 설정
5. **Ingress (`public-alb`)**:
   - AWS Internet-Facing ALB를 생성하고, 외부인터넷 `/` 요청 트래픽을 `web-service:80`으로 포워딩

### [app.yaml.MD](file:///c:/Users/NT551_11TH/OneDrive/Desktop/workspace/tf_project/tf-step6/k8s/app.yaml.MD)
- `app.yaml.tpl` 매니페스트 내의 각 K8s 객체 종류별 설정값 및 EKS Auto Mode 연동 방식에 대해 상세히 정리해 둔 설명 문서입니다.

---

## 7. 학습 추천 경로 및 연동 흐름 (Learning Workflow)

1. **인프라 계층 학습 (`infra/`)**:
   - `05_vpc.tf` (네트워크 구조) $\rightarrow$ `06_iam.tf` / `08_eks.tf` (EKS Auto Mode) $\rightarrow$ `11_rds.tf` (Secrets Manager 연동 DB)
2. **애플리케이션 계층 학습 (`apps/`)**:
   - `apps/was/app.py` (FastAPI + PyMySQL) $\rightarrow$ `apps/web/nginx.conf` (Nginx Reverse Proxy)
3. **쿠버네티스 배포 계층 학습 (`k8s/`)**:
   - `k8s/app.yaml.tpl` (TopologySpread, Ingress, HPA, PDB 오케스트레이션)
4. **배포 자동화 흐름 학습 (`apply-all.bat` & `render_manifest.py`)**:
   - 테라폼 Output $\rightarrow$ Docker Build/Push $\rightarrow$ Secrets Manager 읽기 및 K8s Secret 생성 $\rightarrow$ Manifest 렌더링 $\rightarrow$ ALB 획득

---
*문서 생성 완료 - tf-step6 학습용 가이드*
