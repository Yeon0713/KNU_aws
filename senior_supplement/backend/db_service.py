from sqlalchemy.orm import Session
from database import User, MealRecord, SupplementAnalysis, HealthCheckup, FactCheck, MedicationRecord
from datetime import datetime
import uuid
from typing import List, Optional

class DatabaseService:
    
    # 사용자 관련 메서드
    @staticmethod
    def create_user(db: Session, user_data: dict) -> User:
        """새 사용자 생성"""
        user_id = str(uuid.uuid4())
        db_user = User(
            user_id=user_id,
            name=user_data.get('name', ''),
            age=int(user_data.get('age', 0)),
            gender=user_data.get('gender', ''),
            height=float(user_data.get('height', 0)),
            weight=float(user_data.get('weight', 0)),
            health_concerns=user_data.get('health_concerns', [])
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
        """사용자 ID로 사용자 조회"""
        return db.query(User).filter(User.user_id == user_id).first()
    
    @staticmethod
    def update_user(db: Session, user_id: str, user_data: dict) -> Optional[User]:
        """사용자 정보 업데이트"""
        db_user = db.query(User).filter(User.user_id == user_id).first()
        if db_user:
            for key, value in user_data.items():
                if hasattr(db_user, key):
                    setattr(db_user, key, value)
            db_user.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(db_user)
        return db_user
    
    # 식사 기록 관련 메서드
    @staticmethod
    def add_meal_record(db: Session, user_id: str, meal_data: dict) -> MealRecord:
        """식사 기록 추가"""
        db_meal = MealRecord(
            user_id=user_id,
            date=meal_data.get('date'),
            meal_type=meal_data.get('meal_type'),
            foods=meal_data.get('foods', []),
            nutrients=meal_data.get('nutrients', {}),
            calories=float(meal_data.get('calories', 0)),
            image_path=meal_data.get('image_path'),
            ai_analysis=meal_data.get('ai_analysis', {})
        )
        db.add(db_meal)
        db.commit()
        db.refresh(db_meal)
        return db_meal
    
    @staticmethod
    def get_meals_by_date(db: Session, user_id: str, date: str) -> List[MealRecord]:
        """특정 날짜의 식사 기록 조회"""
        return db.query(MealRecord).filter(
            MealRecord.user_id == user_id,
            MealRecord.date == date
        ).all()
    
    @staticmethod
    def get_meals_by_date_range(db: Session, user_id: str, start_date: str, end_date: str) -> List[MealRecord]:
        """날짜 범위의 식사 기록 조회"""
        return db.query(MealRecord).filter(
            MealRecord.user_id == user_id,
            MealRecord.date >= start_date,
            MealRecord.date <= end_date
        ).all()
    
    # 영양제 분석 관련 메서드
    @staticmethod
    def save_supplement_analysis(db: Session, user_id: str, analysis_data: dict) -> SupplementAnalysis:
        """영양제 분석 결과 저장"""
        db_analysis = SupplementAnalysis(
            user_id=user_id,
            analysis_result=analysis_data.get('analysis_result', {}),
            recommended_supplements=analysis_data.get('recommended_supplements', []),
            deficient_nutrients=analysis_data.get('deficient_nutrients', [])
        )
        db.add(db_analysis)
        db.commit()
        db.refresh(db_analysis)
        return db_analysis
    
    @staticmethod
    def get_latest_supplement_analysis(db: Session, user_id: str) -> Optional[SupplementAnalysis]:
        """최신 영양제 분석 결과 조회"""
        return db.query(SupplementAnalysis).filter(
            SupplementAnalysis.user_id == user_id
        ).order_by(SupplementAnalysis.created_at.desc()).first()
    
    @staticmethod
    def get_supplement_analysis_history(db: Session, user_id: str, limit: int = 10) -> List[SupplementAnalysis]:
        """영양제 분석 기록 조회"""
        return db.query(SupplementAnalysis).filter(
            SupplementAnalysis.user_id == user_id
        ).order_by(SupplementAnalysis.created_at.desc()).limit(limit).all()
    
    # 건강검진 관련 메서드
    @staticmethod
    def save_health_checkup(db: Session, user_id: str, checkup_data: dict) -> HealthCheckup:
        """건강검진 결과 저장"""
        db_checkup = HealthCheckup(
            user_id=user_id,
            checkup_date=checkup_data.get('checkup_date'),
            checkup_data=checkup_data.get('checkup_data', {}),
            ai_analysis=checkup_data.get('ai_analysis', {}),
            status=checkup_data.get('status', ''),
            image_path=checkup_data.get('image_path')
        )
        db.add(db_checkup)
        db.commit()
        db.refresh(db_checkup)
        return db_checkup
    
    @staticmethod
    def get_latest_health_checkup(db: Session, user_id: str) -> Optional[HealthCheckup]:
        """최신 건강검진 결과 조회"""
        return db.query(HealthCheckup).filter(
            HealthCheckup.user_id == user_id
        ).order_by(HealthCheckup.created_at.desc()).first()
    
    @staticmethod
    def get_health_checkup_history(db: Session, user_id: str, limit: int = 10) -> List[HealthCheckup]:
        """건강검진 기록 조회"""
        return db.query(HealthCheckup).filter(
            HealthCheckup.user_id == user_id
        ).order_by(HealthCheckup.created_at.desc()).limit(limit).all()
    
    # 팩트체크 관련 메서드
    @staticmethod
    def save_fact_check(db: Session, user_id: str, fact_check_data: dict) -> FactCheck:
        """팩트체크 결과 저장"""
        db_fact_check = FactCheck(
            user_id=user_id,
            query=fact_check_data.get('query', ''),
            source_type=fact_check_data.get('source_type', 'text'),
            credibility_score=float(fact_check_data.get('credibility_score', 0)),
            fact_check_result=fact_check_data.get('fact_check_result', {})
        )
        db.add(db_fact_check)
        db.commit()
        db.refresh(db_fact_check)
        return db_fact_check
    
    @staticmethod
    def get_fact_check_history(db: Session, user_id: str, limit: int = 15) -> List[FactCheck]:
        """팩트체크 기록 조회"""
        return db.query(FactCheck).filter(
            FactCheck.user_id == user_id
        ).order_by(FactCheck.created_at.desc()).limit(limit).all()
    
    # 복용 기록 관련 메서드
    @staticmethod
    def add_medication_record(db: Session, user_id: str, medication_data: dict) -> MedicationRecord:
        """복용 기록 추가"""
        db_medication = MedicationRecord(
            user_id=user_id,
            date=medication_data.get('date'),
            medication_name=medication_data.get('medication_name'),
            dosage=medication_data.get('dosage'),
            taken=medication_data.get('taken', False),
            taken_time=medication_data.get('taken_time')
        )
        db.add(db_medication)
        db.commit()
        db.refresh(db_medication)
        return db_medication
    
    @staticmethod
    def update_medication_taken(db: Session, user_id: str, date: str, medication_name: str, taken: bool) -> Optional[MedicationRecord]:
        """복용 상태 업데이트"""
        db_medication = db.query(MedicationRecord).filter(
            MedicationRecord.user_id == user_id,
            MedicationRecord.date == date,
            MedicationRecord.medication_name == medication_name
        ).first()
        
        if db_medication:
            db_medication.taken = taken
            db_medication.taken_time = datetime.utcnow() if taken else None
            db.commit()
            db.refresh(db_medication)
        return db_medication
    
    @staticmethod
    def get_medication_records_by_date(db: Session, user_id: str, date: str) -> List[MedicationRecord]:
        """특정 날짜의 복용 기록 조회"""
        return db.query(MedicationRecord).filter(
            MedicationRecord.user_id == user_id,
            MedicationRecord.date == date
        ).all()
    
    # 통계 관련 메서드
    @staticmethod
    def get_user_statistics(db: Session, user_id: str) -> dict:
        """사용자 데이터 통계"""
        meal_count = db.query(MealRecord).filter(MealRecord.user_id == user_id).count()
        supplement_count = db.query(SupplementAnalysis).filter(SupplementAnalysis.user_id == user_id).count()
        checkup_count = db.query(HealthCheckup).filter(HealthCheckup.user_id == user_id).count()
        fact_check_count = db.query(FactCheck).filter(FactCheck.user_id == user_id).count()
        medication_count = db.query(MedicationRecord).filter(MedicationRecord.user_id == user_id).count()
        
        return {
            'meals': meal_count,
            'supplement_analyses': supplement_count,
            'health_checkups': checkup_count,
            'fact_checks': fact_check_count,
            'medication_records': medication_count
        }
    
    # 데이터 동기화 관련 메서드
    @staticmethod
    def sync_user_data(db: Session, user_id: str, sync_data: dict) -> dict:
        """클라이언트와 서버 데이터 동기화"""
        result = {
            'synced_meals': 0,
            'synced_analyses': 0,
            'synced_checkups': 0,
            'synced_fact_checks': 0,
            'synced_medications': 0
        }
        
        # 식사 기록 동기화
        if 'meals' in sync_data:
            for meal_data in sync_data['meals']:
                DatabaseService.add_meal_record(db, user_id, meal_data)
                result['synced_meals'] += 1
        
        # 영양제 분석 동기화
        if 'supplement_analyses' in sync_data:
            for analysis_data in sync_data['supplement_analyses']:
                DatabaseService.save_supplement_analysis(db, user_id, analysis_data)
                result['synced_analyses'] += 1
        
        # 건강검진 동기화
        if 'health_checkups' in sync_data:
            for checkup_data in sync_data['health_checkups']:
                DatabaseService.save_health_checkup(db, user_id, checkup_data)
                result['synced_checkups'] += 1
        
        # 팩트체크 동기화
        if 'fact_checks' in sync_data:
            for fact_check_data in sync_data['fact_checks']:
                DatabaseService.save_fact_check(db, user_id, fact_check_data)
                result['synced_fact_checks'] += 1
        
        # 복용 기록 동기화
        if 'medication_records' in sync_data:
            for medication_data in sync_data['medication_records']:
                DatabaseService.add_medication_record(db, user_id, medication_data)
                result['synced_medications'] += 1
        
        return result