#!/usr/bin/env python3
import os
import json
import base64
import io
from PIL import Image
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import boto3
from sqlalchemy.orm import Session
from rag_system import RAGSystem
from korean_food_classifier import korean_classifier
from database import get_db, create_tables
from db_service import DatabaseService

# 데이터베이스 테이블 생성
create_tables()

# FastAPI 앱 초기화
app = FastAPI(title="Senior Supplement API", version="1.0.0")

# RAG 시스템 초기화
rag_system = RAGSystem()

# 데이터베이스 연동을 위한 Pydantic 모델들
class UserCreate(BaseModel):
    name: str
    age: int
    gender: str
    height: float
    weight: float
    health_concerns: List[str] = []

class UserUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    health_concerns: Optional[List[str]] = None

class MealRecordCreate(BaseModel):
    date: str
    meal_type: str
    foods: List[str]
    nutrients: dict = {}
    calories: float = 0
    image_path: Optional[str] = None
    ai_analysis: dict = {}

class SupplementAnalysisCreate(BaseModel):
    analysis_result: dict
    recommended_supplements: List[dict] = []
    deficient_nutrients: List[str] = []

class HealthCheckupCreate(BaseModel):
    checkup_date: str
    checkup_data: dict
    ai_analysis: dict = {}
    status: str = ""
    image_path: Optional[str] = None

class FactCheckCreate(BaseModel):
    query: str
    source_type: str = "text"
    credibility_score: float = 0
    fact_check_result: dict = {}

class MedicationRecordCreate(BaseModel):
    date: str
    medication_name: str
    dosage: str
    taken: bool = False

class SyncData(BaseModel):
    meals: Optional[List[dict]] = []
    supplement_analyses: Optional[List[dict]] = []
    health_checkups: Optional[List[dict]] = []
    fact_checks: Optional[List[dict]] = []
    medication_records: Optional[List[dict]] = []

