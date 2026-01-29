#!/usr/bin/env python3
"""
식단 분석 Claude Vision 테스트
"""
import requests
import base64
import json

def test_meal_analysis():
    """식단 분석 API 테스트"""
    
    # 테스트용 더미 이미지 (1x1 픽셀 JPEG)
    dummy_image = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\' ",#\x1c\x1c(7),01444\x1f\'9=82<.342\xff\xc0\x00\x11\x08\x00\x01\x00\x01\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00\xaa\xff\xd9'
    
    image_base64 = base64.b64encode(dummy_image).decode('utf-8')
    
    # API 요청 데이터
    request_data = {
        "user_info": {
            "name": "테스트사용자",
            "age": 70,
            "gender": "남성",
            "height": 170,
            "weight": 70
        },
        "image_base64": image_base64
    }
    
    try:
        print("🧪 식단 분석 API 테스트 시작...")
        
        response = requests.post(
            "http://localhost:8000/api/analyze-meal",
            json=request_data,
            timeout=30
        )
        
        print(f"📡 응답 상태: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ API 호출 성공!")
            print(f"📊 응답 데이터: {json.dumps(result, ensure_ascii=False, indent=2)}")
            
            # 결과 검증
            if result.get('success') and result.get('data'):
                data = result['data']
                detected_foods = data.get('detected_foods', [])
                
                print(f"\n🍽️ 인식된 음식: {detected_foods}")
                print(f"📝 분석 내용: {data.get('content', 'N/A')}")
                print(f"💊 권장 영양소: {data.get('recommended_nutrient', 'N/A')}")
                
                # Claude Vision이 제대로 작동했는지 확인
                if detected_foods and not all(food in ['Food', 'Meal', 'Dish'] for food in detected_foods):
                    print("✅ Claude Vision이 구체적인 음식을 식별했습니다!")
                else:
                    print("⚠️ Claude Vision이 여전히 일반적인 라벨만 반환했습니다.")
            else:
                print("❌ 응답 데이터 구조가 예상과 다릅니다.")
        else:
            print(f"❌ API 호출 실패: {response.status_code}")
            print(f"오류 내용: {response.text}")
            
    except Exception as e:
        print(f"❌ 테스트 중 오류 발생: {str(e)}")

if __name__ == "__main__":
    test_meal_analysis()