import boto3

def start_chat():
    session = boto3.Session()
    # 인퍼런스 프로필 ID 사용
    model_id = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
    client = session.client(service_name='bedrock-runtime', region_name='us-east-1')

    print("🚀 Claude 4.5와 대화를 시작합니다! (종료하려면 'exit' 입력)")
    
    while True:
        user_input = input("\n나: ")
        if user_input.lower() == 'exit':
            break

        try:
            response = client.converse(
                modelId=model_id,
                messages=[{"role": "user", "content": [{"text": user_input}]}]
            )
            answer = response['output']['message']['content'][0]['text']
            print(f"🤖 Claude: {answer}")
        except Exception as e:
            print(f"❌ 오류: {e}")

if __name__ == "__main__":
    start_chat()