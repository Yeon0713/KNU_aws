#!/usr/bin/env python3
import requests
import json

def test_rag_search_api():
    """RAG 검색 API를 테스트합니다."""
    
    base_url = "http://localhost:8000"
    
    print("🧪 RAG 검색 API 테스트")
    print("=" * 50)
    
    # 1. 서버 상태 확인
    try:
        response = requests.get(f"{base_url}/api/health")
        if response.status_code == 200:
            health_data = response.json()
            print("✅ 서버 상태 확인:")
            print(f"   - AWS 연결: {health_data.get('aws_connected', False)}")
            print(f"   - FAISS 로드: {health_data.get('rag_system', {}).get('faiss_loaded', False)}")
            print(f"   - 메타데이터 로드: {health_data.get('rag_system', {}).get('metadata_loaded', False)}")
        else:
            print(f"❌ 서버 상태 확인 실패: {response.status_code}")
            return
    except Exception as e:
        print(f"❌ 서버 연결 실패: {e}")
        return
    
    # 2. RAG 검색 테스트
    test_queries = [
        "비타민D",
        "칼슘",
        "오메가3",
        "혈압",
        "홍삼",
        "면역력"
    ]
    
    for query in test_queries:
        print(f"\n🔍 검색어: '{query}'")
        try:
            response = requests.get(f"{base_url}/api/search-supplements", params={
                "query": query,
                "limit": 3
            })
            
            if response.status_code == 200:
                data = response.json()
                results = data.get('results', [])
                print(f"   검색 결과: {len(results)}개")
                
                for i, result in enumerate(results, 1):
                    name = result.get('name', 'Unknown')
                    content = result.get('content', result.get('full_text', ''))[:100]
                    score = result.get('similarity_score', 0)
                    
                    print(f"   {i}. {name} (점수: {score:.3f})")
                    print(f"      내용: {content}...")
                    
            else:
                print(f"   ❌ 검색 실패: {response.status_code}")
                print(f"   오류: {response.text}")
                
        except Exception as e:
            print(f"   ❌ 검색 오류: {e}")

def test_supplement_recommendation():
    """영양제 추천 API 테스트 (RAG 포함)"""
    
    base_url = "http://localhost:8000"
    
    print(f"\n🤖 영양제 추천 API 테스트 (RAG 기반)")
    print("=" * 50)
    
    # 테스트 데이터
    test_data = {
        "user_info": {
            "name": "김영희",
            "age": 70,
            "gender": "여성",
            "height": 160,
            "weight": 55
        },
        "checkup_result": {
            "status": "Yellow",
            "content": "혈압이 약간 높고 골밀도가 낮습니다."
        },
        "meal_result": {
            "content": "단백질과 칼슘이 부족합니다.",
            "recommended_nutrient": "단백질, 칼슘"
        }
    }
    
    try:
        response = requests.post(
            f"{base_url}/api/recommend-supplements",
            json=test_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            result = data.get('data', {})
            
            print("✅ 추천 결과:")
            print(f"   종합 진단: {result.get('content', 'N/A')}")
            
            supplements = result.get('supplement_list', [])
            print(f"   추천 영양제: {len(supplements)}개")
            
            for i, supplement in enumerate(supplements, 1):
                print(f"   {i}. {supplement.get('name', 'Unknown')}")
                print(f"      이유: {supplement.get('reason', 'N/A')}")
                print(f"      복용: {supplement.get('schedule', {}).get('time', 'N/A')} {supplement.get('schedule', {}).get('timing', 'N/A')}")
            
            # RAG 정보 확인
            rag_info = result.get('rag_info', {})
            if rag_info:
                print(f"   RAG 정보:")
                print(f"   - 컨텍스트 소스: {rag_info.get('context_sources', 0)}개")
                print(f"   - 안전성 체크: {rag_info.get('safety_checks', 0)}개")
                print(f"   - 데이터베이스 사용: {rag_info.get('database_used', False)}")
            
        else:
            print(f"❌ 추천 실패: {response.status_code}")
            print(f"오류: {response.text}")
            
    except Exception as e:
        print(f"❌ 추천 오류: {e}")

if __name__ == "__main__":
    test_rag_search_api()
    test_supplement_recommendation()