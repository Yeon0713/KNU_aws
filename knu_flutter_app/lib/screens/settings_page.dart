import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_sync_service.dart';
import '../services/user_service.dart';
import '../services/data_storage_service.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _syncEnabled = true;
  bool _privacyConsent = false;
  bool _isLoading = false;
  Map<String, dynamic> _syncStatus = {};
  Map<String, dynamic> _userProfile = {};
  Map<String, int> _dataStats = {};
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // 동기화 설정 로드
      _syncEnabled = await DatabaseSyncService.isSyncEnabled();
      
      // 개인정보 동의 상태 로드
      _privacyConsent = await UserService.getPrivacyConsent();
      
      // 동기화 상태 로드
      _syncStatus = await DatabaseSyncService.getSyncStatus();
      
      // 사용자 프로필 로드
      _userProfile = await UserService.getCurrentUserProfile();
      
      // 데이터 통계 로드
      _dataStats = await DataStorageService.getDataStatistics();
      
      // 마지막 동기화 시간 로드
      _lastSyncTime = await DatabaseSyncService.getLastSyncTime();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ 설정 로드 오류: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSync(bool value) async {
    setState(() => _isLoading = true);
    
    try {
      await DatabaseSyncService.setSyncEnabled(value);
      
      if (value) {
        // 동기화 활성화 시 즉시 동기화 수행
        final syncResult = await DatabaseSyncService.fullSync();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(syncResult['success'] ? '동기화가 활성화되었습니다.' : '동기화 활성화 중 오류가 발생했습니다.'),
              backgroundColor: syncResult['success'] ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('동기화가 비활성화되었습니다. 데이터는 로컬에만 저장됩니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
      await _loadSettings();
    } catch (e) {
      print('❌ 동기화 설정 변경 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 변경 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePrivacyConsent(bool value) async {
    try {
      await UserService.setPrivacyConsent(value);
      
      if (!value) {
        // 개인정보 동의 철회 시 동기화도 비활성화
        await DatabaseSyncService.setSyncEnabled(false);
      }
      
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '개인정보 처리에 동의하셨습니다.' : '개인정보 처리 동의를 철회하셨습니다.'),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ 개인정보 동의 설정 변경 오류: $e');
    }
  }

  Future<void> _manualSync() async {
    setState(() => _isLoading = true);
    
    try {
      final syncResult = await DatabaseSyncService.fullSync();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(syncResult['message']),
            backgroundColor: syncResult['success'] ? Colors.green : Colors.red,
          ),
        );
      }
      
      await _loadSettings();
    } catch (e) {
      print('❌ 수동 동기화 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동기화 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    
    try {
      final backup = await UserService.createUserBackup();
      
      // 실제 앱에서는 파일로 저장하거나 공유 기능을 사용
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('데이터 백업'),
            content: const Text('데이터 백업이 생성되었습니다.\n실제 앱에서는 파일로 저장하거나 클라우드에 업로드할 수 있습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ 데이터 내보내기 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 내보내기 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 데이터 삭제'),
        content: const Text('모든 로컬 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        await DataStorageService.clearAllData();
        await UserService.deleteAccount();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('모든 데이터가 삭제되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        await _loadSettings();
      } catch (e) {
        print('❌ 데이터 삭제 오류: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('데이터 삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testApiConnection() async {
    setState(() => _isLoading = true);
    
    try {
      // 서버 상태 확인
      print('🔍 API 연결 테스트 시작...');
      final isHealthy = await ApiService.checkServerHealth();
      
      if (!isHealthy) {
        throw Exception('서버에 연결할 수 없습니다');
      }
      
      // 간단한 건강검진 분석 테스트
      final testResult = await ApiService.analyzeCheckup(
        name: _userProfile['name'] ?? '테스트사용자',
        age: _userProfile['age'] ?? 65,
        gender: _userProfile['gender'] ?? '남성',
        height: _userProfile['height'] ?? 170,
        weight: _userProfile['weight'] ?? 70,
        checkupText: '혈압 120/80, 혈당 100, 콜레스테롤 200',
      );
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('API 연결 성공'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ 서버 연결: 정상'),
                const Text('✅ AI 분석: 정상'),
                const SizedBox(height: 8),
                Text('테스트 결과: ${testResult['status'] ?? 'Unknown'}'),
                const SizedBox(height: 4),
                Text('분석 내용: ${testResult['content'] ?? 'No content'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ API 연결 테스트 실패: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('API 연결 실패'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('❌ 서버 연결에 문제가 있습니다.'),
                const SizedBox(height: 8),
                Text('오류: $e'),
                const SizedBox(height: 8),
                const Text('해결 방법:'),
                const Text('• WiFi 연결 확인'),
                const Text('• 서버 상태 확인'),
                const Text('• 앱 재시작'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 사용자 정보 섹션
                _buildSectionCard(
                  title: '사용자 정보',
                  icon: Icons.person,
                  children: [
                    ListTile(
                      title: Text('이름: ${_userProfile['name'] ?? '사용자'}'),
                      subtitle: Text('${_userProfile['age'] ?? 0}세, ${_userProfile['gender'] ?? '성별 미설정'}'),
                      trailing: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                      onTap: () {
                        // 프로필 편집 페이지로 이동
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 데이터 동기화 섹션
                _buildSectionCard(
                  title: '데이터 동기화',
                  icon: Icons.sync,
                  children: [
                    SwitchListTile(
                      title: const Text('클라우드 동기화'),
                      subtitle: Text(_syncEnabled 
                          ? '데이터가 서버와 동기화됩니다' 
                          : '데이터가 로컬에만 저장됩니다'),
                      value: _syncEnabled,
                      activeColor: const Color(0xFF2196F3),
                      onChanged: _toggleSync,
                    ),
                    if (_syncEnabled) ...[
                      const Divider(),
                      ListTile(
                        title: const Text('동기화 상태'),
                        subtitle: Text(_getSyncStatusText()),
                        trailing: Icon(
                          _getSyncStatusIcon(),
                          color: _getSyncStatusColor(),
                        ),
                      ),
                      if (_lastSyncTime != null)
                        ListTile(
                          title: const Text('마지막 동기화'),
                          subtitle: Text(_formatDateTime(_lastSyncTime!)),
                        ),
                      const Divider(),
                      ListTile(
                        title: const Text('지금 동기화'),
                        subtitle: const Text('수동으로 데이터를 동기화합니다'),
                        trailing: const Icon(Icons.sync, color: Color(0xFF2196F3)),
                        onTap: _manualSync,
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('API 연결 테스트'),
                        subtitle: const Text('서버와 AI 기능 연결 상태를 확인합니다'),
                        trailing: const Icon(Icons.network_check, color: Color(0xFF2196F3)),
                        onTap: _testApiConnection,
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 개인정보 보호 섹션
                _buildSectionCard(
                  title: '개인정보 보호',
                  icon: Icons.privacy_tip,
                  children: [
                    SwitchListTile(
                      title: const Text('개인정보 처리 동의'),
                      subtitle: const Text('데이터 수집 및 처리에 대한 동의'),
                      value: _privacyConsent,
                      activeColor: const Color(0xFF2196F3),
                      onChanged: _togglePrivacyConsent,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 데이터 관리 섹션
                _buildSectionCard(
                  title: '데이터 관리',
                  icon: Icons.storage,
                  children: [
                    ListTile(
                      title: const Text('저장된 데이터'),
                      subtitle: Text(_getDataStatsText()),
                      trailing: const Icon(Icons.info, color: Color(0xFF2196F3)),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('데이터 내보내기'),
                      subtitle: const Text('백업 파일로 데이터를 내보냅니다'),
                      trailing: const Icon(Icons.download, color: Color(0xFF2196F3)),
                      onTap: _exportData,
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('모든 데이터 삭제'),
                      subtitle: const Text('로컬에 저장된 모든 데이터를 삭제합니다'),
                      trailing: const Icon(Icons.delete_forever, color: Colors.red),
                      onTap: _clearAllData,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 앱 정보 섹션
                _buildSectionCard(
                  title: '앱 정보',
                  icon: Icons.info,
                  children: [
                    const ListTile(
                      title: Text('버전'),
                      subtitle: Text('1.0.0'),
                    ),
                    const ListTile(
                      title: Text('개발자'),
                      subtitle: Text('AI 영양제 추천 팀'),
                    ),
                    ListTile(
                      title: const Text('개인정보 처리방침'),
                      trailing: const Icon(Icons.open_in_new, color: Color(0xFF2196F3)),
                      onTap: () {
                        // 개인정보 처리방침 페이지로 이동
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  String _getSyncStatusText() {
    final status = _syncStatus['status'] ?? 'unknown';
    switch (status) {
      case 'online':
        return '온라인 - 동기화 활성화';
      case 'offline_by_choice':
        return '오프라인 - 사용자 설정';
      case 'offline':
        return '오프라인 - 네트워크 연결 없음';
      default:
        return '상태 확인 중...';
    }
  }

  IconData _getSyncStatusIcon() {
    final status = _syncStatus['status'] ?? 'unknown';
    switch (status) {
      case 'online':
        return Icons.cloud_done;
      case 'offline_by_choice':
        return Icons.cloud_off;
      case 'offline':
        return Icons.cloud_off;
      default:
        return Icons.help;
    }
  }

  Color _getSyncStatusColor() {
    final status = _syncStatus['status'] ?? 'unknown';
    switch (status) {
      case 'online':
        return Colors.green;
      case 'offline_by_choice':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDataStatsText() {
    final meals = _dataStats['meals'] ?? 0;
    final supplements = _dataStats['supplements'] ?? 0;
    final checkups = _dataStats['checkups'] ?? 0;
    final factChecks = _dataStats['factChecks'] ?? 0;
    
    return '식단 $meals개, 영양제 분석 $supplements개, 건강검진 $checkups개, 팩트체크 $factChecks개';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}