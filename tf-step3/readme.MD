# 목표
- 회사 전용으로 클라우드 내 네트워크 구축 -> VPC
- 현재 EC2는 defaults VPC 사용 -> 전용 VPC로 직접 생성하여 적용
- [v]VPC만 구축
    -> EC2에 커스텀 VPC 연결하여 인프라 구성
    -> web(public subnet), was/db(private subnet) 확장 + NAT gateway, SSH Manager, IAM Role
    -> 소스코드, 쿠버네티스, CI/CD
    -> 대시보드 (그라파타, 프로메테우스, ...)

# 구성
    - AWS
        - VPC
        - CIDR
        - Public/Private Subnet
        - Internet Gateway
        - NAT Gateway
        - Route Table/Route Table Association
        - ...

# VPC (Virtual Private Cloud)
## 정의
- AWS(클라우드 생태계) 안에 내가(개인/기업) `직접 만드는 사설 네트워크`
- AWS 안에 나만(개인/기업) 사용하는 독립된(격리된) 네트워크 공간

## 현실세계 비유
- aws : 도시/국가(생태계)
- vpc : 수많은 아파트 단지 (클라우드 관점 : 개인/회사 단독 사용)
- subnet : 동(101동, 102동,...)
- EC2 : 각 집(세대, 101호, 102호...)
- Internet Gateway : 아파트 정문(외부 통신 가능, 트래픽 나가고, 들어오고 가능)
    - Subnet은 public 형태(개방)
- Route table : 안내 표지판 (주소, 길, 방향)
- Security Group : 각 세대(집) 현관문 (출입 통제 -> 포트/IP 제약(인바운드, 아웃바운드))
- NACL(Network Access Control List) : 아파트 동/단지 출입 통제(VPC를 위한 보안 계층)
-------------------------------
- NAT Gateway : 
    - Private Subnet을 위해서 구성
        - 외부에서 Private Subnet으로 들어올 수는 없음(보안)
        - s/w 설치를 해야하는 경우, 소스코드 획득 등 내부에서 외부의 자원을 가져올 필요가 있음(pull)
        - 이를 위해서 NATG 가 필요

## 구성원 1
### VPC
    - Default VPC
        - 리전별 n개 구성(통상 자동으로 만들어져 있음)
        - EC2 구성시 바로 사용 가능(퍼블릭 기본 세팅)
        - 학습, 테스트시 유용
        - 나만의 VPC X
    - [v]Custom VPC
        - 하위 구성원들 직접 구성(설계)
        - 운영환경 등 활용
        - 나만의 VPC O

### CIDR
    - VPC 구성 시 IP 주소 범위 지정
    ```
        # 설정
        10.0.0.0/16
        ---
        # 해석 : 앞에 16비트(2자리) 고정 / 뒤의 2자리만 커스텀 가능
        # 0 ~ 255 사용 가능 -> 256*256 조합 -> 가용한 IP는 65,536개까지 사용 가능(실제 예약값 존재함)
        10.0.0.10    -> OK
        10.0.1.10    -> OK
        10.0.255.254 -> OK

        10.1.0.10    -> X (앞의 2자리가 고정되어야 하는데 10.1로 바뀌었음)
    ```

### 서브넷
    - VPC를 작은 네트워크로 나눈것
        ```
            VPC
            10.0.0.0/16
            L Public   : 10.0.1.0/24
            L Private  : 10.0.2.0/24
            
            ---
            Public 대역
                - 앞의 3자리 고정 => 나올수 있는 IP의 가지수는 이론상 10.0.1.0 ~ 10.0.1.255 : 256개
                    - 2^(32-24)   => 가지수
                - AWS 예약 IP (5개) -> 사용 x
                    - 10.0.1.0 : 네트워크 주소
                    - 10.0.1.1 : AWS VPC 라우터 주소
                    - 10.0.1.2 : AWS DNS 서버 주소
                    - 10.0.1.3 : AWS 미래 사용을 위한 예약용 주소
                    - 10.0.1.255 : 브로드케스트 주소
                - 최종 : 사용 개수 256-5 = `251개 가용 가능한`

        ```
    - 종류
        - 퍼블릭 서브넷
            - 외부 인터넷과 직접 통신이 가능한 구역
            - 인터넷 게이트웨이로 향하는 라우트 경로가 존재
            - 외부에서 접속 가능한 퍼블릭 IP 가짐([*]web <-> was <-> db)
            - 배치 : web서버, ALB(로드밸런서), Bastion Host(private 서브넛 접속), ....
            ```
                Internet <-> IGW <-> Route Table <-> Public Subnet <-> EC2                    
            ```
        - 프라이빗 서브넷
            - 외부 인터넷 망과 격리되어 내부 통신만 가능한 안전한 구역
            - 외부에서 이 구역으로 접속 불가(모두 차단)
            - 단 NAT 게이트웨이를 통해서 외부로 나가는 통신 가능(Pull)
            - 배치 : EKS 워커노드(worker node), DB(RDS, 직접설치), 백엔드 서버(was)
            ```
                Internet                       X  Route Table <-> Public Subnet <-> EC2
                Internet  <-(pull) NAT Gateway <-> Route Table <-> Public Subnet <-> EC2
            ```

