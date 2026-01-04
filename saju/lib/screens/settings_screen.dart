import 'package:flutter/material.dart';
import '../models/personal_info.dart';
import '../services/settings_storage_service.dart';

/// 설정 화면 (DraggableScrollableSheet 사용)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  NotificationSettings _notificationSettings = NotificationSettings.empty();
  bool _isLoading = true;
  bool _isSaving = false; // 저장 중 상태


  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final notificationSettings = await settingsStorage.loadNotificationSettings();
    
    setState(() {
      _notificationSettings = notificationSettings;
      _isLoading = false;
    });
  }

  Future<void> _saveNotificationSettings() async {
    await settingsStorage.saveNotificationSettings(_notificationSettings);
  }

  /// 모든 설정 저장
  Future<void> _saveAllSettings() async {
    if (_isSaving) return; // 이미 저장 중이면 무시

    setState(() {
      _isSaving = true;
    });

    try {
      await _saveNotificationSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('설정이 저장되었습니다'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('저장 중 오류가 발생했습니다: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 핸들 바
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '설정',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // 스크롤 가능한 내용
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildNotificationSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '알림',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitchField(
          label: '알림 활성화',
          value: _notificationSettings.enabled,
          onChanged: (value) {
            setState(() {
              _notificationSettings = _notificationSettings.copyWith(enabled: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildSwitchField(
          label: '채팅 알림',
          value: _notificationSettings.chatNotifications,
          onChanged: (value) {
            setState(() {
              _notificationSettings = _notificationSettings.copyWith(
                chatNotifications: value,
              );
            });
          },
        ),
        const SizedBox(height: 12),
        _buildSwitchField(
          label: '운세 알림',
          value: _notificationSettings.fortuneNotifications,
          onChanged: (value) {
            setState(() {
              _notificationSettings = _notificationSettings.copyWith(
                fortuneNotifications: value,
              );
            });
          },
        ),
      ],
    );
  }


  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveAllSettings,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: _isSaving ? Colors.grey : Colors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        disabledBackgroundColor: Colors.grey,
      ),
      child: _isSaving
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '저장 중...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : const Text(
              '저장',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

