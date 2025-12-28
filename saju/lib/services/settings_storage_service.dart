import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../models/personal_info.dart';

/// 설정 데이터 저장/로드를 담당하는 서비스
class SettingsStorageService {
  static SettingsStorageService? _instance;
  SharedPreferences? _prefs;

  SettingsStorageService._();

  static SettingsStorageService get instance {
    _instance ??= SettingsStorageService._();
    return _instance!;
  }

  /// SharedPreferences 초기화
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _preferences async {
    await init();
    return _prefs!;
  }

  // ============ 개인맞춤입력 정보 ============

  /// 개인맞춤입력 정보 저장
  Future<void> savePersonalInfo(PersonalInfo info) async {
    final prefs = await _preferences;
    await prefs.setString(StorageKeys.personalInfo, jsonEncode(info.toJson()));
  }

  /// 개인맞춤입력 정보 불러오기
  Future<PersonalInfo> loadPersonalInfo() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(StorageKeys.personalInfo);
    if (jsonStr == null) {
      return PersonalInfo.empty();
    }
    return PersonalInfo.fromJson(jsonDecode(jsonStr));
  }

  // ============ 알림 설정 ============

  /// 알림 설정 저장
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    final prefs = await _preferences;
    await prefs.setString(
      StorageKeys.notificationSettings,
      jsonEncode(settings.toJson()),
    );
  }

  /// 알림 설정 불러오기
  Future<NotificationSettings> loadNotificationSettings() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(StorageKeys.notificationSettings);
    if (jsonStr == null) {
      return NotificationSettings.empty();
    }
    return NotificationSettings.fromJson(jsonDecode(jsonStr));
  }
}

/// 간편 접근용 전역 함수
SettingsStorageService get settingsStorage => SettingsStorageService.instance;

