#!/usr/bin/env python3
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import boto3
import json
import os
import io
from PIL import Image
import base64
from typing import Optional

# RAG 시스템 임포트
from rag_system import get_rag_system

# 요청/응답 모델 정의
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
    image_base64: str  # Base64 인코딩된 이미지

class SupplementRecommendationRequest(BaseModel):
    user_info: UserInfo
    checkup_result: dict
    meal_result: dict

# FastAPI 앱 초기화
app = FastAPI(title="Senior Supplement API", version="1.0.0")

# CORS 설정 (Flutter 앱에서 접근 가능하도록)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 실제 배포시에는 특정 도메인으로 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# NutriScanApp 클래스 (기존 코드 재사용)
class NutriScanApp:
    def __init__(self):
        self.session = boto3.Session()
        self.bedrock = self.session.client(service_name='bedrock-runtime', region_name='us-east-1')
        self.rekognition = self.session.client(service_name='rekognition', region_name='us-east-1')
        self.model_id = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"

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

    def analyze_food_from_base64(self, image_base64):
        """Base64 이미지에서 음식 레이블을 추출합니다."""
        try:
            # Base64 디코딩
            image_data = base64.b64decode(image_base64)
            
            # 이미지 크기 조정 (15MB 제한)
            max_size = 15 * 1024 * 1024
            with Image.open(io.BytesIO(image_data)) as img:
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

            # Rekognition 호출
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

# 앱 인스턴스 생성
nutri_app = NutriScanApp()
rag_system = get_rag_system()  # RAG 시스템 초기화

# API 엔드포인트들
@app.get("/")
async def root():
    return {"message": "Senior Supplement API Server", "status": "running"}

@app.post("/api/analyze-checkup")
async def analyze_checkup(request: HealthCheckupRequest):
    """건강검진 결과 분석"""
    try:
        user_vars = {
            "name": request.user_info.name,
            "age": str(request.user_info.age),
            "gender": request.user_info.gender,
            "height": str(request.user_info.height),
            "weight": str(request.user_info.weight),
            "checkup_text": request.checkup_text
        }
        
        system_prompt = nutri_app.load_prompt("checkup_expert.txt", user_vars)
        result = nutri_app.call_claude(system_prompt, "제공된 검진 수치를 바탕으로 상태를 분석해주세요.")
        
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/analyze-meal")
async def analyze_meal(request: MealAnalysisRequest):
    """식단 사진 분석 (Rekognition + Claude)"""
    try:
        # Rekognition으로 음식 인식
        detected_foods = nutri_app.analyze_food_from_base64(request.image_base64)
        
        # Claude로 영양 분석
        user_vars = {
            "name": request.user_info.name,
            "age": str(request.user_info.age),
            "gender": request.user_info.gender,
            "height": str(request.user_info.height),
            "weight": str(request.user_info.weight)
        }
        
        system_prompt = nutri_app.load_prompt("meal_vision_coach.txt", user_vars)
        food_list_str = ", ".join(detected_foods) if detected_foods else "음식을 인식할 수 없음"
        user_message = f"사진에서 다음 음식들이 인식되었습니다: {food_list_str}. 분석 프로세스에 따라 영양 성분을 평가해주세요."
        
        result = nutri_app.call_claude(system_prompt, user_message)
        result["detected_foods"] = detected_foods
        result["rekognition_confidence"] = len(detected_foods) > 0
        
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/recommend-supplements")
async def recommend_supplements(request: SupplementRecommendationRequest):
    """최종 영양제 추천 (RAG 기반)"""
    try:
        # RAG 시스템에서 컨텍스트 생성
        user_info = {
            'age': request.user_info.age,
            'gender': request.user_info.gender,
            'height': request.user_info.height,
            'weight': request.user_info.weight
        }
        
        # 건강 관심사 추출 (실제로는 사용자 데이터에서 가져와야 함)
        health_concerns = ['혈압', '콜레스테롤', '골다공증']  # 예시
        
        # RAG 컨텍스트 생성
        rag_context = rag_system.get_context_for_recommendation(user_info, health_concerns)
        
        # 안전성 정보 (추천할 영양제 목록 기반)
        potential_supplements = ['비타민D', '칼슘', '오메가3', '마그네슘']
        safety_info = rag_system.get_safety_information(potential_supplements)
        
        # 상호작용 정보
        interaction_info = rag_system.get_supplement_interactions(potential_supplements)
        
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
        
        system_prompt = nutri_app.load_prompt("final_supplement_expert.txt", user_vars)
        result = nutri_app.call_claude(system_prompt, "모든 데이터를 통합하여 최적의 영양제 스케줄을 설계해주세요.")
        
        # RAG 메타데이터 추가
        result["rag_info"] = {
            "context_sources": len(rag_context.split('\n')),
            "safety_checks": len(interaction_info),
            "database_used": True
        }
        
        return {"success": True, "data": result}
    except Exception as e:
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
            "metadata_loaded": rag_system.metadata is not None,
            "database_accessible": os.path.exists(rag_system.db_path)
        }
        
        return {
            "status": "healthy",
            "aws_connected": True,
            "account_id": identity['Account'],
            "rag_system": rag_status
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "aws_connected": False,
            "error": str(e)
        }

