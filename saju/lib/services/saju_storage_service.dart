import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../models/saju_info.dart';
import '../models/selected_saju_data.dart';

/// 사주 데이터 저장/로드를 담당하는 서비스
class SajuStorageService {
  static SajuStorageService? _instance;
  SharedPreferences? _prefs;

  SajuStorageService._();

  static SajuStorageService get instance {
    _instance ??= SajuStorageService._();
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

  // ============ 사주 리스트 CRUD ============

  /// 사주 리스트 저장
  Future<void> saveSajuList(List<SajuInfo> list) async {
    final prefs = await _preferences;
    final jsonList = list.map((saju) => jsonEncode(saju.toJson())).toList();
    await prefs.setStringList(StorageKeys.sajuList, jsonList);
  }

  /// 사주 리스트 불러오기
  Future<List<SajuInfo>> loadSajuList() async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(StorageKeys.sajuList) ?? [];
    return jsonList
        .map((jsonStr) => SajuInfo.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  /// 사주 추가
  Future<void> addSaju(SajuInfo saju) async {
    final list = await loadSajuList();
    list.add(saju);
    await saveSajuList(list);
  }

  /// 사주 삭제
  Future<void> deleteSaju(SajuInfo target) async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(StorageKeys.sajuList) ?? [];
    
    jsonList.removeWhere((jsonStr) {
      final map = jsonDecode(jsonStr);
      return map['name'] == target.name && map['birth'] == target.birth;
    });
    
    await prefs.setStringList(StorageKeys.sajuList, jsonList);
  }

  /// 사주 업데이트
  Future<void> updateSaju(SajuInfo original, SajuInfo updated) async {
    await deleteSaju(original);
    await addSaju(updated);
  }

  // ============ 선택된 사주 저장/로드 ============

  /// 선택된 사주 데이터 저장
  Future<void> saveSelectedSaju(SelectedSajuData data) async {
    final prefs = await _preferences;

    if (data.saju == null || !data.saju!.isValid) {
      await clearSelectedSaju();
      return;
    }

    // 기본 정보 저장
    await prefs.setString(StorageKeys.selectedSaju, jsonEncode(data.saju!.toJson()));
    await prefs.setString(StorageKeys.selectedGanji, jsonEncode(data.ganji));
    await prefs.setString(StorageKeys.selectedDaewoon, jsonEncode(data.daewoon));
    await prefs.setString(StorageKeys.selectedAge, data.koreanAge);
    await prefs.setString(StorageKeys.selectedCurrentDaewoon, data.currentDaewoon);
    await prefs.setInt(StorageKeys.selectedFirstLuckAge, data.firstLuckAge);

    // 십성 정보 저장
    await prefs.setString(StorageKeys.sipseongYinyang, data.sipseong.yinYang);
    await prefs.setString(StorageKeys.sipseongFiveElement, data.sipseong.fiveElement);
    await prefs.setString(StorageKeys.sipseongYearGan, data.sipseong.yearGan);
    await prefs.setString(StorageKeys.sipseongYearJi, data.sipseong.yearJi);
    await prefs.setString(StorageKeys.sipseongWolGan, data.sipseong.wolGan);
    await prefs.setString(StorageKeys.sipseongWolJi, data.sipseong.wolJi);
    await prefs.setString(StorageKeys.sipseongIlGan, data.sipseong.ilGan);
    await prefs.setString(StorageKeys.sipseongIlJi, data.sipseong.ilJi);
    await prefs.setString(StorageKeys.sipseongSiGan, data.sipseong.siGan);
    await prefs.setString(StorageKeys.sipseongSiJi, data.sipseong.siJi);
    await prefs.setString(StorageKeys.sipseongCurrDaewoonGan, data.sipseong.currDaewoonGan);
    await prefs.setString(StorageKeys.sipseongCurrDaewoonJi, data.sipseong.currDaewoonJi);
  }

  /// 선택된 사주 데이터 불러오기
  Future<SelectedSajuData> loadSelectedSaju() async {
    final prefs = await _preferences;

    final sajuJson = prefs.getString(StorageKeys.selectedSaju);
    if (sajuJson == null) {
      return SelectedSajuData.empty();
    }

    final ganjiJson = prefs.getString(StorageKeys.selectedGanji);
    final daewoonJson = prefs.getString(StorageKeys.selectedDaewoon);
    final koreanAge = prefs.getString(StorageKeys.selectedAge) ?? '';
    final currentDaewoon = prefs.getString(StorageKeys.selectedCurrentDaewoon) ?? '';
    final firstLuckAge = prefs.getInt(StorageKeys.selectedFirstLuckAge) ?? 0;

    // 십성 정보 불러오기
    final sipseong = SipseongInfo(
      yinYang: prefs.getString(StorageKeys.sipseongYinyang) ?? '',
      fiveElement: prefs.getString(StorageKeys.sipseongFiveElement) ?? '',
      yearGan: prefs.getString(StorageKeys.sipseongYearGan) ?? '',
      yearJi: prefs.getString(StorageKeys.sipseongYearJi) ?? '',
      wolGan: prefs.getString(StorageKeys.sipseongWolGan) ?? '',
      wolJi: prefs.getString(StorageKeys.sipseongWolJi) ?? '',
      ilGan: prefs.getString(StorageKeys.sipseongIlGan) ?? '',
      ilJi: prefs.getString(StorageKeys.sipseongIlJi) ?? '',
      siGan: prefs.getString(StorageKeys.sipseongSiGan) ?? '',
      siJi: prefs.getString(StorageKeys.sipseongSiJi) ?? '',
      currDaewoonGan: prefs.getString(StorageKeys.sipseongCurrDaewoonGan) ?? '',
      currDaewoonJi: prefs.getString(StorageKeys.sipseongCurrDaewoonJi) ?? '',
    );

    return SelectedSajuData(
      saju: SajuInfo.fromJson(jsonDecode(sajuJson)),
      ganji: ganjiJson != null ? Map<String, String?>.from(jsonDecode(ganjiJson)) : {},
      daewoon: daewoonJson != null ? List<String>.from(jsonDecode(daewoonJson)) : [],
      koreanAge: koreanAge,
      currentDaewoon: currentDaewoon,
      sipseong: sipseong,
      firstLuckAge: firstLuckAge,
    );
  }

  /// 선택된 사주 데이터 삭제
  Future<void> clearSelectedSaju() async {
    final prefs = await _preferences;
    for (final key in StorageKeys.allSelectedSajuKeys) {
      await prefs.remove(key);
    }
  }

  /// 전체 데이터 삭제
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.clear();
  }
}

/// 간편 접근용 전역 함수
SajuStorageService get sajuStorage => SajuStorageService.instance;


