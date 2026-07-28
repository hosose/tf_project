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
            ```
                Internet <-> IGW <-> Route Table <-> Public Subnet <-> EC2                    
            ```
        - 프라이빗 서브넷
            ```
                Internet                       X  Route Table <-> Public Subnet <-> EC2
                Internet  <-(pull) NAT Gateway <-> Route Table <-> Public Subnet <-> EC2
            ```