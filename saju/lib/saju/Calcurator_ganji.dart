import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;


class GanjiYearCalculator {
  List<String> heavenlyStemsHanja = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  List<String> earthlyBranchesHanja = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  
  final customStems = ['庚','辛','壬','癸','甲','乙','丙','丁','戊','己'];
  final customBranches = ['申','酉','戌','亥','子','丑','寅','卯','辰','巳','午','未'];
  String yearGanji = '';
  String monthGanji = '';

  final monthBranches = ['寅','卯','辰','巳','午','未','申','酉','戌','亥','子','丑'];
  final monthStemsStartMap = {
    '甲': '丙', '己': '丙',
    '乙': '戊', '庚': '戊',
    '丙': '庚', '辛': '庚',
    '丁': '壬', '壬': '壬',
    '戊': '甲', '癸': '甲',
  };
  final stems = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];


  void calculateGanji (DateTime birth) {
    int solarYear = birth.year;
    int stemIndex = solarYear % 10;
    int branchIndex = solarYear % 12;
    yearGanji = customStems[stemIndex] + customBranches[branchIndex];

    String yearStem = yearGanji.substring(0, 1);
    String startStem = monthStemsStartMap[yearStem]!;
    int stemStartIndex = stems.indexOf(startStem);
    int lunarMonth = birth.month; // TODO: replace with lunar month when available
    String stem = stems[(stemStartIndex + lunarMonth - 1) % 10];
    String branch = monthBranches[(lunarMonth - 1) % 12];
    monthGanji = stem + branch;
    print("111111monthGanji : $monthGanji, yearGanji : $yearGanji");

  }

  String getYearGanJi(int year) {
    int baseYear = 1984;
    int offset = year - baseYear;
    int stemIndex = offset % 10;
    int branchIndex = offset % 12;
    return heavenlyStemsHanja[stemIndex] + earthlyBranchesHanja[branchIndex];
  }

  String getYearGan(int year) {
    int baseYear = 1984;
    int offset = year - baseYear;
    int stemIndex = offset % 10;
    
    return heavenlyStemsHanja[stemIndex];
  }

  String getYearJi(int year) {
    int baseYear = 1984;
    int offset = year - baseYear;
    
    int branchIndex = offset % 12;
    return earthlyBranchesHanja[branchIndex];
  }
}

class GanjiMonthCalculator {
  final List<String> heavenlyStems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  final List<String> earthlyBranches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  final List<String> monthBranches = ['寅','卯','辰','巳','午','未','申','酉','戌','亥','子','丑'];

  Map<String, int> monthStemStartIndex = {
    '甲': 2, '己': 2,
    '乙': 4, '庚': 4,
    '丙': 6, '辛': 6,
    '丁': 8, '壬': 8,
    '戊': 0, '癸': 0,
  };

  // 각 절기 입절일 (간단 예시, 실제론 매년 다를 수 있음 — 천문 라이브러리 연동 가능)
  List<DateTime> solarTermStartDates1988 = [
    DateTime(1988, 2, 4),  // 입춘 (1월)
    DateTime(1988, 3, 5),  // 경칩 (2월)
    DateTime(1988, 4, 4),  // 청명 (3월)
    DateTime(1988, 5, 5),  // 입하 (4월)
    DateTime(1988, 6, 5),  // 망종 (5월)
    DateTime(1988, 7, 7),  // 소서 (6월)
    DateTime(1988, 8, 7),  // 입추 (7월)
    DateTime(1988, 9, 7),  // 백로 (8월)
    DateTime(1988, 10, 8), // 한로 (9월)
    DateTime(1988, 11, 7), // 입동 (10월)
    DateTime(1988, 12, 7), // 대설 (11월)
    DateTime(1989, 1, 6),  // 소한 (12월)
  ];

  String getMonthGanJi(DateTime date) {
    int year = date.year;
    int yearStemIndex = (year - 1984) % 10;
    if (yearStemIndex < 0) yearStemIndex += 10;
    String yearStem = heavenlyStems[yearStemIndex];
    int baseStemIndex = monthStemStartIndex[yearStem] ?? 0;

    // 절기 기준 월 index 찾기
    int monthIndex = 11; // 기본: 12월
    for (int i = 0; i < solarTermStartDates1988.length; i++) {
      if (date.isBefore(solarTermStartDates1988[i])) {
        monthIndex = i - 1;
        break;
      }
    }

    if (monthIndex < 0) monthIndex = 11;

    String stem = heavenlyStems[(baseStemIndex + monthIndex) % 10];
    String branch = monthBranches[monthIndex];
    return stem + branch;
  }
}

/* 천문력 API 사용시 */
class GanjiFetcher {
  