class YouTubeFactCheckRequest(BaseModel):
    user_info: UserInfo
    youtube_url: str

@app.post("/api/fact-check-youtube")
async def fact_check_youtube(request: YouTubeFactCheckRequest):
    """유튜브 영상 팩트체킹"""
    try:
        # 유튜브 URL에서 비디오 ID 추출
        video_id = extract_video_id(request.youtube_url)
        if not video_id:
            raise HTTPException(status_code=400, detail="유효하지 않은 유튜브 URL입니다.")
        
        # 유튜브 영상 정보 시뮬레이션 (실제로는 YouTube API 사용)
        video_info = {
            "title": "건강 관련 영상",
            "description": "건강에 대한 정보를 제공하는 영상입니다.",
            "transcript": "이 영상에서는 다양한 건강 정보를 다룹니다."
        }
        
        # RAG 시스템에서 관련 의학 정보 검색
        health_claims = extract_health_claims(video_info["title"] + " " + video_info["description"])
        
        fact_check_context = ""
        for claim in health_claims:
            related_docs = rag_system.search_similar_documents(claim, top_k=3)
            for doc in related_docs:
                fact_check_context += f"[의학 정보] {doc.get('name', '')}: {doc.get('content', doc.get('full_text', ''))[:200]}...\n"
        
        # Claude로 팩트체킹 분석
        fact_check_prompt = f"""
당신은 의학 정보 팩트체커입니다. 유튜브 영상의 건강 정보를 검증해주세요.

영상 정보:
- 제목: {video_info['title']}
- 설명: {video_info['description']}

의학 데이터베이스 정보:
{fact_check_context}

다음 JSON 형식으로 답변해주세요:
{{
  "overall_credibility": "높음/보통/낮음",
  "fact_check_result": "팩트체킹 결과 요약",
  "verified_claims": ["검증된 사실들"],
  "questionable_claims": ["의심스러운 주장들"],
  "recommendations": "시청자를 위한 권장사항",
  "medical_disclaimer": "의학적 면책 조항"
        
        response = nutri_app.bedrock.converse(
            modelId=nutri_app.model_id,
            messages=[{"role": "user", "content": [{"text": fact_check_prompt}]}]
        )
        
        raw_text = response['output']['message']['content'][0]['text']
        
        try:
            if "```json" in raw_text:
                json_text = raw_text.split("```json")[1].split("```")[0].strip()
            else:
                start_idx = raw_text.find("{")
                end_idx = raw_text.rfind("}") + 1
                json_text = raw_text[start_idx:end_idx]
            result = json.loads(json_text)
        except:
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
        
        return {"success": True, "data": result}
        
    except Exception as e:
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

if __name__ == "__main__":
    import uvicorn
    print("🚀 Senior Supplement API Server 시작 중...")
    print("📱 Flutter 앱에서 http://localhost:8000 으로 접속하세요!")
    uvicorn.run(app, host="0.0.0.0", port=8000)