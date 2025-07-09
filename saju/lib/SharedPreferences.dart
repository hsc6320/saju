import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:saju/screens/saju_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
/* **************************************************************************** 
json 저장 형식
{
  "saju_list": [
    "{\"name\":\"홍길동\",\"birth\":\"2023-05-28\",\"...\":...}",
    "{\"name\":\"아들\",\"birth\":\"2022-11-11\",\"...\":...}"
  ]
}
******************************************************************************** */
class SajuInfo {
  final String name;
  final String relation;
  final String birth;
  final String element;
  final String lunar;
  final TimeOfDay time;
  bool isFavorite;
  final bool isEditing;

  SajuInfo({
    required this.name,
    required this.relation,
    required this.birth,
    required this.element,
    required this.lunar,
    required this.time,
    this.isFavorite = false,
    this.isEditing = false, // 기본값은 false
  });
  bool get isValid =>
      name.isNotEmpty &&
      relation.isNotEmpty &&
      birth.isNotEmpty &&
      lunar.isNotEmpty;
      
  DateTime get birthDateTime {
    final parts = birth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(year, month, day, time.hour, time.minute);
  }


  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'birth': birth,
        'element': element,
        'isLunar': lunar,
        'time': '${time.hour}:${time.minute}',
        'isFavorite': isFavorite,
      };

  factory SajuInfo.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    return SajuInfo(
      name: json['name'],
      relation: json['relation'],
      birth: json['birth'],
      element: json['element'],
      lunar: json['isLunar'],
      time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  SajuInfo copyWith({
    String? name,
    String? relation,
    String? birth,
    String? element,
    String? isLunar,
    TimeOfDay? time,
    bool? isFavorite,
    bool? isEditing,
    }) {
      return SajuInfo(
        name: name ?? this.name,
        relation: relation ?? this.relation,
        birth: birth ?? this.birth,//this.birth,
        element: element ?? this.element,//this.element,
        lunar: isLunar ?? this.lunar,//this.isLunar,
        time: time ?? this.time,//this.time,
        isFavorite: isFavorite ?? this.isFavorite,//this.isFavorite,
        isEditing: isEditing ?? this.isEditing,//this.isEditing,
      );
    }
}


Future<void> saveSajuList(List<SajuInfo> list) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = list.map((saju) => jsonEncode(saju.toJson())).toList();
  await prefs.setStringList('saju_list', jsonList);
}

Future<List<SajuInfo>> loadSajuList() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = prefs.getStringList('saju_list') ?? [];
  
  return jsonList
      .map((jsonStr) => SajuInfo.fromJson(jsonDecode(jsonStr)))
      .toList();
}

Future<void> deleteSaju(SajuInfo target) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = prefs.getStringList('saju_list') ?? [];
  print("delete saju : ${target.name}");
  jsonList.removeWhere((jsonStr) {
    final map = jsonDecode(jsonStr);

    print("jsonList.removeWhere ${map['name']}, ${target.name} ${map['birth']}");
    return map['name'] == target.name && map['birth'] == target.birth;
  });
  print('완료');
  await prefs.setStringList('saju_list', jsonList);
}

Future<void> addSaju(SajuInfo saju) async {
  final list = await loadSajuList();
  list.add(saju);
  await saveSajuList(list);
}

Future<void> saveUserDataAndNavigate({
  required BuildContext context,
  required DateTime selectedDate,
  required TimeOfDay selectedTime,
  required bool isLunar,
  required String inputName,
  required String gender,
  SajuInfo? originalSaju,
}) async {
  final saju = SajuInfo(
    name: inputName,
    relation: gender,
    birth: selectedDate.toIso8601String().split('T')[0],
    element: '', // TODO: 오행 분석 연결
    lunar: isLunar.toString(),
    time: selectedTime,
  );
  
  if (originalSaju != null) {
    await deleteSaju(originalSaju);
  }
  await addSaju(saju);

  print("name: $inputName, gender : $gender, lunar : $isLunar");
  List<Map<String, dynamic>> generateSolarTermsForYear(String name, String gender, bool isLunar) {
    return [
      {
        "name": name,
        "solar_date": isLunar,
        "gender": gender,
      },
    ];
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SajuListScreen(
        selectedTime: saju.birthDateTime,
        inputOption: generateSolarTermsForYear(saju.name, saju.relation, isLunar,
      ),
    ),
  ));
}


Future<Map<String, dynamic>?> loadUserData() async {
  print('SharedPreferences, loadUserData()');
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString('username');
  final gender = prefs.getString('gender');
  final lunar = prefs.getString('lunar');
  final dateStr = prefs.getString('selected_date');
  final timeStr = prefs.getString('selected_time');
  
  if (name != null && gender != null && dateStr != null && timeStr != null) {
    final selectedDate = DateTime.parse(dateStr);
    final parts = timeStr.split(':');
    final selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    print("selectedDate : $selectedDate, selectedTime : $selectedTime");
    return {
      'name': name,
      'gender': gender,
      'date': selectedDate,
      'time': selectedTime,
      'lunar': lunar, // 향후 확장
    };
  }

  return null;
}

Future<void> removeList(SajuInfo saju) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.remove('username'); // 특정 키만 제거
}
//prefs.remove('username'); // 특정 키만 제거
//prefs.clear();            // 전체 초기화