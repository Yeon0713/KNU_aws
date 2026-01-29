#!/bin/bash

# KNU 건강 관리 앱 EC2 배포 스크립트

echo "🚀 KNU 건강 관리 앱 EC2 배포 시작..."

# 시스템 업데이트
echo "📦 시스템 패키지 업데이트 중..."
sudo yum update -y

# Python 3.11 설치
echo "🐍 Python 3.11 설치 중..."
sudo yum install -y python3 python3-pip git

# 프로젝트 클론
echo "📥 GitHub에서 프로젝트 클론 중..."
cd /home/ec2-user
if [ -d "KNU_aws" ]; then
    echo "기존 프로젝트 디렉토리 제거 중..."
    rm -rf KNU_aws
fi

git clone https://github.com/yun-yeo-heon/KNU_aws.git
cd KNU_aws/senior_supplement/backend

# Python 의존성 설치
echo "📚 Python 패키지 설치 중..."
pip3 install --user -r requirements.txt

# 환경 변수 설정
echo "⚙️ 환경 변수 설정 중..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "❗ .env 파일을 수정하여 AWS 자격 증명을 입력하세요!"
fi

# 포트 8000 방화벽 열기
echo "🔓 포트 8000 방화벽 설정 중..."
sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT

# systemd 서비스 파일 생성
echo "🔧 systemd 서비스 설정 중..."
sudo tee /etc/systemd/system/knu-health.service > /dev/null <<EOF
[Unit]
Description=KNU Health App Backend
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/KNU_aws/senior_supplement/backend
Environment=PATH=/home/ec2-user/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/python3 api_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 서비스 활성화 및 시작
echo "🎯 서비스 활성화 및 시작 중..."
sudo systemctl daemon-reload
sudo systemctl enable knu-health
sudo systemctl start knu-health

# 서비스 상태 확인
echo "📊 서비스 상태 확인 중..."
sudo systemctl status knu-health

echo ""
echo "✅ 배포 완료!"
echo "🌐 서버 URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
echo "🏥 헬스체크: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/api/health"
echo ""
echo "📝 다음 단계:"
echo "1. .env 파일에 AWS 자격 증명 입력"
echo "2. Flutter 앱의 API URL 업데이트"
echo "3. 보안 그룹에서 포트 8000 열기"
echo ""
echo "🔍 로그 확인: sudo journalctl -u knu-health -f"
echo "🔄 서비스 재시작: sudo systemctl restart knu-health"