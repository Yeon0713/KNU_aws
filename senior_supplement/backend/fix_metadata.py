#!/usr/bin/env python3
import pickle
import os
import sys

def analyze_pickle_file():
    """pickle 파일의 구조를 분석하고 langchain 의존성을 제거합니다."""
    
    pkl_path = "../data/mfds_faiss_index/index.pkl"
    
    print("🔍 메타데이터 파일 분석 중...")
    print("=" * 50)
    
    try:
        # 원본 파일 읽기 시도
        with open(pkl_path, 'rb') as f:
            # pickle 파일의 내용을 바이트로 읽기
            content = f.read()
            print(f"파일 크기: {len(content)} bytes")
            
            # 파일 내용에서 langchain 관련 문자열 확인
            content_str = str(content)
            if 'langchain' in content_str:
                print("⚠️ langchain 의존성 발견됨")
            
            # 다른 방법으로 로드 시도
            f.seek(0)
            
            # 단계별로 unpickle 시도
            try:
                # 기본 pickle 로드
                data = pickle.load(f)
                print(f"✅ 기본 pickle 로드 성공!")
                print(f"데이터 타입: {type(data)}")
                
                if hasattr(data, '__len__'):
                    print(f"데이터 길이: {len(data)}")
                
                # 첫 번째 항목 분석
                if isinstance(data, (list, tuple)) and len(data) > 0:
                    first_item = data[0]
                    print(f"첫 번째 항목 타입: {type(first_item)}")
                    
                    if hasattr(first_item, '__dict__'):
                        print(f"첫 번째 항목 속성: {list(first_item.__dict__.keys())}")
                    elif isinstance(first_item, dict):
                        print(f"첫 번째 항목 키: {list(first_item.keys())}")
                        
                return data
                
            except Exception as load_error:
                print(f"❌ 기본 로드 실패: {load_error}")
                
                # 대안 방법들 시도
                try:
                    # 다른 프로토콜로 시도
                    f.seek(0)
                    data = pickle.load(f)
                    return data
                except:
                    pass
                
                return None
                
    except Exception as e:
        print(f"❌ 파일 분석 실패: {e}")
        return None

def create_clean_metadata(original_data):
    """langchain 의존성 없는 깨끗한 메타데이터를 생성합니다."""
    
    if original_data is None:
        print("❌ 원본 데이터가 없어 메타데이터 생성 불가")
        return None
    
    print("\n🔧 깨끗한 메타데이터 생성 중...")
    print("=" * 50)
    
    clean_metadata = []
    
    try:
        # langchain의 InMemoryDocstore에서 문서 추출
        if hasattr(original_data, '__len__') and len(original_data) >= 1:
            docstore = original_data[0]  # 첫 번째 항목이 docstore
            
            if hasattr(docstore, '_dict'):
                documents = docstore._dict
                print(f"문서 저장소에서 {len(documents)}개 문서 발견")
                
                for doc_id, document in documents.items():
                    clean_item = {
                        'id': doc_id,
                        'content': '',
                        'metadata': {}
                    }
                    
                    # langchain Document 객체에서 데이터 추출
                    if hasattr(document, 'page_content'):
                        clean_item['content'] = document.page_content
                    
                    if hasattr(document, 'metadata'):
                        clean_item['metadata'] = document.metadata
                        
                        # 메타데이터에서 주요 필드 추출
                        metadata = document.metadata
                        clean_item['name'] = metadata.get('name', '')
                        clean_item['company'] = metadata.get('company', '')
                        clean_item['effect'] = metadata.get('effect', '')
                        clean_item['full_text'] = metadata.get('full_text', document.page_content)
                    
                    clean_metadata.append(clean_item)
                    
                    # 진행 상황 표시
                    if len(clean_metadata) % 500 == 0:
                        print(f"처리 중... {len(clean_metadata)}/{len(documents)}")
        
        print(f"✅ 깨끗한 메타데이터 생성 완료: {len(clean_metadata)}개 항목")
        
        # 새 파일로 저장
        clean_pkl_path = "../data/mfds_faiss_index/index_clean.pkl"
        with open(clean_pkl_path, 'wb') as f:
            pickle.dump(clean_metadata, f, protocol=pickle.HIGHEST_PROTOCOL)
        
        print(f"✅ 깨끗한 메타데이터 저장 완료: {clean_pkl_path}")
        
        return clean_metadata
        
    except Exception as e:
        print(f"❌ 메타데이터 생성 실패: {e}")
        import traceback
        traceback.print_exc()
        return None

def test_clean_metadata():
    """생성된 깨끗한 메타데이터를 테스트합니다."""
    
    clean_pkl_path = "../data/mfds_faiss_index/index_clean.pkl"
    
    if not os.path.exists(clean_pkl_path):
        print("❌ 깨끗한 메타데이터 파일이 없습니다.")
        return False
    
    print("\n🧪 깨끗한 메타데이터 테스트")
    print("=" * 50)
    
    try:
        with open(clean_pkl_path, 'rb') as f:
            clean_data = pickle.load(f)
        
        print(f"✅ 깨끗한 메타데이터 로드 성공!")
        print(f"데이터 타입: {type(clean_data)}")
        print(f"데이터 길이: {len(clean_data)}")
        
        # 첫 번째 항목 확인
        if len(clean_data) > 0:
            first_item = clean_data[0]
            print(f"첫 번째 항목: {first_item}")
        
        return True
        
    except Exception as e:
        print(f"❌ 깨끗한 메타데이터 테스트 실패: {e}")
        return False

if __name__ == "__main__":
    # 1. 원본 메타데이터 분석
    original_data = analyze_pickle_file()
    
    # 2. 깨끗한 메타데이터 생성
    if original_data:
        clean_data = create_clean_metadata(original_data)
        
        # 3. 테스트
        if clean_data:
            test_clean_metadata()
    else:
        print("❌ 원본 데이터를 로드할 수 없어 진행할 수 없습니다.")
        print("💡 langchain_community를 설치해보세요: pip install langchain-community")