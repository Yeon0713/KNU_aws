#!/usr/bin/env python3
import requests
import json
import base64

def test_all_ai_features():
    """모든 AI 기능을 테스트합니다."""
    
    base_url = "http://localhost:8000"
    
    print("🧪 전체 AI 기능 테스트")
    print("=" * 60)
    
    # 테스트 사용자 정보
    user_info = {
        "name": "김영희",
        "age": 70,
        "gender": "여성",
        "height": 160,
        "weight": 55
    }
    
    # 1. 서버 상태 확인
    print("\n1️⃣ 서버 상태 확인")
    try:
        response = requests.get(f"{base_url}/api/health")
        if response.status_code == 200:
            health_data = response.json()
            print("✅ 서버 정상 작동")
            print(f"   - AWS 연결: {health_data.get('aws_connected', False)}")
            print(f"   - FAISS 로드: {health_data.get('rag_system', {}).get('faiss_loaded', False)}")
            print(f"   - 메타데이터 로드: {health_data.get('rag_system', {}).get('metadata_loaded', False)}")
        else:
            print(f"❌ 서버 상태 확인 실패: {response.status_code}")
            return
    except Exception as e:
        print(f"❌ 서버 연결 실패: {e}")
        return
    
    # 2. 건강검진 분석 테스트
    print("\n2️⃣ 건강검진 분석 AI 테스트")
    try:
        checkup_data = {
            "user_info": user_info,
            "checkup_text": "혈압 145/90, 콜레스테롤 230mg/dL, 혈당 115mg/dL, 골밀도 T-score -2.1"
        }
        
        response = requests.post(f"{base_url}/api/analyze-checkup", json=checkup_data)
        if response.status_code == 200:
            result = response.json()['data']
            print("✅ 건강검진 분석 성공")
            print(f"   - 상태: {result.get('status', 'N/A')}")
            print(f"   - 분석: {result.get('content', 'N/A')[:100]}...")
            print(f"   - 추천 영양소: {result.get('recommended_nutrient', 'N/A')}")
        else:
            print(f"❌ 건강검진 분석 실패: {response.status_code}")
    except Exception as e:
        print(f"❌ 건강검진 분석 오류: {e}")
    
    # 3. 식단 분석 테스트 (더미 이미지)
    print("\n3️⃣ 식단 분석 AI 테스트")
    try:
        # 더미 이미지 (1x1 픽셀 PNG)
        dummy_image = base64.b64encode(b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\tpHYs\x00\x00\x0b\x13\x00\x00\x0b\x13\x01\x00\x9a\x9c\x18\x00\x00\x00\x12IDATx\x9cc```bPPP\x00\x02\xac\xea\x05\xc1\x00\x00\x00\x00IEND\xaeB`\x82').decode()
        
        meal_data = {
            "user_info": user_info,
            "image_base64": dummy_image
        }
        
        response = requests.post(f"{base_url}/api/analyze-meal", json=meal_data)
        if response.status_code == 200:
            result = response.json()['data']
            print("✅ 식단 분석 성공")
            print(f"   - 인식된 음식: {result.get('detected_foods', [])}")
            print(f"   - 분석: {result.get('content', 'N/A')[:100]}...")
            print(f"   - 추천 영양소: {result.get('recommended_nutrient', 'N/A')}")
            print(f"   - Rekognition 신뢰도: {result.get('rekognition_confidence', False)}")
        else:
            print(f"❌ 식단 분석 실패: {response.status_code}")
    except Exception as e:
        print(f"❌ 식단 분석 오류: {e}")
    
    # 4. 유튜브 팩트체킹 테스트
    print("\n4️⃣ 유튜브 팩트체킹 AI 테스트")
    try:
        factcheck_data = {
            "user_info": user_info,
            "youtube_url": "https://youtube.com/watch?v=test123"
        }
        
        response = requests.post(f"{base_url}/api/fact-check-youtube", json=factcheck_data)
        if response.status_code == 200:
            result = response.json()['data']
            print("✅ 유튜브 팩트체킹 성공")
            print(f"   - 신뢰도: {result.get('overall_credibility', 'N/A')}")
            print(f"   - 분석: {result.get('fact_check_result', 'N/A')[:100]}...")
            print(f"   - 검증된 사실: {len(result.get('verified_claims', []))}개")
            print(f"   - 의심스러운 주장: {len(result.get('questionable_claims', []))}개")
            print(f"   - RAG 소스: {result.get('rag_sources', 0)}개")
        else:
            print(f"❌ 유튜브 팩트체킹 실패: {response.status_code}")
    except Exception as e:
        print(f"❌ 유튜브 팩트체킹 오류: {e}")
    
    # 5. 일반 텍스트 팩트체킹 테스트
    print("\n5️⃣ 일반 텍스트 팩트체킹 AI 테스트")
    try:
        text_factcheck_data = {
            "user_info": user_info,
            "youtube_url": "텍스트: 양파즙이 당뇨를 완전히 치료할 수 있다고 들었는데 정말인가요?"
        }
        
        response = requests.post(f"{base_url}/api/fact-check-youtube", json=text_factcheck_data)
        if response.status_code == 200:
            result = response.json()['data']
            print("✅ 텍스트 팩트체킹 성공")
            print(f"   - 신뢰도: {result.get('overall_credibility', 'N/A')}")
            print(f"   - 분석: {result.get('fact_check_result', 'N/A')[:100]}...")
            print(f"   - 권장사항: {result.get('recommendations', 'N/A')[:100]}...")
        else:
            print(f"❌ 텍스트 팩트체킹 실패: {response.status_code}")
    except Exception as e:
        print(f"❌ 텍스트 팩트체킹 오류: {e}")
    
    # 6. 종합 영양제 추천 테스트 (RAG 포함)
    print("\n6️⃣ 종합 영양제 추천 AI 테스트 (RAG 기반)")
    try:
        supplement_data = {
            "user_info": user_info,
            "checkup_result": {
                "status": "Yellow",
                "content": "혈압과 골밀도에 주의가 필요합니다."
            },
            "meal_result": {
                "content": "단백질과 칼슘이 부족합니다.",
                "recommended_nutrient": "단백질, 칼슘"
            }
        }
        
        response = requests.post(f"{base_url}/api/recommend-supplements", json=supplement_data)
        if response.status_code == 200:
            result = response.json()['data']
            print("✅ 영양제 추천 성공")
            print(f"   - 종합 진단: {result.get('content', 'N/A')[:100]}...")
            print(f"   - 추천 영양제: {len(result.get('supplement_list', []))}개")
            
            for i, supplement in enumerate(result.get('supplement_list', []), 1):
                print(f"     {i}. {supplement.get('name', 'Unknown')}")
                print(f"        이유: {supplement.get('reason', 'N/A')[:50]}...")
                print(f"        복용: {supplement.get('schedule', {}).get('time', 'N/A')} {supplement.get('schedule', {}).get('timing', 'N/A')}")
            
            rag_info = result.get('rag_info', {})
            print(f"   - RAG 컨텍스트: {rag_info.get('context_sources', 0)}개")
            print(f"   - 안전성 체크: {rag_info.get('safety_checks', 0)}개")
            print(f"   - DB 사용: {rag_info.get('database_used', False)}")
        else:
            print(f"❌ 영양제 추천 실패: {response.status_code}")
    except Exception as e:
        print(f"❌ 영양제 추천 오류: {e}")
    
    print("\n" + "=" * 60)
    print("🎉 전체 AI 기능 테스트 완료!")
    print("📱 이제 Flutter 앱에서 모든 AI 기능을 사용할 수 있습니다!")

if __name__ == "__main__":
    test_all_ai_features()