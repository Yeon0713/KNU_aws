import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';

class PersistentAnalysisWidget extends StatelessWidget {
  final String title;
  final String type; // 'meal', 'supplement', 'checkup'

  const PersistentAnalysisWidget({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // 홈페이지에서는 분석 결과를 표시하지 않음
    if (type == 'all') {
      return const SizedBox.shrink();
    }

    return Consumer<AnalysisProvider>(
      builder: (context, analysisProvider, child) {
        Map<String, dynamic>? analysisData;
        Color cardColor;
        IconData cardIcon;

        switch (type) {
          case 'meal':
            analysisData = analysisProvider.currentMealAnalysis;
            cardColor = Colors.green;
            cardIcon = Icons.restaurant;
            break;
          case 'supplement':
            analysisData = analysisProvider.currentSupplementAnalysis;
            cardColor = Colors.blue; // 파란색으로 변경
            cardIcon = Icons.medication;
            break;
          case 'checkup':
            analysisData = analysisProvider.currentCheckupAnalysis;
            cardColor = Colors.blue;
            cardIcon = Icons.health_and_safety;
            break;
          default:
            return const SizedBox.shrink();
        }

        if (analysisData == null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(cardIcon, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$title 분석 결과가 없습니다.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardColor.withOpacity(0.1),
                cardColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      cardIcon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$title 분석 결과',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                  ),
                  Text(
                    '저장됨',
                    style: TextStyle(
                      fontSize: 12,
                      color: cardColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 분석 내용 요약
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getAnalysisSummary(analysisData, type),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 특별 정보 (음식 목록, 영양제 목록 등)
              if (type == 'meal' && analysisData['detected_foods'] != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (analysisData['detected_foods'] as List<dynamic>)
                      .take(5) // 최대 5개만 표시
                      .map((food) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              food.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: cardColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              
              if (type == 'supplement' && analysisData['supplement_list'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  '추천 영양제: ${(analysisData['supplement_list'] as List<dynamic>).length}개',
                  style: TextStyle(
                    fontSize: 12,
                    color: cardColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getAnalysisSummary(Map<String, dynamic> data, String type) {
    final content = data['content'] ?? '분석 결과가 없습니다.';
    
    // 내용이 너무 길면 요약
    if (content.length > 100) {
      return '${content.substring(0, 100)}...';
    }
    
    return content;
  }
}