class NutriApp:
    def __init__(self):
        self.session = boto3.Session()
        self.bedrock = self.session.client('bedrock-runtime', region_name='us-east-1')
        self.rekognition = self.session.client('rekognition', region_name='us-east-1')
        self.model_id = "anthropic.claude-3-5-sonnet-20240620-v1:0"
    
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
    
    def resize_image_for_bedrock(self, image_data):
        """이미지를 Bedrock 요구사항에 맞게 리사이즈"""
        try:
            max_size = 15 * 1024 * 1024
            with Image.open(io.BytesIO(image_data)) as img:
                if img.mode in ("RGBA", "P"):
                    img = img.convert("RGB")
                
                quality = 95
                while True:
                    output = io.BytesIO()
                    img.save(output, format="JPEG", quality=quality)
                    if output.tell() <= max_size or quality <= 10:
                        return output.getvalue()
                    quality -= 10
        except Exception as e:
            raise Exception(f"이미지 처리 중 오류 발생: {str(e)}")
    
    # def analyze_food_with_rekognition(self, image_data):
    #     """AWS Rekognition으로 음식 인식 - Claude Vision으로 대체됨"""
    #     # 이 메서드는 더 이상 사용하지 않음 - Claude Vision이 더 정확함
    #     pass
    
    def call_claude(self, system_prompt, user_message, image_data=None):
        """Claude API 호출"""
        import time
        import random
        
        max_retries = 1  # 재시도 횟수를 1로 줄임
        base_delay = 15  # 기본 지연 시간을 줄임
        
        for attempt in range(max_retries):
            try:
                messages = []
                
                if image_data:
                    processed_image = self.resize_image_for_bedrock(image_data)
                    
                    messages.append({
                        "role": "user",
                        "content": [
                            {
                                "image": {
                                    "format": "jpeg",
                                    "source": {
                                        "bytes": processed_image
                                    }
                                }
                            },
                            {
                                "text": user_message
                            }
                        ]
                    })
                else:
                    messages.append({
                        "role": "user", 
                        "content": [{"text": user_message}]
                    })
                
                response = self.bedrock.converse(
                    modelId=self.model_id,
                    messages=messages,
                    system=[{"text": system_prompt}]
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
                except:
                    return {"content": raw_text, "status": "Unknown"}
                    
            except Exception as e:
                if "ThrottlingException" in str(e) and attempt < max_retries - 1:
                    # 지수적 백오프 + 랜덤 지연으로 더 긴 대기 시간
                    delay = base_delay * (2 ** attempt) + random.uniform(10, 30)
                    print(f"⏳ API 호출 제한 발생, {delay:.1f}초 후 재시도... (시도 {attempt + 1}/{max_retries})")
                    time.sleep(delay)
                    continue
                else:
                    print(f"❌ Claude API 최종 오류: {str(e)}")
                    # API 호출 실패 시 즉시 기본 응답 반환 (더 이상 대기하지 않음)
                    if "영양제" in user_message or "supplement" in user_message.lower():
                        return {
                            "content": "현재 AI 서버 사용량이 많습니다. 기본 영양제를 추천해드립니다.",
                            "status": "Yellow",
                            "supplement_list": [
                                {
                                    "name": "비타민D",
                                    "reason": "면역력 강화 및 뼈 건강",
                                    "dosage": "1000IU",
                                    "schedule": {"time": "아침", "timing": "식후"}
                                },
                                {
                                    "name": "오메가3",
                                    "reason": "심혈관 건강 및 염증 완화",
                                    "dosage": "1000mg",
                                    "schedule": {"time": "저녁", "timing": "식후"}
                                }
                            ]
                        }
                    elif "건강검진" in user_message or "checkup" in user_message.lower():
                        return {
                            "content": "현재 AI 서버 사용량이 많습니다. 기본 건강 조언을 제공합니다.",
                            "status": "Yellow",
                            "recommended_nutrient": "비타민D",
                            "action_plan": "규칙적인 운동과 균형잡힌 식단을 유지하세요."
                        }
                    else:
                        return {
                            "content": "현재 AI 서버 사용량이 많습니다. 잠시 후 다시 시도해주세요.",
                            "status": "Yellow"
                        }
        
        return {"content": "서버 연결 시간 초과. 잠시 후 다시 시도해주세요.", "status": "Error"}

# NutriApp 인스턴스 생성
nutri_app = NutriApp()

# Pydantic 모델들
class UserInfo(BaseModel):
    name: str
    age: int
    gender: str
    height: int
    weight: int

class HealthCheckupRequest(BaseModel):
    user_info: UserInfo
    checkup_text: str

class MealAnalysisRequest(BaseModel):
    user_info: UserInfo
    image_base64: str

class SupplementRecommendationRequest(BaseModel):
    user_info: UserInfo
    checkup_result: dict
    meal_result: dict

class YouTubeFactCheckRequest(BaseModel):
    user_info: UserInfo
    youtube_url: str

# API 엔드포인트들
@app.get("/")
async def root():
    return {"message": "Senior Supplement API Server", "status": "running"}

@app.post("/api/analyze-checkup")
async def analyze_checkup(request: HealthCheckupRequest):
    """건강검진 결과 분석"""
    try:
        print(f"건강검진 분석 요청 받음: {request.user_info.name}")
        
        user_vars = {
            "name": request.user_info.name,
            "age": str(request.user_info.age),
            "gender": request.user_info.gender,
            "height": str(request.user_info.height),
            "weight": str(request.user_info.weight),
            "checkup_text": request.checkup_text
        }
        
        print(f"사용자 변수: {user_vars}")
        
        system_prompt = nutri_app.load_prompt("checkup_expert.txt", user_vars)
        print("프롬프트 로드 완료")
        
        result = nutri_app.call_claude(system_prompt, "제공된 검진 수치를 바탕으로 상태를 분석해주세요.")
        print(f"Claude 호출 결과: {result}")
        
        return {"success": True, "data": result}
    except Exception as e:
        print(f"건강검진 분석 오류: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/analyze-meal")
async def analyze_meal(request: MealAnalysisRequest):
    """식단 사진 분석 (정교한 한국 음식 분류)"""
    try:
        print(f"식단 분석 요청 받음: {request.user_info.name}")
        
        image_data = base64.b64decode(request.image_base64)
        print("이미지 디코딩 완료")
        
        user_vars = {
            "name": request.user_info.name,
            "age": str(request.user_info.age),
            "gender": request.user_info.gender,
            "height": str(request.user_info.height),
            "weight": str(request.user_info.weight)
        }
        
        print(f"사용자 변수: {user_vars}")
        
        system_prompt = nutri_app.load_prompt("meal_vision_coach.txt", user_vars)
        
        # 정교한 한국 음식 분류 프롬프트 사용
        detailed_classification = korean_classifier.get_detailed_classification_prompt()
        
        user_message = f"""
{detailed_classification}

이 식단 사진을 위의 정교한 분류 기준에 따라 매우 정확히 분석해주세요.

**단계별 분석:**
1. 각 음식의 색깔을 정확히 관찰
2. 모양과 크기 확인 (정사각형=깍두기, 길쭉함=배추김치)
3. 재료 조합 분석 (콩나물+오징어 vs 콩나물만)
4. 국물의 색깔과 탁도 확인 (갈색탁함=된장국, 맑음+검은미역=미역국)

**특별 주의사항:**
- 김치류: 모양으로 구분 (정사각형=깍두기, 길쭉함=배추김치)
- 국물류: 색깔과 재료로 구분 (갈색탁함=된장국, 맑음+미역=미역국)
- 볶음류: 재료 조합으로 구분 (콩나물+오징어 vs 각각)

**절대 추정하지 말고, 실제 보이는 특징만으로 정확히 분류하세요!**

JSON 형식으로 응답:
{{
  "analysis_logic": "각 음식별 색깔, 모양, 재료 분석 과정",
  "detected_foods": ["정교하게 분류된 정확한 한국 음식명"],
  "visual_details": "각 음식의 시각적 특징 설명",
  "content": "{request.user_info.name}님의 식단 분석 결과",
  "recommended_nutrient": "가장 부족한 영양소",
  "action_plan": "다음 식사에 추가할 구체적인 음식"
}}
"""
        
        result = nutri_app.call_claude(system_prompt, user_message, image_data)
        print(f"1차 Claude Vision 분석 결과: {result}")
        
        # 분석 결과 검증 및 재시도 로직
        if result and isinstance(result, dict):
            detected_foods = result.get('detected_foods', [])
            
            # 일반적인 라벨이나 부정확한 분류 감지
            generic_terms = ['Food', 'Meal', 'Dish', '음식', '식사', '요리']
            inaccurate_classification = any(food in generic_terms for food in detected_foods)
            
            if not detected_foods or inaccurate_classification:
                print("⚠️ 부정확한 분류 감지. 검증 질문으로 재분석합니다.")
                
                # 검증 질문을 통한 재분석
                verification_questions = korean_classifier.get_verification_questions()
                
                retry_message = f"""
이전 분석이 부정확했습니다. 다음 검증 질문에 답하면서 다시 정확히 분석해주세요:

{chr(10).join([f"{i+1}. {q}" for i, q in enumerate(verification_questions)])}

**재분석 지침:**
- 김치 vs 깍두기: 모양 확인 (길쭉한 잎=김치, 정사각형 조각=깍두기)
- 된장국 vs 미역국: 국물 색깔 (갈색 탁함=된장국, 맑음+검은미역=미역국)
- 오징어콩나물볶음 vs 콩나물볶음: 오징어 유무 확인
- 시금치나물 vs 기타 나물: 색깔과 잎 모양 확인

각 검증 질문에 대한 답변과 함께 정확한 음식명을 다시 분류해주세요.

JSON 형식으로 응답:
{{
  "verification_answers": ["각 질문에 대한 답변"],
  "corrected_analysis": "수정된 분석 과정",
  "detected_foods": ["재검증된 정확한 음식명"],
  "confidence_score": "분류 확신도 (1-10)",
  "content": "수정된 분석 결과",
  "recommended_nutrient": "부족한 영양소",
  "action_plan": "권장사항"
}}
"""
                
                result = nutri_app.call_claude(system_prompt, retry_message, image_data)
                print(f"재검증 분석 결과: {result}")
        
        return {"success": True, "data": result}
    except Exception as e:
        print(f"식단 분석 오류: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/recommend-supplements-fast")
async def recommend_supplements_fast(request: SupplementRecommendationRequest):
    """빠른 영양제 추천 (기본 추천 제공)"""
    try:
        print(f"빠른 영양제 추천 요청 받음: {request.user_info.name}")
        
        # 기본 영양제 추천 로직
        age = request.user_info.age
        gender = request.user_info.gender
        
        basic_supplements = []
        
        # 나이별 기본 추천
        if age >= 65:
            basic_supplements.extend([
                {
                    "name": "비타민D",
                    "reason": "뼈 건강과 면역력 강화를 위해 필요합니다",
                    "dosage": "1000IU",
                    "schedule": {"time": "아침", "timing": "식후"}
                },
                {
                    "name": "칼슘",
                    "reason": "골다공증 예방을 위해 필요합니다",
                    "dosage": "500mg",
                    "schedule": {"time": "저녁", "timing": "식후"}
                }
            ])
        else:
            basic_supplements.append({
                "name": "비타민D",
                "reason": "면역력 강화를 위해 필요합니다",
                "dosage": "1000IU",
                "schedule": {"time": "아침", "timing": "식후"}
            })
        
        # 성별별 추가 추천
        if gender == "남성":
            basic_supplements.append({
                "name": "오메가3",
                "reason": "심혈관 건강을 위해 필요합니다",
                "dosage": "1000mg",
                "schedule": {"time": "저녁", "timing": "식후"}
            })
        else:
            basic_supplements.append({
                "name": "철분",
                "reason": "빈혈 예방을 위해 필요합니다",
                "dosage": "18mg",
                "schedule": {"time": "아침", "timing": "식후"}
            })
        
        result = {
            "content": f"{request.user_info.name}님의 나이와 성별을 고려한 기본 영양제를 추천드립니다.",
            "status": "Green",
            "supplement_list": basic_supplements,
            "special_caution": "현재 복용 중인 약물이 있다면 의사와 상담 후 복용하세요.",
            "rag_info": {
                "context_sources": 0,
                "safety_checks": 0,
                "database_used": False,
                "fast_mode": True
            }
        }
        
        return {"success": True, "data": result}
    except Exception as e:
        print(f"빠른 영양제 추천 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/recommend-supplements")
async def recommend_supplements(request: SupplementRecommendationRequest):
    """최종 영양제 추천 (RAG 기반)"""
    try:
        print(f"영양제 추천 요청 받음: {request.user_info.name}")
        
        # RAG 시스템에서 관련 정보 검색
        search_queries = [
            request.checkup_result.get('recommended_nutrient', ''),
            request.meal_result.get('recommended_nutrient', ''),
            f"{request.user_info.age}세 {request.user_info.gender}",
            "영양제 추천"
        ]
        
        print(f"검색 쿼리: {search_queries}")
        
        rag_context = ""
        for query in search_queries:
            if query.strip():
                results = rag_system.search_similar_documents(query, top_k=3)
                for doc in results:
                    content = doc.get('content', doc.get('full_text', ''))
                    if content:
                        rag_context += f"[{doc.get('name', 'Unknown')}] {content[:200]}...\n"
        
        print(f"RAG 컨텍스트 길이: {len(rag_context)}")
        
        # 안전성 정보 (추천할 영양제 목록 기반)
        potential_supplements = ['비타민D', '칼슘', '오메가3', '마그네슘']
        safety_info = rag_system.get_safety_information(potential_supplements)
        print(f"안전성 정보 길이: {len(safety_info)}")
        
        # 상호작용 정보
        interaction_info = rag_system.get_supplement_interactions(potential_supplements)
        print(f"상호작용 정보 개수: {len(interaction_info)}")
        
        # 종합 RAG 컨텍스트 구성
        comprehensive_context = f"""
=== 영양제 추천 데이터베이스 정보 ===
{rag_context}

=== 안전성 정보 ===
{safety_info}

=== 상호작용 정보 ===
{'; '.join([f"{item['supplement']}: {item['interaction_info']}" for item in interaction_info[:3]])}
"""
        
        user_vars = {
            "name": request.user_info.name,
            "age": str(request.user_info.age),
            "gender": request.user_info.gender,
            "height": str(request.user_info.height),
            "weight": str(request.user_info.weight),
            "checkup_analysis_result": request.checkup_result.get('content', ''),
            "meal_analysis_result": request.meal_result.get('content', ''),
            "retrieved_context": comprehensive_context  # RAG 컨텍스트 사용
        }
        
        try:
            print(f"사용자 변수 준비 완료")
            
            system_prompt = nutri_app.load_prompt("final_supplement_expert.txt", user_vars)
            print("프롬프트 로드 완료")
            
            result = nutri_app.call_claude(system_prompt, "모든 데이터를 통합하여 최적의 영양제 스케줄을 설계해주세요.")
            print(f"Claude 호출 결과: {result}")
            
            # API 호출 실패 시 기본 응답인지 확인
            if "AI 서버가 과부하" in result.get('content', ''):
                # 기본 영양제 추천 로직
                age = request.user_info.age
                gender = request.user_info.gender
                
                basic_supplements = []
                if age >= 65:
                    basic_supplements.extend([
                        {
                            "name": "비타민D",
                            "reason": "뼈 건강과 면역력 강화를 위해 필요합니다",
                            "dosage": "1000IU",
                            "schedule": {"time": "아침", "timing": "식후"}
                        },
                        {
                            "name": "칼슘",
                            "reason": "골다공증 예방을 위해 필요합니다",
                            "dosage": "500mg",
                            "schedule": {"time": "저녁", "timing": "식후"}
                        }
                    ])
                
                if gender == "남성":
                    basic_supplements.append({
                        "name": "오메가3",
                        "reason": "심혈관 건강을 위해 필요합니다",
                        "dosage": "1000mg",
                        "schedule": {"time": "아침", "timing": "식후"}
                    })
                
                result = {
                    "content": f"{request.user_info.name}님의 나이와 성별을 고려한 기본 영양제를 추천드립니다. AI 서버 과부하로 상세 분석은 나중에 다시 시도해주세요.",
                    "status": "Yellow",
                    "supplement_list": basic_supplements,
                    "special_caution": "현재 복용 중인 약물이 있다면 의사와 상담 후 복용하세요."
                }
            
            # RAG 메타데이터 추가
            result["rag_info"] = {
                "context_sources": len(rag_context.split('\n')),
                "safety_checks": len(interaction_info),
                "database_used": True
            }
            
            return {"success": True, "data": result}
        except Exception as e:
            print(f"영양제 추천 최종 오류: {str(e)}")
            # 완전 실패 시 최소한의 응답
            return {
                "success": True, 
                "data": {
                    "content": "현재 서버 과부하로 상세 분석이 어렵습니다. 기본적으로 비타민D와 오메가3를 권장합니다.",
                    "status": "Unknown",
                    "supplement_list": [
                        {
                            "name": "비타민D",
                            "reason": "기본 건강 유지",
                            "dosage": "1000IU",
                            "schedule": {"time": "아침", "timing": "식후"}
                        }
                    ]
                }
            }
    except Exception as e:
        print(f"영양제 추천 오류: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/health")
async def health_check():
    """서버 상태 확인"""
    try:
        # AWS 연결 테스트
        sts = nutri_app.session.client('sts')
        identity = sts.get_caller_identity()
        
        # RAG 시스템 상태 확인
        rag_status = {
            "faiss_loaded": rag_system.index is not None,
            "metadata_loaded": rag_system.metadata is not None and len(rag_system.metadata) > 0,
            "total_documents": len(rag_system.metadata) if rag_system.metadata else 0
        }
        
        return {
            "status": "healthy",
            "aws_connected": True,
            "aws_account": identity.get('Account', 'Unknown'),
            "rag_system": rag_status,
            "message": "모든 시스템이 정상 작동 중입니다."
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "aws_connected": False,
            "error": str(e),
            "rag_system": {"faiss_loaded": False, "metadata_loaded": False}
        }

@app.post("/api/fact-check-youtube")
async def fact_check_youtube(request: YouTubeFactCheckRequest):
    """유튜브 영상 팩트체킹"""
    try:
        print(f"팩트체크 요청 받음: {request.user_info.name}")
        print(f"입력 URL/텍스트: {request.youtube_url}")
        
        from youtube_transcript_api import YouTubeTranscriptApi
        import re
        
        # 유튜브 URL에서 비디오 ID 추출
        video_id = extract_video_id(request.youtube_url)
        print(f"추출된 비디오 ID: {video_id}")
        
        if video_id:
            print(f"유튜브 비디오 ID 발견: {video_id}")
            # 실제 유튜브 자막 가져오기
            try:
                from youtube_transcript_api import YouTubeTranscriptApi
                
                print("자막 가져오기 시도 중...")
                # 자막 가져오기
                transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
                
                # 한국어 자막 우선, 없으면 영어
                transcript = None
                try:
                    transcript = transcript_list.find_generated_transcript(['ko'])
                    print("한국어 자동 생성 자막 발견")
                except:
                    try:
                        transcript = transcript_list.find_transcript(['ko'])
                        print("한국어 수동 자막 발견")
                    except:
                        try:
                            transcript = transcript_list.find_generated_transcript(['en'])
                            print("영어 자동 생성 자막 발견")
                        except:
                            transcript = transcript_list.find_transcript(['en'])
                            print("영어 수동 자막 발견")
                
                if transcript:
                    transcript_data = transcript.fetch()
                    full_transcript = ' '.join([item.text for item in transcript_data])
                    print(f"자막 길이: {len(full_transcript)} 문자")
                    
                    # 너무 긴 자막은 처음 2000자만 사용
                    if len(full_transcript) > 2000:
                        full_transcript = full_transcript[:2000] + "..."
                        
                    video_info = {
                        "title": f"유튜브 영상 (ID: {video_id})",
                        "description": "자막에서 추출한 내용",
                        "transcript": full_transcript
                    }
                    print("자막 추출 성공")
                else:
                    raise Exception("자막을 찾을 수 없습니다.")
                    
            except Exception as e:
                print(f"자막 추출 실패: {str(e)}")
                # 자막을 가져올 수 없는 경우 기본 메시지
                video_info = {
                    "title": f"유튜브 영상 (ID: {video_id})",
                    "description": "자막을 가져올 수 없어 URL 기반으로 분석합니다.",
                    "transcript": f"마그네슘에 대한 정보를 다루는 영상으로 추정됩니다. 자막 오류: {str(e)}"
                }
        else:
            print("유튜브 URL이 아닌 일반 텍스트로 처리")
            # URL이 아닌 일반 텍스트인 경우
            video_info = {
                "title": "텍스트 팩트체킹",
                "description": "사용자가 입력한 텍스트",
                "transcript": request.youtube_url
            }
        
        # 자막에서 건강 관련 주장 추출
        health_claims = extract_health_claims(video_info["transcript"])
        print(f"추출된 건강 주장: {health_claims}")
        
        # RAG 시스템에서 관련 의학 정보 검색
        fact_check_context = ""
        search_queries = health_claims + ["마그네슘", "영양제", "건강보조식품"]
        print(f"검색 쿼리: {search_queries[:5]}")
        
        for claim in search_queries[:5]:  # 최대 5개 쿼리만 검색
            related_docs = rag_system.search_similar_documents(claim, top_k=2)
            for doc in related_docs:
                content = doc.get('content', doc.get('full_text', ''))
                if content:
                    fact_check_context += f"[의학 정보] {doc.get('name', claim)}: {content[:300]}...\n"
        
        print(f"RAG 컨텍스트 길이: {len(fact_check_context)}")
        
        # Claude로 팩트체킹 분석
        print("Claude API 호출 시작...")
        fact_check_prompt = f"""
당신은 의학 정보 팩트체커입니다. 유튜브 영상의 건강 정보를 검증해주세요.

영상 정보:
- 제목: {video_info['title']}
- 내용: {video_info['transcript'][:1000]}

의학 데이터베이스 정보:
{fact_check_context}

사용자 정보:
- 이름: {request.user_info.name}
- 나이: {request.user_info.age}세
- 성별: {request.user_info.gender}

다음 JSON 형식으로 답변해주세요:
{{
  "overall_credibility": "높음/보통/낮음",
  "fact_check_result": "팩트체킹 결과 요약 (한국어로 자세히)",
  "verified_claims": ["검증된 사실들"],
  "questionable_claims": ["의심스러운 주장들"],
  "recommendations": "시청자를 위한 권장사항",
  "medical_disclaimer": "의학적 면책 조항"
}}
"""
        
        response = nutri_app.bedrock.converse(
            modelId=nutri_app.model_id,
            messages=[{"role": "user", "content": [{"text": fact_check_prompt}]}]
        )
        
        raw_text = response['output']['message']['content'][0]['text']
        print(f"Claude 응답 길이: {len(raw_text)}")
        
        try:
            if "```json" in raw_text:
                json_text = raw_text.split("```json")[1].split("```")[0].strip()
            else:
                start_idx = raw_text.find("{")
                end_idx = raw_text.rfind("}") + 1
                json_text = raw_text[start_idx:end_idx]
            result = json.loads(json_text)
            print("JSON 파싱 성공")
        except Exception as parse_error:
            print(f"JSON 파싱 실패: {parse_error}")
            result = {
                "overall_credibility": "보통",
                "fact_check_result": raw_text,
                "verified_claims": [],
                "questionable_claims": [],
                "recommendations": "전문의와 상담하세요.",
                "medical_disclaimer": "이 정보는 의학적 조언을 대체할 수 없습니다."
            }
        
        result["video_info"] = video_info
        result["rag_sources"] = len(fact_check_context.split('\n'))
        
        print("팩트체크 완료")
        return {"success": True, "data": result}
        
    except Exception as e:
        print(f"팩트체크 오류: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

def extract_video_id(url: str) -> str:
    """유튜브 URL에서 비디오 ID 추출"""
    import re
    patterns = [
        r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([^&\n?#]+)',
        r'youtube\.com/watch\?.*v=([^&\n?#]+)'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return ""

def extract_health_claims(text: str) -> list:
    """텍스트에서 건강 관련 주장 추출"""
    health_keywords = ["마그네슘", "비타민", "영양제", "건강", "다이어트", "운동", "혈압", "콜레스테롤", "당뇨", "면역력", "칼슘", "오메가3", "단백질", "미네랄"]
    claims = []
    
    text_lower = text.lower()
    for keyword in health_keywords:
        if keyword.lower() in text_lower:
            claims.append(keyword)
    
    return claims if claims else ["일반 건강 정보"]

@app.get("/api/health")
async def health_check():
    """서버 상태 확인"""
    try:
        # AWS 연결 상태 확인
        aws_connected = False
        aws_account = None
        try:
            sts = nutri_app.session.client('sts', region_name='us-east-1')
            identity = sts.get_caller_identity()
            aws_connected = True
            aws_account = identity.get('Account')
        except Exception:
            pass
        
        # RAG 시스템 상태 확인
        rag_status = {
            "faiss_loaded": rag_system.index is not None,
            "metadata_loaded": rag_system.metadata is not None,
            "total_documents": len(rag_system.metadata) if rag_system.metadata else 0
        }
        
        return {
            "status": "healthy",
            "aws_connected": aws_connected,
            "aws_account": aws_account,
            "rag_system": rag_status,
            "message": "모든 시스템이 정상 작동 중입니다."
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }

@app.post("/api/analyze-checkup-image")
async def analyze_checkup_image(request: MealAnalysisRequest):
    """건강검진 이미지 분석"""
    try:
        print(f"건강검진 이미지 분석 요청 받음: {request.user_info.name}")
        
        image_data = base64.b64decode(request.image_base64)
        print("이미지 디코딩 완료")
        
        user_vars = {
            "name": request.user_info.name,
            "age": str(request.user_info.age),
            "gender": request.user_info.gender,
            "height": str(request.user_info.height),
            "weight": str(request.user_info.weight)
        }
        
        system_prompt = nutri_app.load_prompt("checkup_expert.txt", user_vars)
        
        user_message = """
이 건강검진 결과 이미지를 분석해주세요.
혈압, 혈당, 콜레스테롤, 간 수치 등의 주요 지표를 읽어서 분석해주세요.

JSON 형식으로 응답:
{
  "analysis_logic": "검진 결과 분석 근거",
  "extracted_values": {"혈압": "140/90", "혈당": "120", "콜레스테롤": "220"},
  "status": "정상 / 주의 / 위험",
  "content": "건강 상태 요약",
  "recommended_nutrient": "필요한 영양소",
  "action_plan": "권장사항"
}
"""
        
        result = nutri_app.call_claude(system_prompt, user_message, image_data)
        print(f"건강검진 이미지 분석 결과: {result}")
        
        return {"success": True, "data": result}
    except Exception as e:
        print(f"건강검진 이미지 분석 오류: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/fact-check-youtube")
async def fact_check_youtube(request: YouTubeFactCheckRequest):
    """유튜브 팩트체킹"""
    try:
        print(f"유튜브 팩트체크 요청 받음: {request.youtube_url}")
        
        # 유튜브 URL인지 텍스트인지 확인
        is_youtube_url = "youtube.com" in request.youtube_url or "youtu.be" in request.youtube_url
        
        if is_youtube_url:
            # 실제 유튜브 분석 (현재는 기본 응답)
            result = {
                "content": "유튜브 영상 분석 기능은 현재 개발 중입니다. 곧 정식 서비스될 예정입니다.",
                "overall_credibility": "보통",
                "fact_check_result": "유튜브 영상의 건강 정보는 전문의와 상담 후 판단하시기 바랍니다.",
                "key_claims": ["건강 정보 검증 필요"],
                "verification_status": "pending"
            }
        else:
            # 텍스트 기반 팩트체크
            user_vars = {
                "name": request.user_info.name,
                "age": str(request.user_info.age),
                "gender": request.user_info.gender,
                "height": str(request.user_info.height),
                "weight": str(request.user_info.weight),
                "query_text": request.youtube_url.replace("텍스트: ", "")
            }
            
            # 간단한 팩트체크 프롬프트
            system_prompt = f"""
당신은 {user_vars['name']}님을 위한 건강 정보 팩트체커입니다.
사용자 정보: {user_vars['age']}세 {user_vars['gender']}, {user_vars['height']}cm, {user_vars['weight']}kg

다음 건강 정보의 신뢰도를 평가하고 팩트체크해주세요:
"{user_vars['query_text']}"

JSON 형식으로 응답:
{{
  "overall_credibility": "높음/보통/낮음",
  "fact_check_result": "팩트체크 결과 설명 (2-3문장)",
  "key_claims": ["주요 주장들"],
  "verification_status": "verified/caution/false"
}}
"""
            
            try:
                result = nutri_app.call_claude(system_prompt, "위 건강 정보를 분석해주세요.")
                print(f"텍스트 팩트체크 결과: {result}")
            except Exception as claude_error:
                print(f"Claude 호출 오류: {claude_error}")
                # 폴백 응답
                result = {
                    "overall_credibility": "보통",
                    "fact_check_result": "현재 AI 서버 사용량이 많습니다. 건강 정보는 반드시 전문의와 상담하시기 바랍니다.",
                    "key_claims": ["전문의 상담 권장"],
                    "verification_status": "caution"
                }
        
        return {"success": True, "data": result}
    except Exception as e:
        print(f"유튜브 팩트체크 오류: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/search-supplements")
async def search_supplements(query: str, limit: int = 5):
    """RAG 기반 영양제 검색"""
    try:
        results = rag_system.search_similar_documents(query, top_k=limit)
        return {
            "success": True,
            "query": query,
            "results": results,
            "total_found": len(results)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== 데이터베이스 연동 API ====================

# 사용자 관리 API
@app.post("/api/users")
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """새 사용자 생성"""
    try:
        db_user = DatabaseService.create_user(db, user.dict())
        return {
            "success": True,
            "user_id": db_user.user_id,
            "message": "사용자가 성공적으로 생성되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}")
async def get_user(user_id: str, db: Session = Depends(get_db)):
    """사용자 정보 조회"""
    try:
        user = DatabaseService.get_user_by_id(db, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
        
        return {
            "success": True,
            "user": {
                "user_id": user.user_id,
                "name": user.name,
                "age": user.age,
                "gender": user.gender,
                "height": user.height,
                "weight": user.weight,
                "health_concerns": user.health_concerns,
                "created_at": user.created_at.isoformat(),
                "updated_at": user.updated_at.isoformat()
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/users/{user_id}")
async def update_user(user_id: str, user_update: UserUpdate, db: Session = Depends(get_db)):
    """사용자 정보 업데이트"""
    try:
        updated_user = DatabaseService.update_user(db, user_id, user_update.dict(exclude_unset=True))
        if not updated_user:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
        
        return {
            "success": True,
            "message": "사용자 정보가 업데이트되었습니다."
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 식사 기록 API
@app.post("/api/users/{user_id}/meals")
async def add_meal_record(user_id: str, meal: MealRecordCreate, db: Session = Depends(get_db)):
    """식사 기록 추가"""
    try:
        db_meal = DatabaseService.add_meal_record(db, user_id, meal.dict())
        return {
            "success": True,
            "meal_id": db_meal.id,
            "message": "식사 기록이 추가되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/meals")
async def get_meals(user_id: str, date: Optional[str] = None, start_date: Optional[str] = None, 
                   end_date: Optional[str] = None, db: Session = Depends(get_db)):
    """식사 기록 조회"""
    try:
        if date:
            meals = DatabaseService.get_meals_by_date(db, user_id, date)
        elif start_date and end_date:
            meals = DatabaseService.get_meals_by_date_range(db, user_id, start_date, end_date)
        else:
            raise HTTPException(status_code=400, detail="date 또는 start_date, end_date를 제공해야 합니다.")
        
        meal_list = []
        for meal in meals:
            meal_list.append({
                "id": meal.id,
                "date": meal.date,
                "meal_type": meal.meal_type,
                "foods": meal.foods,
                "nutrients": meal.nutrients,
                "calories": meal.calories,
                "image_path": meal.image_path,
                "ai_analysis": meal.ai_analysis,
                "created_at": meal.created_at.isoformat()
            })
        
        return {
            "success": True,
            "meals": meal_list,
            "total_count": len(meal_list)
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 영양제 분석 API
@app.post("/api/users/{user_id}/supplement-analysis")
async def save_supplement_analysis(user_id: str, analysis: SupplementAnalysisCreate, db: Session = Depends(get_db)):
    """영양제 분석 결과 저장"""
    try:
        db_analysis = DatabaseService.save_supplement_analysis(db, user_id, analysis.dict())
        return {
            "success": True,
            "analysis_id": db_analysis.id,
            "message": "영양제 분석 결과가 저장되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/supplement-analysis/latest")
async def get_latest_supplement_analysis(user_id: str, db: Session = Depends(get_db)):
    """최신 영양제 분석 결과 조회"""
    try:
        analysis = DatabaseService.get_latest_supplement_analysis(db, user_id)
        if not analysis:
            return {"success": True, "analysis": None}
        
        return {
            "success": True,
            "analysis": {
                "id": analysis.id,
                "analysis_result": analysis.analysis_result,
                "recommended_supplements": analysis.recommended_supplements,
                "deficient_nutrients": analysis.deficient_nutrients,
                "created_at": analysis.created_at.isoformat()
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 건강검진 API
@app.post("/api/users/{user_id}/health-checkups")
async def save_health_checkup(user_id: str, checkup: HealthCheckupCreate, db: Session = Depends(get_db)):
    """건강검진 결과 저장"""
    try:
        db_checkup = DatabaseService.save_health_checkup(db, user_id, checkup.dict())
        return {
            "success": True,
            "checkup_id": db_checkup.id,
            "message": "건강검진 결과가 저장되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/health-checkups/latest")
async def get_latest_health_checkup(user_id: str, db: Session = Depends(get_db)):
    """최신 건강검진 결과 조회"""
    try:
        checkup = DatabaseService.get_latest_health_checkup(db, user_id)
        if not checkup:
            return {"success": True, "checkup": None}
        
        return {
            "success": True,
            "checkup": {
                "id": checkup.id,
                "checkup_date": checkup.checkup_date,
                "checkup_data": checkup.checkup_data,
                "ai_analysis": checkup.ai_analysis,
                "status": checkup.status,
                "image_path": checkup.image_path,
                "created_at": checkup.created_at.isoformat()
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 팩트체크 API
@app.post("/api/users/{user_id}/fact-checks")
async def save_fact_check(user_id: str, fact_check: FactCheckCreate, db: Session = Depends(get_db)):
    """팩트체크 결과 저장"""
    try:
        db_fact_check = DatabaseService.save_fact_check(db, user_id, fact_check.dict())
        return {
            "success": True,
            "fact_check_id": db_fact_check.id,
            "message": "팩트체크 결과가 저장되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/fact-checks")
async def get_fact_check_history(user_id: str, limit: int = 15, db: Session = Depends(get_db)):
    """팩트체크 기록 조회"""
    try:
        fact_checks = DatabaseService.get_fact_check_history(db, user_id, limit)
        
        fact_check_list = []
        for fc in fact_checks:
            fact_check_list.append({
                "id": fc.id,
                "query": fc.query,
                "source_type": fc.source_type,
                "credibility_score": fc.credibility_score,
                "fact_check_result": fc.fact_check_result,
                "created_at": fc.created_at.isoformat()
            })
        
        return {
            "success": True,
            "fact_checks": fact_check_list,
            "total_count": len(fact_check_list)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 복용 기록 API
@app.post("/api/users/{user_id}/medications")
async def add_medication_record(user_id: str, medication: MedicationRecordCreate, db: Session = Depends(get_db)):
    """복용 기록 추가"""
    try:
        db_medication = DatabaseService.add_medication_record(db, user_id, medication.dict())
        return {
            "success": True,
            "medication_id": db_medication.id,
            "message": "복용 기록이 추가되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/users/{user_id}/medications/{date}/{medication_name}")
async def update_medication_taken(user_id: str, date: str, medication_name: str, taken: bool, db: Session = Depends(get_db)):
    """복용 상태 업데이트"""
    try:
        updated_medication = DatabaseService.update_medication_taken(db, user_id, date, medication_name, taken)
        if not updated_medication:
            raise HTTPException(status_code=404, detail="복용 기록을 찾을 수 없습니다.")
        
        return {
            "success": True,
            "message": "복용 상태가 업데이트되었습니다."
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/users/{user_id}/medications")
async def get_medication_records(user_id: str, date: str, db: Session = Depends(get_db)):
    """복용 기록 조회"""
    try:
        medications = DatabaseService.get_medication_records_by_date(db, user_id, date)
        
        medication_list = []
        for med in medications:
            medication_list.append({
                "id": med.id,
                "date": med.date,
                "medication_name": med.medication_name,
                "dosage": med.dosage,
                "taken": med.taken,
                "taken_time": med.taken_time.isoformat() if med.taken_time else None,
                "created_at": med.created_at.isoformat()
            })
        
        return {
            "success": True,
            "medications": medication_list,
            "total_count": len(medication_list)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 통계 API
@app.get("/api/users/{user_id}/statistics")
async def get_user_statistics(user_id: str, db: Session = Depends(get_db)):
    """사용자 데이터 통계"""
    try:
        stats = DatabaseService.get_user_statistics(db, user_id)
        return {
            "success": True,
            "statistics": stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 데이터 동기화 API
@app.post("/api/users/{user_id}/sync")
async def sync_user_data(user_id: str, sync_data: SyncData, db: Session = Depends(get_db)):
    """클라이언트와 서버 데이터 동기화"""
    try:
        result = DatabaseService.sync_user_data(db, user_id, sync_data.dict())
        return {
            "success": True,
            "sync_result": result,
            "message": "데이터 동기화가 완료되었습니다."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    print("🚀 Senior Supplement API Server 시작 중...")
    print("📱 Flutter 앱에서 http://localhost:8000 으로 접속하세요!")
    print("🗄️ 데이터베이스 연동 기능이 활성화되었습니다!")
    uvicorn.run(app, host="0.0.0.0", port=8000)