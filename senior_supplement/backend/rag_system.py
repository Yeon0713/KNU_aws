#!/usr/bin/env python3
import os
import sqlite3
import pickle
import numpy as np
from typing import List, Dict, Any
import boto3
import json

try:
    import faiss
    FAISS_AVAILABLE = True
except ImportError:
    FAISS_AVAILABLE = False
    print("⚠️ FAISS가 설치되지 않았습니다. pip install faiss-cpu 를 실행해주세요.")

class RAGSystem:
    def __init__(self, data_path="../data"):
        self.data_path = data_path
        self.db_path = os.path.join(data_path, "medicines.db")
        self.faiss_index_path = os.path.join(data_path, "mfds_faiss_index", "index.faiss")
        self.faiss_pkl_path = os.path.join(data_path, "mfds_faiss_index", "index.pkl")
        self.clean_pkl_path = os.path.join(data_path, "mfds_faiss_index", "index_clean.pkl")  # 깨끗한 메타데이터
        
        # AWS Bedrock 클라이언트
        self.session = boto3.Session()
        self.bedrock = self.session.client(service_name='bedrock-runtime', region_name='us-east-1')
        
        # FAISS 인덱스와 메타데이터 로드
        self.index = None
        self.metadata = None
        self._load_faiss_index()
        
    def _load_faiss_index(self):
        """FAISS 인덱스와 메타데이터를 로드합니다."""
        if not FAISS_AVAILABLE:
            print("⚠️ FAISS를 사용할 수 없어 RAG 기능이 제한됩니다.")
            return
            
        try:
            if os.path.exists(self.faiss_index_path):
                # FAISS 인덱스 로드
                self.index = faiss.read_index(self.faiss_index_path)
                print(f"✅ FAISS 인덱스 로드 완료: {self.index.ntotal}개 문서")
                
                # 깨끗한 메타데이터 우선 시도
                if os.path.exists(self.clean_pkl_path):
                    try:
                        with open(self.clean_pkl_path, 'rb') as f:
                            self.metadata = pickle.load(f)
                        print(f"✅ 깨끗한 메타데이터 로드 완료: {len(self.metadata)}개 항목")
                        return
                    except Exception as clean_error:
                        print(f"⚠️ 깨끗한 메타데이터 로드 실패: {clean_error}")
                
                # 원본 메타데이터 시도 (langchain 의존성 필요)
                if os.path.exists(self.faiss_pkl_path):
                    try:
                        with open(self.faiss_pkl_path, 'rb') as f:
                            original_data = pickle.load(f)
                        
                        # langchain docstore에서 데이터 추출
                        if hasattr(original_data, '__len__') and len(original_data) >= 1:
                            docstore = original_data[0]
                            if hasattr(docstore, '_dict'):
                                documents = docstore._dict
                                self.metadata = []
                                
                                for doc_id, document in documents.items():
                                    clean_item = {
                                        'id': doc_id,
                                        'content': getattr(document, 'page_content', ''),
                                        'metadata': getattr(document, 'metadata', {}),
                                        'name': getattr(document, 'metadata', {}).get('name', ''),
                                        'full_text': getattr(document, 'page_content', '')
                                    }
                                    self.metadata.append(clean_item)
                                
                                print(f"✅ 원본 메타데이터 변환 완료: {len(self.metadata)}개 항목")
                                return
                                
                    except Exception as original_error:
                        print(f"⚠️ 원본 메타데이터 로드 실패: {original_error}")
                
                # 모든 메타데이터 로드 실패 시 SQLite 폴백
                print("⚠️ 메타데이터 로드 실패, SQLite 폴백 사용")
                self.metadata = None
                    
            else:
                print("⚠️ FAISS 인덱스 파일을 찾을 수 없습니다.")
        except Exception as e:
            print(f"❌ FAISS 인덱스 로드 실패: {str(e)}")
            self.index = None
            self.metadata = None
    
    def get_text_embedding(self, text: str) -> np.ndarray:
        """텍스트를 임베딩 벡터로 변환합니다."""
        try:
            # Amazon Titan Embeddings 사용
            response = self.bedrock.invoke_model(
                modelId="amazon.titan-embed-text-v1",
                body=json.dumps({
                    "inputText": text
                })
            )
            
            response_body = json.loads(response['body'].read())
            embedding = np.array(response_body['embedding'], dtype=np.float32)
            
            # FAISS 인덱스 차원에 맞게 조정 (768차원)
            if len(embedding) > 768:
                # 1536차원을 768차원으로 축소 (앞쪽 768개만 사용)
                embedding = embedding[:768]
            elif len(embedding) < 768:
                # 부족한 차원은 0으로 패딩
                padding = np.zeros(768 - len(embedding), dtype=np.float32)
                embedding = np.concatenate([embedding, padding])
            
            return embedding
            
        except Exception as e:
            print(f"❌ 임베딩 생성 실패: {str(e)}")
            # 임베딩 실패 시 더미 벡터 반환 (768차원에 맞춤)
            return np.random.rand(768).astype(np.float32)
    
    def search_similar_documents(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """쿼리와 유사한 문서들을 검색합니다."""
        # FAISS 인덱스가 있지만 메타데이터가 없는 경우 SQLite 폴백 사용
        if not FAISS_AVAILABLE or self.index is None or self.metadata is None:
            return self._fallback_search(query, top_k)
        
        try:
            # 쿼리 임베딩 생성
            query_embedding = self.get_text_embedding(query)
            query_embedding = query_embedding.reshape(1, -1)
            
            # FAISS 검색
            scores, indices = self.index.search(query_embedding, top_k)
            
            results = []
            for i, (score, idx) in enumerate(zip(scores[0], indices[0])):
                if idx < len(self.metadata):
                    doc = self.metadata[idx].copy()
                    doc['similarity_score'] = float(score)
                    doc['rank'] = i + 1
                    results.append(doc)
            
            return results
            
        except Exception as e:
            print(f"❌ FAISS 검색 실패: {str(e)}")
            return self._fallback_search(query, top_k)
    
    def _fallback_search(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """FAISS가 실패했을 때 SQLite 기반 폴백 검색"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # 간단한 키워드 검색 (실제 테이블 구조에 맞게 수정)
            keywords = query.split()
            where_conditions = []
            params = []
            
            for keyword in keywords:
                where_conditions.append("(name LIKE ? OR effect LIKE ? OR full_text LIKE ?)")
                params.extend([f"%{keyword}%", f"%{keyword}%", f"%{keyword}%"])
            
            where_clause = " OR ".join(where_conditions) if where_conditions else "1=1"
            
            cursor.execute(f"""
                SELECT name, company, effect, full_text
                FROM drugs 
                WHERE {where_clause}
                LIMIT ?
            """, params + [top_k])
            
            results = []
            for row in cursor.fetchall():
                results.append({
                    'name': row[0] or '',
                    'company': row[1] or '',
                    'effect': row[2] or '',
                    'full_text': row[3] or '',
                    'similarity_score': 0.8,  # 임의 점수
                    'rank': len(results) + 1,
                    'source': 'sqlite_fallback'
                })
            
            conn.close()
            return results
            
        except Exception as e:
            print(f"❌ 폴백 검색도 실패: {str(e)}")
            return []
    
    def get_supplement_interactions(self, supplement_names: List[str]) -> List[Dict[str, Any]]:
        """영양제 간 상호작용 정보를 검색합니다."""
        interactions = []
        
        for supplement in supplement_names:
            query = f"{supplement} 상호작용 부작용 주의사항"
            results = self.search_similar_documents(query, top_k=3)
            
            for result in results:
                if result.get('full_text'):
                    interactions.append({
                        'supplement': supplement,
                        'interaction_info': result['full_text'][:200] + "...",  # 처음 200자만
                        'effect': result.get('effect', ''),
                        'confidence': result.get('similarity_score', 0.5)
                    })
        
        return interactions
    
    def get_context_for_recommendation(self, user_info: Dict[str, Any], health_concerns: List[str]) -> str:
        """영양제 추천을 위한 컨텍스트를 생성합니다."""
        context_parts = []
        
        # 건강 관심사별 검색
        for concern in health_concerns:
            query = f"{concern} 영양제 추천 효과"
            results = self.search_similar_documents(query, top_k=2)
            
            for result in results:
                context_parts.append(f"[{concern} 관련] {result.get('name', '')}: {result.get('effect', '')}")
        
        # 나이대별 추천
        age = user_info.get('age', 65)
        if age >= 65:
            query = "시니어 노인 영양제 추천"
        elif age >= 50:
            query = "중년 영양제 추천"
        else:
            query = "성인 영양제 추천"
            
        age_results = self.search_similar_documents(query, top_k=3)
        for result in age_results:
            context_parts.append(f"[연령대 추천] {result.get('name', '')}: {result.get('effect', '')}")
        
        # 성별별 추천
        gender = user_info.get('gender', '')
        if gender in ['여성', 'female']:
            query = "여성 영양제 추천"
            gender_results = self.search_similar_documents(query, top_k=2)
            for result in gender_results:
                context_parts.append(f"[여성 추천] {result.get('name', '')}: {result.get('effect', '')}")
        
        return "\n".join(context_parts[:10])  # 최대 10개 컨텍스트
    
    def get_safety_information(self, supplements: List[str]) -> str:
        """영양제 안전성 정보를 검색합니다."""
        safety_info = []
        
        for supplement in supplements:
            query = f"{supplement} 안전성 부작용 주의사항 금기"
            results = self.search_similar_documents(query, top_k=2)
            
            for result in results:
                if result.get('full_text'):
                    safety_info.append(f"{supplement}: {result.get('full_text', '')[:100]}...")  # 처음 100자만
        
        return "\n".join(safety_info)

# 전역 RAG 시스템 인스턴스
rag_system = None

def get_rag_system():
    """RAG 시스템 싱글톤 인스턴스를 반환합니다."""
    global rag_system
    if rag_system is None:
        rag_system = RAGSystem()
    return rag_system

if __name__ == "__main__":
    # 테스트 코드
    rag = RAGSystem()
    
    print("🧪 RAG 시스템 테스트")
    print("=" * 50)
    
    # 검색 테스트
    query = "비타민 D 효과"
    results = rag.search_similar_documents(query, top_k=3)
    
    print(f"검색 쿼리: {query}")
    print(f"검색 결과: {len(results)}개")
    
    for i, result in enumerate(results, 1):
        print(f"\n{i}. {result.get('name', 'Unknown')}")
        print(f"   유사도: {result.get('similarity_score', 0):.3f}")
        print(f"   설명: {result.get('description', 'N/A')[:100]}...")
    
    # 컨텍스트 생성 테스트
    user_info = {'age': 70, 'gender': '여성'}
    health_concerns = ['혈압', '골다공증']
    context = rag.get_context_for_recommendation(user_info, health_concerns)
    
    print(f"\n컨텍스트 생성 결과:")
    print(context[:300] + "..." if len(context) > 300 else context)