# 개요
- 테라폼 작성 주요 문법

# 준비
- syntax.tf 생성
    - 초기화
    ```
        terraform init
    ```

# 구성 절차
- 작성(init -> plan, validate, fmt, graph...)
- 실행(apply)
- 결과(output)
    - 결과값은 알파벳(사전)순으로 정렬
    - HCL(HashiCorp Configuration Language) 읽어서 -> 그래프 구성(DAG) -> 실행
        - 리소스간 의존성 계산(먼저 생성할 것들, 참조할 것들)
        - output은 map으로 관리(키,값)

# 변수
- 타입
```
string, number, bool, list, map, object
```

- 변수의 의미 (variables -> Input Variable vs `locals` (Local Values))
    - 목적: 재사용되는 값 변수로 정의하여 일괄관리, 외부에서 받아오는 입력값 대응
    - 재사용성(여러 리소스등에서 사용), 동적 설정(외부, `-var 옵션` or `.tfvars`)

- 외부 입력하여 수정
```
# 생성(수행) 단계에서 매개변수로 전달하여(외부) 변수값 수정
terraform apply -var="age=26" -var="is_mz=false"
```