### 게이트웨이
    - 인터넷과 연결하는 문
        ```
            # 큰 틀
            인터넷 <-> IGW <-> VPC
        ```
    - 종류
        - IGW(Internet Gateway)
            - VPC와 인터넷 연결, 양방향, 관문
            - 퍼블릭 서브넷의 위치한 리소스(ec2등)와 인터넷간 데이터를 주고받을 수 있다
        - NAT Gateway
            - 프라이빗 서브넷의 위치한 리소스(ec등)에서 외부 인터넷의 데이터를 다운로드(라이브러이 업데이트, 도커 이미지 패치, ..)
            - 외부에서 프라이빗 네트워크 내부로 들어오는 접근은 완전 차단 (일방향)

### 라우팅 테이블
    - 네비게이션/이정표/안내
    - 패킷(데이터 요청/응답)이 어디로 갈지 결정하는 안내 표지판
        ```
            목적지         
            10.0.0.0/16     local
            0.0.0.0/0       IGW
        ```
    - `패킷`이 `목적지 IP를 찾아갈수 있도록 안내 규칙 집합`
    - 예)
        - 퍼블릭 - 라우팅 테이블 : 0.0.0.0/0 => IGW 보내라
        - 프라이빗 - 라우팅 테이블 : 0.0.0.0/0 => NAT Gateway 보내라

### 보안 방화벽
    - 구성
    ```
                [ Internet / External ]
                        │
                        ▼
            ┌──────────────────────────────┐
            │        Subnet Boundary       │
            │   ┌──────────────────────┐   │
            │   │ Network ACL (NACL)   │ ⬅️ 1차 검문 (Stateless, 서브넷 단위)
            │   └──────────┬───────────┘   │
            │              │               │
            │              ▼               │
            │   ┌──────────────────────┐   │
            │   │ Security Group (SG)  │ ⬅️ 2차 검문 (Stateful, 인스턴스/ENI 단위)
            │   └──────────┬───────────┘   │
            │              │               │
            │              ▼               │
            │   ┌──────────────────────┐   │
            │   │     EC2 Instance     │ ⬅️ 최종 도착지
            │   └──────────────────────┘   │
            └──────────────────────────────┘
    ```
    - 보안 그룹 (Security Group)
        - 대상 : EC2 인스턴스, EKS 노드 단위, POD 대상
        - 특징 : 허용/허가(allow) 규칙 설정, 기본적 모든 트레픽 차단, 필요한 것만 개방
        - 종류 : 인바운드, 아웃바운드
    - 네트워크 ACL(NACL)
        - 대상 : 서브넷 전체 단위에 적용되는 방화벽
        - 특징 : 허용(allow), 거부(deny) 규칙 모두 설정 가능

# 망구성
## 개발, 운영, 테스트등 분리 전략
```
AWS
 ├── VPC-A (개발)
 │      ├── EC2
 │      ├── RDS
 │      └── ALB
 │
 ├── VPC-B (운영)
 │      ├── EC2
 │      └── RDS
 │
 └── VPC-C (테스트)
```

## 일반적 구성(용도제외, 요소별 구성)
```
                  Internet
                      │
              Internet Gateway
                      │
               ┌──────────────┐
               │     VPC      │
               │10.0.0.0/16   │
               └──────────────┘
                 │          │
        ┌────────┘          └────────┐
        │                            │
 Public Subnet                 Private Subnet
10.0.1.0/24                   10.0.2.0/24
        │                            │
      EC2(Web)                   EC2(DB, WAS)
        │                            │
    Public IP                    Private IP
```

