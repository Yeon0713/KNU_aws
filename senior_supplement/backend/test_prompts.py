#!/usr/bin/env python3
import boto3
import json
import os

class PromptTester:
    def __init__(self):
        self.session = boto3.Session()
        self.bedrock = self.session.client(service_name='bedrock-runtime', region_name='us-east-1')
        self.model_id = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"

    def load_prompt(self, filename, variables):
        """prompts 폴더 내의 텍스트 파일을 읽고 변수를 치환합니다."""
        filepath = os.path.join("prompts", filename)
        
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"파일을 찾을 수 없습니다: {os.path.abspath(filepath)}")

        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        for key, value in variables.items():
            content = content.replace(f"{{{{{key}}}}}", str(value))
        return content

    def call_claude(self, system_prompt, user_message):
        """Claude 4.5를 호출하여 텍스트 기반 추론을 수행하고 JSON을 반환합니다."""
        response = self.bedrock.converse(
            modelId=self.model_id,
            system=[{"text": system_prompt}],
            messages=[{"role": "user", "content": [{"text": user_message}]}]
        )
        
        raw_text = response['output']['message']['content'][0]['text']
        
        try:
            if "```json" in raw_text:
                json_text = raw_text.split("```json")[1].split("```")[0].strip()
            else:
                start_idx = raw_text.find("{")
                end_idx = raw_text.rfind("}") + 1
                json_text = raw_text[start_idx:end_idx]
            return json.loads(json_text)
        except Exception as e:
            print(f"JSON 파싱 실패! 원문: {raw_text}")
            raise e

def test_checkup_prompt():
    """건강검진 프롬프트 테스트"""
    tester = PromptTester()
    
    # 테스트 데이터
    user_info = {
        "name": "김영희",
        "age": "75",
        "gender": "여성", 
        "height": "160",
        "weight": "58",
        "checkup_text": "T-score -2.6, 혈압 145/85"
    }
    
    print("🧪 건강검진 프롬프트 테스트 중...")
    
    try:
        # 프롬프트 로드
        system_prompt = tester.load_prompt("checkup_expert.txt", user_info)
        print("✅ 프롬프트 로드 성공")
        
        # Claude 호출
        result = tester.call_claude(system_prompt, "제공된 검진 수치를 바탕으로 상태를 분석해주세요.")
        print("✅ Claude 응답 성공")
        
        # 결과 출력
        print(f"\n📊 분석 결과:")
        print(f"상태: {result.get('status', '알 수 없음')}")
        print(f"내용: {result.get('content', '내용 없음')}")
        print(f"추천 영양소: {result.get('recommended_nutrient', '없음')}")
        print(f"실천 방안: {result.get('action_plan', '없음')}")
        
        return True
        
    except Exception as e:
        print(f"❌ 오류 발생: {str(e)}")
        return False

if __name__ == "__main__":
    print("="*50)
    print(" 프롬프트 시스템 테스트")
    print("="*50)
    
    success = test_checkup_prompt()
    
    if success:
        print("\n🎉 프롬프트 시스템이 정상적으로 작동합니다!")
    else:
        print("\n❌ 프롬프트 시스템에 문제가 있습니다.")