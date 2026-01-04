import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// 개인맞춤입력 정보 저장 (사주별로 저장)
  /// [name]과 [birth]를 키로 사용하여 사주별로 개인맞춤입력 정보를 저장합니다.
  Future<void> savePersonalInfo(PersonalInfo info, {String? name, String? birth}) async {
    final prefs = await _preferences;
    
    // name과 birth가 제공된 경우 사주별로 저장
    if (name != null && name.isNotEmpty && birth != null && birth.isNotEmpty) {
      final key = '${StorageKeys.personalInfo}_${name}_$birth';
      await prefs.setString(key, jsonEncode(info.toJson()));
      debugPrint('✅ 사주별 개인맞춤입력 정보 저장: $name ($birth)');
    } else {
      // 레거시: 전역 저장 (하위 호환성)
      await prefs.setString(StorageKeys.personalInfo, jsonEncode(info.toJson()));
      debugPrint('⚠️ 전역 개인맞춤입력 정보 저장 (레거시)');
    }
  }

  /// 개인맞춤입력 정보 불러오기 (사주별로 로드)
  /// [name]과 [birth]를 키로 사용하여 해당 사주의 개인맞춤입력 정보를 불러옵니다.
  Future<PersonalInfo> loadPersonalInfo({String? name, String? birth}) async {
    final prefs = await _preferences;
    
    // name과 birth가 제공된 경우 사주별로 로드
    if (name != null && name.isNotEmpty && birth != null && birth.isNotEmpty) {
      final key = '${StorageKeys.personalInfo}_${name}_$birth';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        debugPrint('✅ 사주별 개인맞춤입력 정보 로드: $name ($birth)');
        return PersonalInfo.fromJson(jsonDecode(jsonStr));
      }
      debugPrint('ℹ️ 사주별 개인맞춤입력 정보 없음: $name ($birth)');
    }
    
    // 사주별 정보가 없으면 빈 정보 반환
    return PersonalInfo.empty();
  }

  /// 특정 사주의 개인맞춤입력 정보 삭제
  Future<void> deletePersonalInfo(String name, String birth) async {
    final prefs = await _preferences;
    final key = '${StorageKeys.personalInfo}_${name}_$birth';
    await prefs.remove(key);
    debugPrint('🗑️ 사주별 개인맞춤입력 정보 삭제: $name ($birth)');
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

