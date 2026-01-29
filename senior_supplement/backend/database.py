from sqlalchemy import create_engine, Column, Integer, String, DateTime, Text, JSON, Float, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os
from dotenv import load_dotenv

load_dotenv()

# 데이터베이스 URL 설정 (환경변수에서 가져오기)
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./health_app.db")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 사용자 정보 테이블
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, unique=True, index=True)  # 앱에서 생성하는 고유 ID
    name = Column(String)
    age = Column(Integer)
    gender = Column(String)
    height = Column(Float)  # cm
    weight = Column(Float)  # kg
    health_concerns = Column(JSON)  # 건강 관심사 리스트
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# 식사 기록 테이블
class MealRecord(Base):
    __tablename__ = "meal_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    date = Column(String)  # YYYY-MM-DD 형식
    meal_type = Column(String)  # 아침, 점심, 저녁
    foods = Column(JSON)  # 음식 리스트
    nutrients = Column(JSON)  # 영양소 정보
    calories = Column(Float)
    image_path = Column(String, nullable=True)
    ai_analysis = Column(JSON, nullable=True)  # AI 분석 결과
    created_at = Column(DateTime, default=datetime.utcnow)

# 영양제 분석 기록 테이블
class SupplementAnalysis(Base):
    __tablename__ = "supplement_analyses"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    analysis_result = Column(JSON)  # AI 분석 결과
    recommended_supplements = Column(JSON)  # 추천 영양제 리스트
    deficient_nutrients = Column(JSON)  # 부족한 영양소
    created_at = Column(DateTime, default=datetime.utcnow)

# 건강검진 기록 테이블
class HealthCheckup(Base):
    __tablename__ = "health_checkups"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    checkup_date = Column(String)  # 검진 날짜
    checkup_data = Column(JSON)  # 검진 수치들
    ai_analysis = Column(JSON)  # AI 분석 결과
    status = Column(String)  # 건강 상태 (정상, 주의, 위험)
    image_path = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

# 팩트체크 기록 테이블
class FactCheck(Base):
    __tablename__ = "fact_checks"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    query = Column(Text)  # 사용자 질문
    source_type = Column(String)  # text, youtube_url 등
    credibility_score = Column(Float)  # 신뢰도 점수
    fact_check_result = Column(JSON)  # 팩트체크 결과
    created_at = Column(DateTime, default=datetime.utcnow)

# 복용 기록 테이블
class MedicationRecord(Base):
    __tablename__ = "medication_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    date = Column(String)  # YYYY-MM-DD 형식
    medication_name = Column(String)
    dosage = Column(String)
    taken = Column(Boolean, default=False)  # 복용 여부
    taken_time = Column(DateTime, nullable=True)  # 복용 시간
    created_at = Column(DateTime, default=datetime.utcnow)

# 데이터베이스 테이블 생성
def create_tables():
    Base.metadata.create_all(bind=engine)

# 데이터베이스 세션 의존성
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()