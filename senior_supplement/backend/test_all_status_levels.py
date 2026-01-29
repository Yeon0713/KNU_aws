#!/usr/bin/env python3
"""
모든 건강 상태 레벨(정상/주의/위험)이 한국어로 올바르게 반환되는지 테스트
"""
import requests
import json

def test_status_level(test_name, checkup_text, expected_status):
    url = "http://localhost:8000/api/analyze-checkup"
    
    test_data = {
        "user_info": {
            "name": "테스트사용자",
            "age": 65,
            "gender": "남성",
            "height": 170,
            "weight": 70
        },
        "checkup_text": checkup_text
    }
    
    try:
        print(f"\n🧪 {test_name} 테스트...")
        response = requests.post(url, json=test_data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if 'data' in result:
                status = result['data'].get('status', 'Unknown')
                content = result['data'].get('content', '')
                print(f"🏥 건강 상태: {status}")
                print(f"📝 분석 내용: {content[:50]}...")
                
                korean_statuses = ['정상', '주의', '위험']
                if status in korean_statuses:
                    print(f"✅ 한국어 상태명 반환 성공: {status}")
                    if status == expected_status:
                        print(f"✅ 예상 상태와 일치: {expected_status}")
                    else:
                        print(f"⚠️ 예상 상태와 다름: 예상={expected_status}, 실제={status}")
                else:
                    print(f"❌ 영어 상태명 반환: {status}")
            else:
                print("❌ 응답에 data 필드가 없습니다.")
        else:
            print(f"❌ API 호출 실패: {response.status_code}")
            
    except Exception as e:
        print(f"❌ 오류: {e}")

def main():
    print("🏥 건강검진 상태명 한국어 변환 테스트")
    
    # 정상 케이스
    test_status_level(
        "정상 상태",
        "혈압: 120/80 mmHg, 총콜레스테롤: 180 mg/dL, 혈당: 90 mg/dL, BMI: 22.0",
        "정상"
    )
    
    # 주의 케이스  
    test_status_level(
        "주의 상태",
        "혈압: 140/90 mmHg, 총콜레스테롤: 220 mg/dL, 혈당: 110 mg/dL, BMI: 24.5",
        "주의"
    )
    
    # 위험 케이스
    test_status_level(
        "위험 상태", 
        "혈압: 160/100 mmHg, 총콜레스테롤: 280 mg/dL, 혈당: 140 mg/dL, BMI: 28.0",
        "위험"
    )
    
    print("\n🎯 테스트 완료!")

if __name__ == "__main__":
    main()