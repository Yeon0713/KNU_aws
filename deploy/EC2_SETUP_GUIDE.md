# 🚀 EC2 인스턴스 생성 및 배포 가이드

## 1단계: AWS 콘솔에서 EC2 인스턴스 생성

### 1.1 EC2 대시보드 접속
1. [AWS 콘솔](https://console.aws.amazon.com) 로그인
2. 리전을 **서울 (ap-northeast-2)** 로 설정
3. "EC2" 검색 후 클릭
4. "인스턴스 시작" 버튼 클릭

### 1.2 인스턴스 설정
- **이름**: `knu-health-backend`
- **AMI**: 
  - **Ubuntu**: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type (추천)
  - **Amazon Linux**: Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
- **인스턴스 유형**: t3.medium (2 vCPU, 4GB RAM)
- **키 페어**: 새로 생성하거나 기존 키 사용

### 1.3 보안 그룹 설정 (중요!)
**새 보안 그룹 생성**:
- 보안 그룹 이름: `knu-health-sg`
- **인바운드 규칙**:
  - SSH (22): 내 IP
  - HTTP (80): 0.0.0.0/0
  - HTTPS (443): 0.0.0.0/0
  - **사용자 지정 TCP (8000): 0.0.0.0/0** ← 이것이 중요!

### 1.4 사용자 데이터 (User Data)
**고급 세부 정보** → **사용자 데이터**에 다음 입력:

**Ubuntu용**:
```bash
#!/bin/bash
apt update -y
apt install -y git python3 python3-pip
cd /home/ubuntu
git clone https://github.com/yun-yeo-heon/KNU_aws.git
chown -R ubuntu:ubuntu KNU_aws
echo "EC2 초기 설정 완료" > /tmp/setup.log
```

**Amazon Linux용**:
```bash
#!/bin/bash
yum update -y
yum install -y git python3 python3-pip
cd /home/ec2-user
git clone https://github.com/yun-yeo-heon/KNU_aws.git
chown -R ec2-user:ec2-user KNU_aws
echo "EC2 초기 설정 완료" > /tmp/setup.log
```

## 2단계: 인스턴스 접속 및 배포

### 2.1 SSH 접속
```bash
# 키 파일 권한 설정
chmod 400 your-key.pem

# Ubuntu 인스턴스 접속
ssh -i your-key.pem ubuntu@YOUR_PUBLIC_IP

# 또는 Amazon Linux 인스턴스 접속
ssh -i your-key.pem ec2-user@YOUR_PUBLIC_IP
```

### 2.2 배포 스크립트 실행
```bash
cd KNU_aws

# Ubuntu용 배포 스크립트
./deploy/ec2-deploy-ubuntu.sh

# 또는 Amazon Linux용 배포 스크립트
./deploy/ec2-deploy.sh
```

### 2.3 AWS 자격 증명 설정
```bash
cd senior_supplement/backend
nano .env
```

**.env 파일 내용**:
```
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_REGION=ap-northeast-2
BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0
BEDROCK_REGION=us-east-1
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
DEBUG=False
ENVIRONMENT=production
```

### 2.4 서비스 재시작
```bash
sudo systemctl restart knu-health
sudo systemctl status knu-health
```

## 3단계: 배포 확인

### 3.1 서버 상태 확인
```bash
# 브라우저에서 접속
http://YOUR_PUBLIC_IP:8000/api/health

# 또는 curl로 테스트
curl http://YOUR_PUBLIC_IP:8000/api/health
```

**예상 응답**:
```json
{
  "status": "healthy",
  "aws_connected": true,
  "message": "모든 시스템이 정상 작동 중입니다."
}
```

### 3.2 로그 확인
```bash
# 실시간 로그 확인
sudo journalctl -u knu-health -f

# 최근 로그 확인
sudo journalctl -u knu-health --no-pager
```

## 4단계: Flutter 앱 API URL 업데이트

EC2 퍼블릭 IP를 확인한 후, Flutter 앱의 API URL을 업데이트해야 합니다.

**파일**: `knu_flutter_app/lib/services/api_service.dart`
```dart
// 기존
static const String baseUrl = 'http://10.111.28.35:8000';

// 변경
static const String baseUrl = 'http://YOUR_EC2_PUBLIC_IP:8000';
```

## 5단계: 문제 해결

### 포트 8000 접속 안 됨
```bash
# Ubuntu - UFW 방화벽 확인
sudo ufw status
sudo ufw allow 8000

# Amazon Linux - iptables 확인
sudo iptables -L
sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT

# 서비스 상태 확인
sudo systemctl status knu-health
```

### AWS Bedrock 권한 오류
```bash
# Ubuntu/Amazon Linux 공통 - AWS CLI 설치 및 설정
# Ubuntu
sudo apt install -y awscli

# Amazon Linux
sudo yum install -y awscli

# AWS 설정
aws configure

# Bedrock 권한 테스트
aws bedrock list-foundation-models --region us-east-1
```

### 메모리 부족
```bash
# 메모리 확인
free -h

# 스왑 파일 생성 (필요시)
sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 완료!

배포가 완료되면:
- **API URL**: `http://YOUR_PUBLIC_IP:8000`
- **헬스체크**: `http://YOUR_PUBLIC_IP:8000/api/health`
- **API 문서**: `http://YOUR_PUBLIC_IP:8000/docs`

Flutter 앱에서 새로운 API URL로 접속하면 정상 작동할 것입니다!