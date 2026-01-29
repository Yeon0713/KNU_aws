import boto3
import os
from dotenv import load_dotenv

# 1. .env 파일의 환경 변수 로드
load_dotenv()

def test_claude_connection():
    # 2. Bedrock Runtime 클라이언트 생성
    # .env에 AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION이 있어야 합니다.
    client = boto3.client(
        service_name='bedrock-runtime',
        region_name=os.getenv("AWS_REGION", "us-east-1") 
    )

    # 3. 사용할 모델 ID (Claude 4.5 Sonnet)
    model_id = "anthropic.claude-sonnet-4-5-20250929-v1:0"

    # 4. 질문 던지기
    prompt = "안녕 Claude! API 연동이 성공했다면 '연동 성공'이라고 말해주고, 우리 앱의 핵심 기능을 짧게 요약해줘."

    try:
        response = client.converse(
            modelId=model_id,
            messages=[{"role": "user", "content": [{"text": prompt}]}]
        )
        
        # 5. 답변 출력
        result = response['output']['message']['content'][0]['text']
        print("\n--- Claude의 답변 ---")
        print(result)
        print("---------------------\n")
        
    except Exception as e:
        print(f"\n❌ 연동 실패: {str(e)}")
        print("팁: .env 파일의 키값과 AWS 권한 설정을 확인하세요!")

if __name__ == "__main__":
    test_claude_connection()