import 'package:flutter/material.dart';
import 'models/saju_info.dart';
import 'services/saju_storage_service.dart';

/// 사주 리스트 상태 관리 Provider
class SajuProvider with ChangeNotifier {
  final List<SajuInfo> _sajuList = [];

  /// 읽기 전용 사주 리스트
  List<SajuInfo> get sajuList => List.unmodifiable(_sajuList);

  /// 리스트 초기화 (저장소에서 불러온 데이터로)
  void setList(List<SajuInfo> list) {
    debugPrint('provider setList: ${list.length}개');
    _sajuList
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  /// 사주 추가
  Future<void> add(SajuInfo saju) async {
    debugPrint('provider add: ${saju.name}');
    _sajuList.add(saju);
    notifyListeners();
    await sajuStorage.addSaju(saju);
  }

  /// 인덱스로 사주 수정
  void update(int index, SajuInfo newSaju) {
    if (index < 0 || index >= _sajuList.length) return;
    debugPrint('provider update: index=$index');
    _sajuList[index] = newSaju;
    notifyListeners();
  }

  /// 기존 사주를 새 사주로 교체
  Future<void> updateItem(SajuInfo original, SajuInfo updated) async {
    debugPrint('provider updateItem: ${original.name} → ${updated.name}');
    final index = _sajuList.indexWhere(
      (item) => item.name == original.name && item.birth == original.birth,
    );
    
    if (index != -1) {
      _sajuList[index] = updated;
      await sajuStorage.updateSaju(original, updated);
      notifyListeners();
    }
  }

  /// 사주 삭제
  Future<void> remove(SajuInfo saju) async {
    debugPrint('provider remove: ${saju.name}');
    _sajuList.removeWhere(
      (item) => item.name == saju.name && item.birth == saju.birth,
    );
    notifyListeners();
    await sajuStorage.deleteSaju(saju);
  }

  /// 즐겨찾기 토글
  void toggleFavorite(int index) {
    if (index < 0 || index >= _sajuList.length) return;
    _sajuList[index].isFavorite = !_sajuList[index].isFavorite;
    notifyListeners();
  }

  /// 이름으로 사주 찾기
  SajuInfo? findByName(String name) {
    try {
      return _sajuList.firstWhere((item) => item.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 리스트가 비어있는지 확인
  bool get isEmpty => _sajuList.isEmpty;

  /// 리스트 크기
  int get length => _sajuList.length;
}
