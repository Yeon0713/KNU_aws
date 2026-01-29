import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';

class AnalysisSummaryWidget extends StatelessWidget {
  const AnalysisSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, analysisProvider, child) {
        final hasAnyAnalysis = analysisProvider.hasSupplementAnalysis() ||
            analysisProvider.hasMealAnalysis() ||
            analysisProvider.hasCheckupAnalysis();

        if (!hasAnyAnalysis) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE3F2FD), Color(0xFFF3F9FF)], // 파란색 계열
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3), // 파란색
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '최근 AI 분석 결과',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2), // 진한 파란색
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showDetailedResults(context, analysisProvider),
                    child: const Text(
                      '전체보기',
                      style: TextStyle(
                        color: Color(0xFF1976D2), // 진한 파란색
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 영양제 분석 요약
              if (analysisProvider.hasSupplementAnalysis())
                _buildAnalysisCard(
                  icon: Icons.medication,
                  title: '영양제 추천',
                  summary: analysisProvider.getSupplementSummary(),
                  color: Colors.blue, // 파란색으로 변경
                ),
              
              // 식단 분석 요약
              if (analysisProvider.hasMealAnalysis())
                _buildAnalysisCard(
                  icon: Icons.restaurant,
                  title: '식단 분석',
                  summary: analysisProvider.getMealSummary(),
                  color: Colors.green,
                ),
              
              // 건강검진 분석 요약
              if (analysisProvider.hasCheckupAnalysis())
                _buildAnalysisCard(
                  icon: Icons.health_and_safety,
                  title: '건강검진 분석',
                  summary: analysisProvider.getCheckupSummary(),
                  color: Colors.blue,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisCard({
    required IconData icon,
    required String title,
    required String summary,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedResults(BuildContext context, AnalysisProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들바
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 제목
              const Text(
                '전체 분석 결과',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // 상세 결과 리스트
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // 영양제 분석 상세
                    if (provider.hasSupplementAnalysis())
                      _buildDetailedAnalysisCard(
                        title: '영양제 추천 분석',
                        icon: Icons.medication,
                        color: Colors.orange,
                        data: provider.currentSupplementAnalysis!,
                        type: 'supplement',
                      ),
                    
                    // 식단 분석 상세
                    if (provider.hasMealAnalysis())
                      _buildDetailedAnalysisCard(
                        title: '식단 분석 결과',
                        icon: Icons.restaurant,
                        color: Colors.green,
                        data: provider.currentMealAnalysis!,
                        type: 'meal',
                      ),
                    
                    // 건강검진 분석 상세
                    if (provider.hasCheckupAnalysis())
                      _buildDetailedAnalysisCard(
                        title: '건강검진 분석 결과',
                        icon: Icons.health_and_safety,
                        color: Colors.blue,
                        data: provider.currentCheckupAnalysis!,
                        type: 'checkup',
                      ),
                  ],
                ),
              ),
              
              // 하단 버튼
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showClearDataDialog(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text('데이터 삭제'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('확인'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysisCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> data,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 분석 내용
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data['content'] ?? '분석 결과가 없습니다.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          // 타입별 추가 정보
          if (type == 'meal' && data['detected_foods'] != null) ...[
            const SizedBox(height: 12),
            const Text(
              '인식된 음식:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (data['detected_foods'] as List<dynamic>)
                  .map((food) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          food.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          
          if (type == 'supplement' && data['supplement_list'] != null) ...[
            const SizedBox(height: 12),
            const Text(
              '추천 영양제:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(data['supplement_list'] as List<dynamic>).map((supplement) => 
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplement['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      supplement['reason'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '복용: ${supplement['schedule']['time']} ${supplement['schedule']['timing']} (${supplement['dosage']})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, AnalysisProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 삭제'),
        content: const Text('모든 분석 결과를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await provider.clearAllData();
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 바텀시트 닫기
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('모든 분석 데이터가 삭제되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}