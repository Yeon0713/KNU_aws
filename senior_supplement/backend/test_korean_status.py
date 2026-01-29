#!/usr/bin/env python3
"""
건강검진 분석에서 한국어 상태명이 올바르게 반환되는지 테스트
"""
import requests
import json

def test_korean_status():
    url = "http://localhost:8000/api/analyze-checkup"
    
    test_data = {
        "user_info": {
            "name": "테스트사용자",
            "age": 65,
            "gender": "남성",
            "height": 170,
            "weight": 70
        },
        "checkup_text": "혈압: 140/90 mmHg, 총콜레스테롤: 220 mg/dL, 혈당: 110 mg/dL, BMI: 24.5"
    }
    
    try:
        print("🧪 건강검진 분석 API 테스트 시작...")
        response = requests.post(url, json=test_data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ API 호출 성공!")
            print(f"📊 응답 데이터: {json.dumps(result, ensure_ascii=False, indent=2)}")
            
            if 'data' in result:
                status = result['data'].get('status', 'Unknown')
                print(f"🏥 건강 상태: {status}")
                
                # 한국어 상태명 확인
                korean_statuses = ['정상', '주의', '위험']
                if status in korean_statuses:
                    print("✅ 한국어 상태명이 올바르게 반환되었습니다!")
                else:
                    print(f"❌ 영어 상태명이 반환되었습니다: {status}")
                    print("   예상: 정상/주의/위험 중 하나")
            else:
                print("❌ 응답에 data 필드가 없습니다.")
        else:
            print(f"❌ API 호출 실패: {response.status_code}")
            print(f"   오류 내용: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ 네트워크 오류: {e}")
    except Exception as e:
        print(f"❌ 예상치 못한 오류: {e}")

if __name__ == "__main__":
    test_korean_status()