  static Future<Map<String, String>?> fetchGanji(DateTime date) async {
    //final serviceKey = 'pqzKeusfrDJdZttN%2BORxf2wYNv1sI0h%2Ft0lDkmBB41boZ7g4ZEwFHSzYAX36u%2FXgDRSRQGYJ5GqOh0jrh6He8g%3D%3D';
                         
    final url = Uri.parse(
      'http://apis.data.go.kr/B090041/openapi/service/LrsrCldInfoService/getLunCalInfo?solYear=1954&solMonth=08&solDay=30&ServiceKey=pqzKeusfrDJdZttN%2BORxf2wYNv1sI0h%2Ft0lDkmBB41boZ7g4ZEwFHSzYAX36u%2FXgDRSRQGYJ5GqOh0jrh6He8g%3D%3D'
    );

    final response = await http.get(url);
    print("${date.year}, solMonth=${date.month}&solDay=${date.day}");
    print('📦 API 응답:\n${response.body}');
    if (response.statusCode == 200) {
      final doc = xml.XmlDocument.parse(response.body);
      final item = doc.findAllElements('item').first;

      return {
        'ganjiYear': item.getElement('ganjiYear')?.text ?? '',
        'ganjiMonth': item.getElement('ganjiMonth')?.text ?? '',
        'ganjiDay': item.getElement('ganjiDay')?.text ?? '',
      };
    } else {
      debugPrint('API 호출 실패: ${response.statusCode}');
      return null;
    }
  }
}

class GanjiCalculator {
  final List<String> heavenlyStems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  final List<String> earthlyBranches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  final List<List<String>> hourStemTable = [
    ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'],
    ['乙','丙','丁','戊','己','庚','辛','壬','癸','甲'],
    ['丙','丁','戊','己','庚','辛','壬','癸','甲','乙'],
    ['丁','戊','己','庚','辛','壬','癸','甲','乙','丙'],
    ['戊','己','庚','辛','壬','癸','甲','乙','丙','丁'],
    ['己','庚','辛','壬','癸','甲','乙','丙','丁','戊'],
    ['庚','辛','壬','癸','甲','乙','丙','丁','戊','己'],
    ['辛','壬','癸','甲','乙','丙','丁','戊','己','庚'],
    ['壬','癸','甲','乙','丙','丁','戊','己','庚','辛'],
    ['癸','甲','乙','丙','丁','戊','己','庚','辛','壬'],
    ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'],
    ['乙','丙','丁','戊','己','庚','辛','壬','癸','甲'],
  ];

  String getDayGanJi(DateTime date) {
    DateTime baseDate = DateTime(1899, 12, 22);
    int diffDays = date.difference(baseDate).inDays;
    int index = diffDays % 60;
    if (index < 0) index += 60;
    print("diffDays : $diffDays, index : $index");
    return heavenlyStems[index % 10] + earthlyBranches[index % 12];
  }

  // 시간 → 시지 인덱스
  int getHourBranchIndex(DateTime date) {
    final int h = date.hour;
    final int m = date.minute;
    final double time = h + m / 60.0;

    if (time >= 23.5 || time < 1.5) return 0;   // 子: 23:30 ~ 01:29
    if (time >= 1.5 && time < 3.5) return 1;    // 丑
    if (time >= 3.5 && time < 5.5) return 2;    // 寅
    if (time >= 5.5 && time < 7.5) return 3;    // 卯
    if (time >= 7.5 && time < 9.5) return 4;    // 辰
    if (time >= 9.5 && time < 11.5) return 5;   // 巳
    if (time >= 11.5 && time < 13.5) return 6;  // 午
    if (time >= 13.5 && time < 15.5) return 7;  // 未
    if (time >= 15.5 && time < 17.5) return 8;  // 申
    if (time >= 17.5 && time < 19.5) return 9;  // 酉
    if (time >= 19.5 && time < 21.5) return 10; // 戌
    return 11;                                  // 亥
  }
  void getHourGanji(DateTime date, String dayGanji) {
    final heavenlyStems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    final earthlyBranches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

    final stem = dayGanji.characters.first;
    final stemIndex = heavenlyStems.indexOf(stem);
    print("일간: $stem → 인덱스: $stemIndex");  // 壬 → 8

    final hourIndex = getHourBranchIndex(date);
    final branch = earthlyBranches[hourIndex];
    print("시간: ${date.hour}:${date.minute} → 시지: $branch (index $hourIndex)");

    final hourStemTable = [
      ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸', '甲','乙'], // 갑이나 기일주일때 
      ['丙','丁','戊','己','庚','辛','壬','癸','甲','乙','丙','丁'], // 을이나 경
      ['戊','己','庚','辛','壬','癸','甲','乙','丙','丁', '戊','己',], // 병이나 신
      ['庚','辛','壬','癸','甲','乙','丙','丁','戊','己','庚','辛'], // 정이나 임
      ['壬','癸','甲','乙','丙','丁','戊','己','庚','辛','壬','癸'], // 무나 계
    ];

    final hourStem = hourStemTable[hourIndex][stemIndex];
    print("시간(天干): $hourStem, 시지: $branch → 시주: $hourStem$branch");
  }


}