## 게이트웨이 포함 패킷 이동
```
+-----------------------------------------------------------------------------------+
| AWS Cloud (ap-northeast-2 : 서울 리전)                                             |
|                                                                                   |
|  [ VPC: 10.0.0.0/16 ] (가상 네트워크 )                                              |
|                                                                                   |
|   +---------------------------------------+ +----------------------------------+  |
|   | Public Subnet (10.0.1.0/24)           | | Private Subnet (10.0.101.0/24)   |  |
|   | (외부 공개 구역)                        | | (내부 보안 구역)                   |  |
|   |                                       | |                                  |  |
|   |  [ ALB / Bastion ]                    | |  [ EKS Worker Node / DB ]        |  |
|   +---------------------------------------+ +----------------------------------+  |
|                       |                                      |                    |
|                       | (직접 연결)                           | (NAT 통해 출구만 연결)|
|                       v                                      v                    |
|             [ Internet Gateway ]                    [ NAT Gateway ]               |
|                      |                                       |                    |
+----------------------+---------------------------------------+--------------------+
                       |                                       |
                       +------------------[ 인터넷  ]------------+
```


# 테라폼을 이용한 Custom VPC 구성, company-vpc
## VPC 구성
- ~/tf-step3/vpc.tf 생성
    - 작성
    - terraform init
    - terraform plan
    - terraform apply

## 서브넷 구성 (public)
- 작성
```
terraform apply
---
..
---
terraform state list
---
aws_subnet.public
aws_vpc.DE-AI-07-company
```

## Internet Gateway 
- 작성
- 생성
- 확인

## Route Table
- Route Table 생성

## Route Table 연결
- subnet과 igw를 연결

## 실습
### 목표
    - basic에서 작성한 ec2 Iac 코드를 가져와서 vpc, 서브넷 포지션을 vpc.tf로 만들어진 내용으로 연결
    - 테라폼으로 Custom VPC 사용하는 EC2 구성
    - public subnet에 EC2 배치
    - Security group 회사 VPC에 맞게 수정(22, 80)
    - EIP X

### 구성도
```
            Internet
                │
            Internet Gateway
                │
      ┌─────────────────────────┐
      │      Company VPC        │
      │     10.0.0.0/16         │
      │                         │
      │  Public Subnet          │
      │   10.0.1.0/24           │
      │        │                │
      │     EC2 + EIP(x)        │
      └─────────────────────────┘
```
```

[ AWS Region: ap-northeast-2 (서울) ]
────────────────────────────────────────────────────────────────────────────────────────────

 1️⃣ 새로 생성한 네트워크 (New VPC Environment)
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │ aws_vpc.DE-AI-07-COMPANY (CIDR: 10.0.0.0/16)                                           │
 │                                                                                        │
 │  ┌──────────────────────────────────────────────┐       ┌───────────────────────────┐  │
 │  │ aws_subnet.public                            │       │ aws_internet_gateway      │  │
 │  │ (CIDR: 10.0.1.0/24, AZ: ap-northeast-2a)     │       │ .company                  │  │
 │  │                                              │       └─────────────┬─────────────┘  │
 │  │                                              │                     │                │
 │  └──────────────────────┬───────────────────────┘                     │                │
 │                         │                                             │ (Internet)     │
 │                         │ (연결/Association)                           │                │
 │                         ▼                                             ▼                │
 │  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
 │  │ aws_route_table.public                                                           │  │
 │  │   └── Route: 0.0.0.0/0 ──────────────────────────────────────────────────────────┘  │
 │  └──────────────────────────────────────────────────────────────────────────────────┘  │
 └────────────────────────────────────────────────────────────────────────────────────────┘

 2️⃣ 기존 Default VPC 기반 EC2 및 보안/IP 설정 (EC2 Instance & Security)
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │ data.aws_vpc.default (기존 Default VPC)                                                 │
 │                                                                                        │
 │  ┌───────────────────────────────────────┐                                             │
 │  │ aws_security_group.DE-AI-07-IaC-TF-SG │                                             │
 │  │   ├── Inbound: SSH (22), HTTP (80)    │                                             │
 │  │   └── Outbound: All (0.0.0.0/0)       │                                             │
 │  └───────────────────┬───────────────────┘                                             │
 │                      │                                                                 │
 │                      ▼ (적용)                                                           │
 │  ┌──────────────────────────────────────────────────┐      ┌────────────────────────┐  │
 │  │ aws_instance.DE-AI-07-IaC-TF-EC2                 │◄─────┤ aws_eip                │  │
 │  │   ├── Type: t3.micro                             │(할당) │ .DE-AI-07-IaC-TF-EIP   │  │
 │  │   ├── Key: de-ai-07-rsa                          │      └────────────────────────┘  │
 │  │   ├── Subnet: subnet-049c8f72bb109a11e (Default) │                                  │
 │  │   └── AMI: data.aws_ami.amazon_linux             │                                  │
 │  └──────────────────────────────────────────────────┘                                  │
 └────────────────────────────────────────────────────────────────────────────────────────┘
```

