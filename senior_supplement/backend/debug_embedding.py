#!/usr/bin/env python3
import boto3
import json

def test_titan_embedding():
    """Amazon Titan Embeddings 테스트"""
    
    print("🧪 Amazon Titan Embeddings 테스트")
    print("=" * 50)
    
    try:
        session = boto3.Session()
        bedrock = session.client(service_name='bedrock-runtime', region_name='us-east-1')
        
        # 간단한 텍스트로 임베딩 테스트
        test_text = "비타민 D"
        
        print(f"테스트 텍스트: '{test_text}'")
        
        response = bedrock.invoke_model(
            modelId="amazon.titan-embed-text-v1",
            body=json.dumps({
                "inputText": test_text
            })
        )
        
        response_body = json.loads(response['body'].read())
        embedding = response_body['embedding']
        
        print(f"✅ 임베딩 생성 성공!")
        print(f"   - 임베딩 차원: {len(embedding)}")
        print(f"   - 첫 5개 값: {embedding[:5]}")
        
        return True
        
    except Exception as e:
        print(f"❌ 임베딩 생성 실패: {str(e)}")
        
        # 사용 가능한 모델 확인
        try:
            print("\n사용 가능한 임베딩 모델 확인 중...")
            
            # 다른 모델 시도
            alternative_models = [
                "amazon.titan-embed-text-v2:0",
                "cohere.embed-english-v3",
                "cohere.embed-multilingual-v3"
            ]
            
            for model_id in alternative_models:
                try:
                    print(f"모델 테스트: {model_id}")
                    response = bedrock.invoke_model(
                        modelId=model_id,
                        body=json.dumps({
                            "inputText": test_text,
                            "input_type": "search_document" if "cohere" in model_id else None
                        })
                    )
                    print(f"✅ {model_id} 사용 가능!")
                    return model_id
                except Exception as model_error:
                    print(f"❌ {model_id} 사용 불가: {str(model_error)}")
            
        except Exception as list_error:
            print(f"❌ 모델 확인 실패: {str(list_error)}")
        
        return False

if __name__ == "__main__":
    test_titan_embedding()