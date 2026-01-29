import boto3

def test_connection():
    try:
        # 1. 터미널(aws configure) 설정을 그대로 가져옵니다.
        session = boto3.Session()
        
        # 2. 현재 로그인된 사용자 정보 확인 (연동 확인용)
        sts = session.client('sts')
        identity = sts.get_caller_identity()
        print(f"✅ AWS 연동 성공! 계정 ID: {identity['Account']}")

        # 3. Claude 4.5 Sonnet 호출 테스트
        bedrock = session.client(service_name='bedrock-runtime', region_name='us-east-1')
        model_id = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
        
        response = bedrock.converse(
            modelId=model_id,
            messages=[{"role": "user", "content": [{"text": "안녕! 연결 성공했니?"}]}]
        )
        print(f"🤖 Claude 응답: {response['output']['message']['content'][0]['text']}")

    except Exception as e:
        print(f"❌ 오류 발생: {str(e)}")
        print("\n💡 체크리스트:")
        print("1. 터미널에 'aws configure'를 정확히 입력했나요?")
        print("2. IAM에서 'AmazonBedrockFullAccess' 권한을 추가했나요?")
        print("3. AWS 콘솔 Bedrock 메뉴에서 'Model Access'를 허용했나요?")

if __name__ == "__main__":
    test_connection()