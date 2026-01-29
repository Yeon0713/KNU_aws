#!/usr/bin/env python3
"""
정교한 한국 음식 분류 테스트
"""
from korean_food_classifier import korean_classifier

def test_classification_system():
    """분류 시스템 테스트"""
    
    print("🧪 정교한 한국 음식 분류 시스템 테스트")
    print("=" * 50)
    
    # 분류 데이터베이스 확인
    print("📊 분류 데이터베이스:")
    for category, foods in korean_classifier.food_database.items():
        print(f"\n🍽️ {category}:")
        for food_name, details in foods.items():
            print(f"  • {food_name}: {details['구분점']}")
    
    print("\n" + "=" * 50)
    print("🎯 주요 구분 기준:")
    print("• 김치 vs 깍두기: 길쭉한 잎 vs 정사각형 조각")
    print("• 된장국 vs 미역국: 갈색 탁한 국물 vs 맑은 국물+검은 미역")
    print("• 오징어콩나물볶음 vs 콩나물볶음: 오징어 유무")
    print("• 배추김치 vs 총각김치: 배추잎 vs 작은 무+잎")
    
    print("\n✅ 정교한 분류 시스템 준비 완료!")
    print("📱 Flutter 앱에서 음식 사진을 업로드해서 테스트하세요.")

if __name__ == "__main__":
    test_classification_system()