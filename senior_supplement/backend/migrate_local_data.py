#!/usr/bin/env python3
"""
로컬 SharedPreferences 데이터를 DB로 마이그레이션하는 스크립트
"""
import json
import requests
import uuid
from datetime import datetime

# API 서버 URL
BASE_URL = "http://localhost:8000"

def create_test_user():
    """테스트 사용자 생성"""
    user_data = {
        "name": "테스트 사용자",
        "age": 35,
        "gender": "남성",
        "height": 175.0,
        "weight": 70.0,
        "health_concerns": ["혈압", "혈당", "콜레스테롤"]
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/users", json=user_data)
        if response.status_code == 200:
            result = response.json()
            print(f"✅ 사용자 생성 성공: {result['user_id']}")
            return result['user_id']
        else:
            print(f"❌ 사용자 생성 실패: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"❌ 사용자 생성 오류: {e}")
        return None

def migrate_sample_meal_data(user_id):
    """샘플 식단 데이터 마이그레이션"""
    print("\n🍽️ 식단 데이터 마이그레이션 시작...")
    
    # MealDataProvider에서 사용하는 샘플 데이터와 동일한 구조
    sample_meals = {
        '2026-01-20': [
            {
                'type': '아침',
                'time': '08:30',
                'foods': ['현미밥', '된장찌개', '김치', '계란후라이'],
                'image': 'breakfast_1.jpg',
                'calories': 450,
            },
            {
                'type': '점심',
                'time': '12:30',
                'foods': ['불고기덮밥', '미역국', '나물반찬'],
                'image': 'lunch_1.jpg',
                'calories': 680,
            },
            {
                'type': '저녁',
                'time': '19:00',
                'foods': ['연어구이', '샐러드', '현미밥'],
                'image': 'dinner_1.jpg',
                'calories': 520,
            },
        ],
        '2026-01-21': [
            {
                'type': '아침',
                'time': '08:00',
                'foods': ['오트밀', '바나나', '견과류'],
                'image': 'breakfast_2.jpg',
                'calories': 380,
            },
            {
                'type': '점심',
                'time': '13:00',
                'foods': ['치킨샐러드', '통밀빵', '요거트'],
                'image': 'lunch_2.jpg',
                'calories': 550,
            },
        ],
        '2026-01-22': [
            {
                'type': '아침',
                'time': '08:15',
                'foods': ['토스트', '아보카도', '스크램블에그'],
                'image': 'breakfast_3.jpg',
                'calories': 420,
            },
            {
                'type': '점심',
                'time': '12:45',
                'foods': ['비빔밥', '된장국', '김치'],
                'image': 'lunch_3.jpg',
                'calories': 600,
            },
            {
                'type': '저녁',
                'time': '18:30',
                'foods': ['닭가슴살', '브로콜리', '고구마'],
                'image': 'dinner_3.jpg',
                'calories': 480,
            },
        ],
        '2026-01-28': [
            {
                'type': '아침',
                'time': '08:00',
                'foods': ['현미밥', '된장찌개', '김치', '계란'],
                'image': 'breakfast_today.jpg',
                'calories': 450,
            },
            {
                'type': '점심',
                'time': '12:30',
                'foods': ['연어구이', '샐러드', '현미밥', '우유'],
                'image': 'lunch_today.jpg',
                'calories': 620,
            },
            {
                'type': '저녁',
                'time': '19:00',
                'foods': ['닭가슴살', '브로콜리', '견과류', '요거트'],
                'image': 'dinner_today.jpg',
                'calories': 540,
            },
        ],
    }
    
    success_count = 0
    total_count = 0
    
    for date, meals in sample_meals.items():
        for meal in meals:
            total_count += 1
            
            # 영양소 정보 생성 (샘플)
            nutrients = {
                "protein": round(meal['calories'] * 0.15 / 4, 1),  # 단백질 15%
                "carbs": round(meal['calories'] * 0.55 / 4, 1),    # 탄수화물 55%
                "fat": round(meal['calories'] * 0.30 / 9, 1),      # 지방 30%
                "fiber": round(meal['calories'] * 0.02, 1),        # 식이섬유
                "sodium": round(meal['calories'] * 2, 1),          # 나트륨
            }
            
            meal_data = {
                "date": date,
                "meal_type": meal['type'],
                "foods": meal['foods'],
                "nutrients": nutrients,
                "calories": float(meal['calories']),
                "image_path": meal['image'],
                "ai_analysis": {
                    "detected_foods": meal['foods'],
                    "calories": meal['calories'],
                    "meal_time": meal['time'],
                    "analysis_confidence": 0.95,
                    "recommended_nutrient": "비타민C",
                    "action_plan": "다음 식사에 과일을 추가해보세요"
                }
            }
            
            try:
                response = requests.post(
                    f"{BASE_URL}/api/users/{user_id}/meals",
                    json=meal_data
                )
                
                if response.status_code == 200:
                    success_count += 1
                    print(f"  ✅ {date} {meal['type']} 저장 완료")
                else:
                    print(f"  ❌ {date} {meal['type']} 저장 실패: {response.status_code}")
                    
            except Exception as e:
                print(f"  ❌ {date} {meal['type']} 저장 오류: {e}")
    
    print(f"\n📊 식단 데이터 마이그레이션 완료: {success_count}/{total_count}")
    return success_count

def migrate_sample_supplement_data(user_id):
    """샘플 영양제 분석 데이터 마이그레이션"""
    print("\n💊 영양제 분석 데이터 마이그레이션 시작...")
    
    sample_analyses = [
        {
            "analysis_result": {
                "content": "35세 남성의 건강 상태를 종합적으로 분석한 결과입니다.",
                "status": "Yellow",
                "overall_health": "보통",
                "key_findings": ["비타민D 부족", "오메가3 필요", "마그네슘 부족"]
            },
            "recommended_supplements": [
                {
                    "name": "비타민D",
                    "reason": "면역력 강화 및 뼈 건강을 위해 필요합니다",
                    "dosage": "1000IU",
                    "schedule": {"time": "아침", "timing": "식후"}
                },
                {
                    "name": "오메가3",
                    "reason": "심혈관 건강과 뇌 기능 개선을 위해 필요합니다",
                    "dosage": "1000mg",
                    "schedule": {"time": "저녁", "timing": "식후"}
                },
                {
                    "name": "마그네슘",
                    "reason": "근육 기능과 신경 전달을 위해 필요합니다",
                    "dosage": "400mg",
                    "schedule": {"time": "저녁", "timing": "취침 전"}
                }
            ],
            "deficient_nutrients": ["비타민D", "오메가3", "마그네슘", "비타민B12"]
        },
        {
            "analysis_result": {
                "content": "최근 식단 분석을 바탕으로 한 영양제 추천입니다.",
                "status": "Green",
                "overall_health": "양호",
                "key_findings": ["칼슘 보충 필요", "비타민C 충분"]
            },
            "recommended_supplements": [
                {
                    "name": "칼슘",
                    "reason": "뼈 건강 유지를 위해 필요합니다",
                    "dosage": "600mg",
                    "schedule": {"time": "저녁", "timing": "식후"}
                },
                {
                    "name": "종합비타민",
                    "reason": "전반적인 영양 균형을 위해 필요합니다",
                    "dosage": "1정",
                    "schedule": {"time": "아침", "timing": "식후"}
                }
            ],
            "deficient_nutrients": ["칼슘", "아연"]
        }
    ]
    
    success_count = 0
    
    for i, analysis in enumerate(sample_analyses):
        try:
            response = requests.post(
                f"{BASE_URL}/api/users/{user_id}/supplement-analysis",
                json=analysis
            )
            
            if response.status_code == 200:
                success_count += 1
                print(f"  ✅ 영양제 분석 {i+1} 저장 완료")
            else:
                print(f"  ❌ 영양제 분석 {i+1} 저장 실패: {response.status_code}")
                
        except Exception as e:
            print(f"  ❌ 영양제 분석 {i+1} 저장 오류: {e}")
    
    print(f"\n📊 영양제 분석 마이그레이션 완료: {success_count}/{len(sample_analyses)}")
    return success_count

def migrate_sample_health_checkup_data(user_id):
    """샘플 건강검진 데이터 마이그레이션"""
    print("\n🏥 건강검진 데이터 마이그레이션 시작...")
    
    sample_checkups = [
        {
            "checkup_date": "2026-01-15",
            "checkup_data": {
                "혈압": "120/80",
                "혈당": "95",
                "콜레스테롤": "200",
                "체중": "70",
                "BMI": "22.9"
            },
            "ai_analysis": {
                "content": "전반적으로 정상 범위의 건강 수치를 보이고 있습니다.",
                "status": "정상",
                "recommendations": [
                    "현재 건강 상태를 유지하세요",
                    "규칙적인 운동을 계속하세요",
                    "균형 잡힌 식단을 유지하세요"
                ],
                "risk_factors": [],
                "next_checkup": "6개월 후"
            },
            "status": "정상",
            "image_path": "checkup_2026_01_15.jpg"
        },
        {
            "checkup_date": "2025-07-20",
            "checkup_data": {
                "혈압": "135/85",
                "혈당": "110",
                "콜레스테롤": "220",
                "체중": "72",
                "BMI": "23.5"
            },
            "ai_analysis": {
                "content": "혈압과 콜레스테롤 수치가 약간 높습니다. 주의가 필요합니다.",
                "status": "주의",
                "recommendations": [
                    "염분 섭취를 줄이세요",
                    "유산소 운동을 늘리세요",
                    "포화지방 섭취를 줄이세요"
                ],
                "risk_factors": ["고혈압 전단계", "경계성 고콜레스테롤"],
                "next_checkup": "3개월 후"
            },
            "status": "주의",
            "image_path": "checkup_2025_07_20.jpg"
        }
    ]
    
    success_count = 0
    
    for i, checkup in enumerate(sample_checkups):
        try:
            response = requests.post(
                f"{BASE_URL}/api/users/{user_id}/health-checkups",
                json=checkup
            )
            
            if response.status_code == 200:
                success_count += 1
                print(f"  ✅ 건강검진 {checkup['checkup_date']} 저장 완료")
            else:
                print(f"  ❌ 건강검진 {checkup['checkup_date']} 저장 실패: {response.status_code}")
                
        except Exception as e:
            print(f"  ❌ 건강검진 {checkup['checkup_date']} 저장 오류: {e}")
    
    print(f"\n📊 건강검진 마이그레이션 완료: {success_count}/{len(sample_checkups)}")
    return success_count

def migrate_sample_fact_check_data(user_id):
    """샘플 팩트체크 데이터 마이그레이션"""
    print("\n🔍 팩트체크 데이터 마이그레이션 시작...")
    
    sample_fact_checks = [
        {
            "query": "마그네슘이 정말 수면에 도움이 될까요?",
            "source_type": "text",
            "credibility_score": 0.8,
            "fact_check_result": {
                "overall_credibility": "높음",
                "fact_check_result": "마그네슘은 실제로 수면의 질 개선에 도움이 될 수 있습니다. 여러 연구에서 마그네슘 보충이 불면증 개선과 수면 시간 증가에 효과가 있다고 보고되었습니다.",
                "verified_claims": [
                    "마그네슘은 신경계 진정 효과가 있습니다",
                    "수면 호르몬인 멜라토닌 생성을 도와줍니다",
                    "근육 이완에 도움이 됩니다"
                ],
                "questionable_claims": [],
                "recommendations": "마그네슘 보충제는 취침 1-2시간 전에 복용하는 것이 좋습니다.",
                "medical_disclaimer": "개인차가 있을 수 있으므로 전문의와 상담 후 복용하세요."
            }
        },
        {
            "query": "비타민D 과다복용이 위험한가요?",
            "source_type": "text",
            "credibility_score": 0.9,
            "fact_check_result": {
                "overall_credibility": "높음",
                "fact_check_result": "비타민D 과다복용은 실제로 위험할 수 있습니다. 고칼슘혈증, 신장 결석, 신장 손상 등의 부작용이 발생할 수 있습니다.",
                "verified_claims": [
                    "하루 4000IU 이상 장기 복용 시 위험합니다",
                    "혈중 칼슘 농도가 높아질 수 있습니다",
                    "신장에 부담을 줄 수 있습니다"
                ],
                "questionable_claims": [],
                "recommendations": "혈액검사를 통해 비타민D 수치를 확인한 후 적정량을 복용하세요.",
                "medical_disclaimer": "복용 전 반드시 의사와 상담하시기 바랍니다."
            }
        },
        {
            "query": "오메가3는 얼마나 먹어야 하나요?",
            "source_type": "youtube_url",
            "credibility_score": 0.7,
            "fact_check_result": {
                "overall_credibility": "보통",
                "fact_check_result": "일반적으로 성인은 하루 1000-2000mg의 오메가3를 섭취하는 것이 권장됩니다. 하지만 개인의 건강 상태에 따라 달라질 수 있습니다.",
                "verified_claims": [
                    "EPA+DHA 합계 1000mg이 일반적 권장량입니다",
                    "심혈관 질환 예방 효과가 있습니다",
                    "뇌 건강에 도움이 됩니다"
                ],
                "questionable_claims": [
                    "무조건 많이 먹을수록 좋다는 주장"
                ],
                "recommendations": "개인의 건강 상태를 고려하여 적정량을 섭취하세요.",
                "medical_disclaimer": "특정 질환이 있는 경우 의사와 상담 후 복용하세요."
            }
        }
    ]
    
    success_count = 0
    
    for i, fact_check in enumerate(sample_fact_checks):
        try:
            response = requests.post(
                f"{BASE_URL}/api/users/{user_id}/fact-checks",
                json=fact_check
            )
            
            if response.status_code == 200:
                success_count += 1
                print(f"  ✅ 팩트체크 {i+1} 저장 완료")
            else:
                print(f"  ❌ 팩트체크 {i+1} 저장 실패: {response.status_code}")
                
        except Exception as e:
            print(f"  ❌ 팩트체크 {i+1} 저장 오류: {e}")
    
    print(f"\n📊 팩트체크 마이그레이션 완료: {success_count}/{len(sample_fact_checks)}")
    return success_count

def migrate_sample_medication_data(user_id):
    """샘플 복용 기록 데이터 마이그레이션"""
    print("\n💊 복용 기록 데이터 마이그레이션 시작...")
    
    # 최근 7일간의 복용 기록 생성
    from datetime import datetime, timedelta
    
    medications = [
        {"name": "비타민D", "dosage": "1000IU"},
        {"name": "오메가3", "dosage": "1000mg"},
        {"name": "마그네슘", "dosage": "400mg"},
        {"name": "종합비타민", "dosage": "1정"}
    ]
    
    success_count = 0
    total_count = 0
    
    # 최근 7일간의 데이터 생성
    for i in range(7):
        date = (datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d')
        
        for med in medications:
            total_count += 1
            
            # 랜덤하게 복용 여부 결정 (90% 확률로 복용)
            import random
            taken = random.random() < 0.9
            
            medication_data = {
                "date": date,
                "medication_name": med["name"],
                "dosage": med["dosage"],
                "taken": taken
            }
            
            try:
                response = requests.post(
                    f"{BASE_URL}/api/users/{user_id}/medications",
                    json=medication_data
                )
                
                if response.status_code == 200:
                    success_count += 1
                    status = "복용" if taken else "미복용"
                    print(f"  ✅ {date} {med['name']} ({status}) 저장 완료")
                else:
                    print(f"  ❌ {date} {med['name']} 저장 실패: {response.status_code}")
                    
            except Exception as e:
                print(f"  ❌ {date} {med['name']} 저장 오류: {e}")
    
    print(f"\n📊 복용 기록 마이그레이션 완료: {success_count}/{total_count}")
    return success_count

def check_migration_results():
    """마이그레이션 결과 확인"""
    print("\n" + "="*60)
    print("📊 마이그레이션 결과 확인")
    print("="*60)
    
    try:
        # 서버 상태 확인
        response = requests.get(f"{BASE_URL}/api/health")
        if response.status_code == 200:
            print("✅ 서버 연결 정상")
        else:
            print("❌ 서버 연결 실패")
            return
            
        # 사용자 목록 확인 (첫 번째 사용자 가져오기)
        import sqlite3
        conn = sqlite3.connect('health_app.db')
        cursor = conn.cursor()
        
        # 각 테이블의 데이터 개수 확인
        tables = ['users', 'meal_records', 'supplement_analyses', 'health_checkups', 'fact_checks', 'medication_records']
        
        for table in tables:
            cursor.execute(f'SELECT COUNT(*) FROM {table}')
            count = cursor.fetchone()[0]
            print(f"📋 {table}: {count}개 데이터")
            
            # 샘플 데이터 1개씩 보기
            if count > 0:
                cursor.execute(f'SELECT * FROM {table} LIMIT 1')
                sample = cursor.fetchone()
                print(f"   샘플: {str(sample)[:100]}...")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ 결과 확인 오류: {e}")

def main():
    """메인 마이그레이션 함수"""
    print("🚀 로컬 데이터 → DB 마이그레이션 시작")
    print("="*60)
    
    # 1. 테스트 사용자 생성
    user_id = create_test_user()
    if not user_id:
        print("❌ 사용자 생성 실패로 마이그레이션 중단")
        return
    
    # 2. 각 데이터 타입별 마이그레이션
    meal_count = migrate_sample_meal_data(user_id)
    supplement_count = migrate_sample_supplement_data(user_id)
    checkup_count = migrate_sample_health_checkup_data(user_id)
    fact_check_count = migrate_sample_fact_check_data(user_id)
    medication_count = migrate_sample_medication_data(user_id)
    
    # 3. 결과 요약
    print("\n" + "="*60)
    print("🎉 마이그레이션 완료!")
    print("="*60)
    print(f"👤 사용자: 1명 생성")
    print(f"🍽️ 식단 기록: {meal_count}개")
    print(f"💊 영양제 분석: {supplement_count}개")
    print(f"🏥 건강검진: {checkup_count}개")
    print(f"🔍 팩트체크: {fact_check_count}개")
    print(f"💊 복용 기록: {medication_count}개")
    
    total_records = meal_count + supplement_count + checkup_count + fact_check_count + medication_count
    print(f"\n📊 총 {total_records}개의 데이터가 DB에 저장되었습니다!")
    
    # 4. 마이그레이션 결과 확인
    check_migration_results()

if __name__ == "__main__":
    main()