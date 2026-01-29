import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_data.dart';

class DoctorViewPage extends StatelessWidget {
  final UserData userData;

  const DoctorViewPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '환자 복용 정보 - 의료진용',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: () {
              _showPrintDialog(context);
            },
            icon: const Icon(Icons.print),
            tooltip: '인쇄',
          ),
          IconButton(
            onPressed: () {
              _showShareDialog(context);
            },
            icon: const Icon(Icons.share),
            tooltip: '공유',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 정보
            _buildHeader(),
            const SizedBox(height: 32),
            
            // 환자 기본 정보
            _buildPatientInfo(),
            const SizedBox(height: 32),
            
            // 현재 복용 의약품
            _buildCurrentMedications(),
            const SizedBox(height: 32),
            
            // 복용 순응도
            _buildComplianceInfo(),
            const SizedBox(height: 32),
            
            // 알레르기 및 주의사항
            _buildAllergiesAndWarnings(),
            const SizedBox(height: 32),
            
            // 건강 관심사
            _buildHealthConcerns(),
            const SizedBox(height: 32),
            
            // 법적 고지
            _buildLegalNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2196F3), const Color(0xFF64B5F6)], // 파란색 그라데이션으로 변경
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_information,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '환자 복용 정보 요약서',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '작성일: ${DateFormat('yyyy년 MM월 dd일 HH:mm').format(DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return _buildSection(
      title: '환자 기본 정보',
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoTable([
            ['성명', userData.name.isNotEmpty ? userData.name : '사용자'],
            ['나이', userData.age.isNotEmpty ? '${userData.age}세' : '미설정'],
            ['성별', userData.gender.isNotEmpty ? userData.gender : '미설정'],
            if (userData.height.isNotEmpty && userData.height != '170')
              ['키', '${userData.height}cm'],
            if (userData.weight.isNotEmpty && userData.weight != '70')
              ['몸무게', '${userData.weight}kg'],
            if (userData.height.isNotEmpty && userData.weight.isNotEmpty)
              ['BMI', _calculateBMI()],
          ]),
        ],
      ),
    );
  }

  Widget _buildCurrentMedications() {
    final medications = [
      {
        'name': '메트포르민 500mg',
        'dosage': '1일 2회, 1회 1정',
        'duration': '2023.03.15 ~ 현재 (10개월)',
        'purpose': '당뇨병 치료',
        'prescribedBy': '내분비내과 김○○ 교수',
      },
      {
        'name': '리피토 20mg',
        'dosage': '1일 1회, 1회 1정 (저녁)',
        'duration': '2023.06.01 ~ 현재 (7개월)',
        'purpose': '고지혈증 치료',
        'prescribedBy': '순환기내과 이○○ 교수',
      },
      {
        'name': '아스피린 100mg',
        'dosage': '1일 1회, 1회 1정 (아침)',
        'duration': '2023.01.10 ~ 현재 (12개월)',
        'purpose': '심혈관 질환 예방',
        'prescribedBy': '순환기내과 이○○ 교수',
      },
    ];

    return _buildSection(
      title: '현재 복용 의약품',
      icon: Icons.medication,
      child: Column(
        children: medications.asMap().entries.map((entry) {
          final index = entry.key;
          final medication = entry.value;
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBDEFB), // 연한 파란색으로 변경
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3), // 파란색으로 변경
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            medication['name'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMedicationDetail('복용법', medication['dosage'] as String),
                    _buildMedicationDetail('복용기간', medication['duration'] as String),
                    _buildMedicationDetail('처방목적', medication['purpose'] as String),
                    _buildMedicationDetail('처방의', medication['prescribedBy'] as String),
                  ],
                ),
              ),
              if (index < medications.length - 1)
                const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComplianceInfo() {
    final medications = [
      {'name': '메트포르민 500mg', 'compliance': 95},
      {'name': '리피토 20mg', 'compliance': 88},
      {'name': '아스피린 100mg', 'compliance': 92},
    ];

    return _buildSection(
      title: '복용 순응도 (최근 30일)',
      icon: Icons.analytics,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8), // 연한 초록색 (건강한 느낌)
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)!), // 연한 초록색 테두리
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: const Color(0xFF4CAF50), size: 24), // 초록색
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '전체 평균 순응도: 92%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...medications.map((medication) {
            final compliance = medication['compliance'] as int;
            final color = compliance >= 90 
                ? const Color(0xFF4CAF50) // 초록색
                : compliance >= 80 
                    ? const Color(0xFFFF9800) // 주황색
                    : const Color(0xFF2196F3); // 파란색으로 변경
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      medication['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: LinearProgressIndicator(
                      value: compliance / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$compliance%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAllergiesAndWarnings() {
    return _buildSection(
      title: '알레르기 및 주의사항',
      icon: Icons.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F9FF), // 연한 파란색으로 변경
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBDEFB)), // 연한 파란색 테두리로 변경
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: const Color(0xFF2196F3), size: 20), // 파란색으로 변경
                    const SizedBox(width: 8),
                    const Text(
                      '약물 알레르기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• 페니실린계 항생제 (발진, 두드러기)\n• 설파제 (호흡곤란)',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0), // 연한 주황색
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0B2)), // 연한 주황색 테두리
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: const Color(0xFFFF9800), size: 20), // 주황색
                    const SizedBox(width: 8),
                    const Text(
                      '복용 시 주의사항',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• 메트포르민: 신장기능 검사 정기 실시 필요\n• 리피토: 근육통 발생 시 즉시 중단\n• 아스피린: 위장보호제와 함께 복용 권장',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthConcerns() {
    if (userData.healthConcerns.isEmpty) return const SizedBox.shrink();
    
    return _buildSection(
      title: '주요 건강 관심사',
      icon: Icons.favorite,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: userData.healthConcerns.map((concern) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F9FF), // 연한 파란색으로 변경
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBBDEFB)), // 연한 파란색 테두리로 변경
            ),
            child: Text(
              concern,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2196F3), // 파란색으로 변경
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegalNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '법적 고지 및 면책사항',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '본 복용 정보는 환자가 직접 입력한 내용을 바탕으로 작성되었으며, 의학적 진단이나 처방을 대체할 수 없습니다. 정확한 의학적 판단 및 처방 변경은 반드시 의료진과 상담하시기 바랍니다.\n\n작성 시점: ${DateFormat('yyyy년 MM월 dd일 HH:mm').format(DateTime.now())}\n정보 제공: 환자 자가 관리 앱',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1), // 연한 파란색으로 변경
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2196F3), // 파란색으로 변경
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildInfoTable(List<List<String>> data) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: data.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Container(
            decoration: BoxDecoration(
              color: index.isEven ? Colors.grey[50] : Colors.white,
              border: index < data.length - 1 
                  ? Border(bottom: BorderSide(color: Colors.grey[300]!))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Text(
                      row[0],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      row[1],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateBMI() {
    try {
      final height = double.parse(userData.height) / 100; // cm to m
      final weight = double.parse(userData.weight);
      final bmi = weight / (height * height);
      return '${bmi.toStringAsFixed(1)} kg/m²';
    } catch (e) {
      return '계산 불가';
    }
  }

  void _showPrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인쇄'),
        content: const Text('이 화면을 인쇄하시겠습니까?\n\n브라우저의 인쇄 기능을 사용하거나\n스크린샷을 저장하여 인쇄할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('브라우저의 인쇄 기능(Ctrl+P)을 사용하세요'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공유'),
        content: const Text('이 정보를 공유하시겠습니까?\n\n스크린샷을 저장하거나\n화면을 캡처하여 공유할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('스크린샷 기능을 사용하여 공유하세요'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}