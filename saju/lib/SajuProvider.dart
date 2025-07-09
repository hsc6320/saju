import 'package:flutter/material.dart';
import 'package:saju/SharedPreferences.dart';

class SajuProvider with ChangeNotifier {
  final List<SajuInfo> _sajuList = [];

  List<SajuInfo> get sajuList => List.unmodifiable(_sajuList);

  void setList(List<SajuInfo> list) {
    print("provider setList");
    _sajuList
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  void add(SajuInfo saju) async {
    print("provider add, name : ${saju.name}");
    _sajuList.add(saju);
    notifyListeners();
    await addSaju(saju);
  }

  void update(int index, SajuInfo newSaju) {
    print("provider update");
    _sajuList[index] = newSaju;
    notifyListeners();
  }
  void updateItem(SajuInfo original, SajuInfo updated) {
    print("provider updateItem");
    final index = _sajuList.indexWhere((item) =>
        item.name == original.name && item.birth == original.birth);
    if (index != -1) {
      _sajuList[index] = updated;
      deleteSaju(original); // 기존 삭제
      addSaju(updated);     // 수정된 항목 다시 저장
      notifyListeners();
    }
  }


  void remove(SajuInfo saju) async {
    print("provider remove");
    _sajuList.removeWhere((item) =>
        item.name == saju.name && item.birth == saju.birth);
    notifyListeners();
    await deleteSaju(saju); // ✅ SharedPreferences 삭제
  }

  void toggleFavorite(int index) {
    _sajuList[index].isFavorite = !_sajuList[index].isFavorite;
    notifyListeners();
  }
}
