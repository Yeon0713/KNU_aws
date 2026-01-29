#!/usr/bin/env python3
import pickle
import os
import faiss
import numpy as np

def check_faiss_files():
    """FAISS 파일들의 구조를 확인합니다."""
    
    data_path = "../data/mfds_faiss_index"
    faiss_path = os.path.join(data_path, "index.faiss")
    pkl_path = os.path.join(data_path, "index.pkl")
    
    print("🔍 FAISS 파일 구조 확인")
    print("=" * 50)
    
    # 1. FAISS 인덱스 파일 확인
    if os.path.exists(faiss_path):
        try:
            index = faiss.read_index(faiss_path)
            print(f"✅ FAISS 인덱스 로드 성공")
            print(f"   - 총 벡터 수: {index.ntotal}")
            print(f"   - 벡터 차원: {index.d}")
            print(f"   - 인덱스 타입: {type(index)}")
        except Exception as e:
            print(f"❌ FAISS 인덱스 로드 실패: {e}")
    else:
        print(f"❌ FAISS 인덱스 파일 없음: {faiss_path}")
    
    # 2. 메타데이터 파일 확인
    if os.path.exists(pkl_path):
        try:
            with open(pkl_path, 'rb') as f:
                metadata = pickle.load(f)
            
            print(f"✅ 메타데이터 로드 성공")
            print(f"   - 메타데이터 타입: {type(metadata)}")
            print(f"   - 메타데이터 길이: {len(metadata) if hasattr(metadata, '__len__') else 'N/A'}")
            
            # 첫 번째 항목 확인
            if isinstance(metadata, list) and len(metadata) > 0:
                first_item = metadata[0]
                print(f"   - 첫 번째 항목 타입: {type(first_item)}")
                if isinstance(first_item, dict):
                    print(f"   - 첫 번째 항목 키: {list(first_item.keys())}")
                    for key, value in list(first_item.items())[:3]:  # 처음 3개 키만
                        print(f"     {key}: {str(value)[:100]}...")
                        
        except Exception as e:
            print(f"❌ 메타데이터 로드 실패: {e}")
    else:
        print(f"❌ 메타데이터 파일 없음: {pkl_path}")

def test_simple_search():
    """간단한 검색 테스트"""
    print("\n🧪 간단한 검색 테스트")
    print("=" * 50)
    
    try:
        from rag_system import RAGSystem
        rag = RAGSystem()
        
        # 검색 테스트
        queries = ["비타민", "칼슘", "오메가3", "혈압"]
        
        for query in queries:
            print(f"\n검색어: '{query}'")
            results = rag.search_similar_documents(query, top_k=3)
            print(f"결과 수: {len(results)}")
            
            for i, result in enumerate(results[:2], 1):  # 상위 2개만
                name = result.get('name', 'Unknown')[:30]
                effect = result.get('effect', 'N/A')[:50]
                score = result.get('similarity_score', 0)
                print(f"  {i}. {name} (점수: {score:.3f})")
                print(f"     효과: {effect}...")
                
    except Exception as e:
        print(f"❌ 검색 테스트 실패: {e}")

if __name__ == "__main__":
    check_faiss_files()
    test_simple_search()