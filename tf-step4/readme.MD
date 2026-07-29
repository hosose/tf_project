# 목표 시스템
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

# 리소스 구성
AWS
L VPC
    L Internet Gateway
        L public Route Table
            L Public Subnet
                L EC2 (Web) - SG (22, 80, 443) - EIP
    -------------------------------------------------
    L NAT Gateway
        L Private Route Table
            L Private Subnet
                L EC2 (Was) - SG (22, 8000)
                L EC2 (Db)  - SG (22, 3306)