### 작업
- VPC 교체 -> subnet 교체 -> 사용하느곳 모두 교체
- basic 코드 붙여넣기 -> main.tf, variable.tf, provider.tf, outputs.tf
- main.tf 에서 vpc, subnet 코드 삭제
- terraform plan > error > 수정위치가 나옴
```
│ Error: Reference to undeclared resource
│
│   on main.tf line 9, in resource "aws_security_group" "DE-AI-25-IaC-TF-GROUP":
│    9:   vpc_id = aws_vpc.DE-AI-25-company.id
│
│ A managed resource "aws_vpc" "DE-AI-25-company" has not been declared in the root module.
╵
╷
│ Error: Reference to undeclared resource
│
│   on outputs.tf line 6, in output "default_vpc_id":
│    6:   value       = data.aws_vpc.default.id
│
│ A data resource "aws_vpc" "default" has not been declared in the root module.
╵
╷
│ Error: Reference to undeclared resource
│
│   on outputs.tf line 11, in output "default_subnets_ids":
│   11:   value       = data.aws_subnets.default.ids
│
│ A data resource "aws_subnets" "default" has not been declared in the root module.
╵
╷
│ Error: Reference to undeclared resource
│
│   on outputs.tf line 30, in output "public_ip":
│   30:   value       = aws_eip.DE-AI-07-IaC-TF-EIP.public_ip
│
│ A managed resource "aws_eip" "DE-AI-07-IaC-TF-EIP" has not been declared in the root module.
╵
╷
│ Error: Reference to undeclared resource
│
│   on outputs.tf line 36, in output "instance_id":
│   36:   value       = aws_instance.DE-AI-07-IaC-TF-EC2.id
│
│ A managed resource "aws_instance" "DE-AI-07-IaC-TF-EC2" has not been declared in the root module.

 Error: Reference to undeclared resource
│
│   on outputs.tf line 6, in output "default_vpc_id":
│    6:   value       = data.aws_vpc.default.id
│
│ A data resource "aws_vpc" "default" has not been declared in the root module.
╵
╷
│ Error: Reference to undeclared resource
│
│   on outputs.tf line 11, in output "default_subnets_ids":
│   11:   value       = data.aws_subnets.default.ids
│
│ A data resource "aws_subnets" "default" has not been declared in the root module.
╵
╷
│ Error: Reference to undeclared resource
│
│   on outputs.tf line 36, in output "instance_id":
│   36:   value       = aws_instance.DE-AI-07-IaC-TF-EC2.id
│
│ A managed resource "aws_instance" "DE-AI-07-IaC-TF-EC2" has not been declared in the root module.
```
- 5. Elastic IP 생성 선언 주석 풀어줌
- outputs.tf에서 EIP의 퍼블릭 IP 출력로 표기
- terraform apply
- terraform graph 
    - 관계도 확인
    ```
        digraph G {
            rankdir = "RL";
            node [shape = rect, fontname = "sans-serif"];
            "data.aws_ami.amazon_linux" [label="data.aws_ami.amazon_linux"];
            "aws_eip.DE-AI-25-IaC-TF-EIP" [label="aws_eip.DE-AI-25-IaC-TF-EIP"];
            "aws_instance.DE-AI-25-IaC-TF" [label="aws_instance.DE-AI-25-IaC-TF"];
            ...
    ```


# 내일 목표시스템
- private 서브넷 구성
- 3-tier 구성
- NAT Gateway 배치
```
                    Internet
                        │
                Internet Gateway
                        │
                Public Route Table
                        │
      ┌─────────────────┴─────────────────┐
      │                                   │
 Public Subnet (10.0.1.0/24)        Private Subnet (10.0.2.0/24) <- ssm Manager 방식
      │                                   │
      │                                   │
 ┌────────────┐                    ┌────────────┐
 │ Web EC2    │                    │ DB EC2     │
 │ nginx      │     -(SSH)->       │ mysql      │
 └────────────┘                    └────────────┘
                                          │
                                    ┌────────────┐
                                    │ WAS EC2    │
                                    │ FastAPI    │
                                    └────────────┘
                                          
```       