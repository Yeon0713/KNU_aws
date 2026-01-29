import boto3
import json
import os
import io
from PIL import Image

# [1] 클래스 정의
class NutriScanApp:
    def __init__(self):
        # AWS 서비스 클라이언트 설정
        self.session = boto3.Session()
        self.bedrock = self.session.client(service_name='bedrock-runtime', region_name='us-east-1')
        self.rekognition = self.session.client(service_name='rekognition', region_name='us-east-1')
        
        # [TEXTRACT 주석 처리] 나중에 기능을 사용할 때 아래 줄의 주석을 해제하세요.
        # self.textract = self.session.client(service_name='textract', region_name='us-east-1')
        
        self.model_id = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"

    # NutriScanApp 클래스 내부의 메서드 수정
    def load_prompt(self, filename, variables):
        """prompts 폴더 내의 텍스트 파일을 읽고 변수를 치환합니다."""
        # 기존 "frontend" 대신 "prompts"로 경로 수정
        filepath = os.path.join("prompts", filename) 

        if not os.path.exists(filepath):
            # 현재 실행 위치 확인을 위해 경로 포함 출력
            raise FileNotFoundError(f"파일을 찾을 수 없습니다: {os.path.abspath(filepath)}")

        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        for key, value in variables.items():
            content = content.replace(f"{{{{{key}}}}}", str(value))
        return content


    def analyze_food_with_rekognition(self, image_path):
        """Rekognition을 사용하여 이미지에서 음식 레이블을 추출합니다 (최대 15MB)."""
        if not os.path.exists(image_path):
            return []

        # 15MB 제한에 맞춘 리사이징 로직
        max_size = 15 * 1024 * 1024
        with Image.open(image_path) as img:
            if img.mode in ("RGBA", "P"):
                img = img.convert("RGB")
            
            quality = 95
            while True:
                buffer = io.BytesIO()
                img.save(buffer, format="JPEG", quality=quality)
                image_bytes = buffer.getvalue()
                if len(image_bytes) <= max_size or quality <= 40:
                    break
                quality -= 10

        try:
            response = self.rekognition.detect_labels(
                Image={'Bytes': image_bytes},
                MaxLabels=10,
                MinConfidence=70
            )
            return [label['Name'] for label in response['Labels']]
        except Exception as e:
            print(f"Rekognition 분석 중 오류 발생: {str(e)}")
            return []

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

# [2] 실행 로직
if __name__ == "__main__":
    app = NutriScanApp()
    
    print("\n" + "="*50)
    print(" 시니어 맞춤형 건강 관리 뉴트리스캔 테스트")
    print("="*50)

    # 사용자 정보 입력
    user_info = {
        "name": input("이름: "),
        "age": input("나이: "),
        "gender": input("성별(남성/여성): "),
        "height": input("키(cm): "),
        "weight": input("몸무게(kg): ")
        # "health_domain": input("관심 분야(예: 혈관, 뼈): ")
    }

    checkup_input = input("\n검진 수치를 입력하세요(예: 혈압 140/90): ")
    image_name = input("식단 사진 파일명(images 폴더 내, 예: ramen.jpg): ")
    
    if image_name and "." not in image_name:
        image_name += ".jpg"
    meal_path = os.path.join("images", image_name) if image_name else None

    print(f"\n {user_info['name']}님 맞춤 분석 중...")

    # 1단계: 건강검진 분석 (checkup_expert.txt)
    p1_vars = {**user_info, "checkup_text": checkup_input}
    p1_system = app.load_prompt("checkup_expert.txt", p1_vars)
    p1_res = app.call_claude(p1_system, "제공된 검진 수치를 바탕으로 상태를 분석해주세요.")
    print(f"- 건강 상태 판정: {p1_res.get('status', '알 수 없음')}")

    # 2단계: 식단 분석 (Rekognition + meal_vision_coach.txt)
    p2_res = {"content": "식단 데이터 없음", "detected_foods": []}
    if meal_path and os.path.exists(meal_path):
        print("- 사진에서 음식을 인식하고 있습니다...")
        detected_labels = app.analyze_food_with_rekognition(meal_path)
        
        # Rekognition 결과를 텍스트로 변환하여 Claude에게 전달
        food_list_str = ", ".join(detected_labels)
        p2_system = app.load_prompt("meal_vision_coach.txt", user_info)
        p2_user_msg = f"사진에서 다음 음식들이 인식되었습니다: {food_list_str}. 분석 프로세스에 따라 영양 성분을 평가해주세요."
        p2_res = app.call_claude(p2_system, p2_user_msg)
        print(f"- 인식된 음식: {p2_res.get('detected_foods', '알 수 없음')}")
    else:
        print("- 식단 사진이 없어 분석을 건너뜁니다.")

    # 3단계: 최종 영양제 추천 (final_supplement_expert.txt)
    # RAG 지식은 현재 예시 텍스트로 대체
    p3_vars = {
        **user_info,
        "checkup_analysis_result": p1_res.get('content', ''),
        "meal_analysis_result": p2_res.get('content', ''),
        "retrieved_context": "칼슘과 철분은 흡수를 방해하므로 2시간 간격 복용 권장" 
    }
    p3_system = app.load_prompt("final_supplement_expert.txt", p3_vars)
    p3_res = app.call_claude(p3_system, "모든 데이터를 통합하여 최적의 영양제 스케줄을 설계해주세요.")

    # 최종 결과 출력
    print("\n" + "*"*50)
    print(f"[{user_info['name']}님을 위한 최종 분석 결과]")
    print(f"종합 진단: {p3_res.get('content', '내용 없음')}")
    print("\n[추천 영양제 리스트]")
    for item in p3_res.get('supplement_list', []):
        print(f"- {item['name']} ({item['dosage']}): {item['reason']}")
        print(f"  복용 시간: {item['schedule']['time']} / {item['schedule']['timing']}")
    
    print(f"\n주의사항: {p3_res.get('special_caution', '특이사항 없음')}")
    print("*"*50)