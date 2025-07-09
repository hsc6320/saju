import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;


/// 고정 절기 목록 (월주 계산용)
const List<Map<String, dynamic>> solarTerms = [
  
  //{"name": "대한", "month": 1, "day": 20},
  {"name": "입춘", "month": 2, "day": 4},
  //{"name": "우수", "month": 2, "day": 19},
  {"name": "경칩", "month": 3, "day": 5},
  //{"name": "춘분", "month": 3, "day": 20},
  {"name": "청명", "month": 4, "day": 5},
  //{"name": "곡우", "month": 4, "day": 20},
  {"name": "입하", "month": 5, "day": 5},
  //{"name": "소만", "month": 5, "day": 21},
  {"name": "망종", "month": 6, "day": 6},
  //{"name": "하지", "month": 6, "day": 21},
  {"name": "소서", "month": 7, "day": 7},
  //{"name": "대서", "month": 7, "day": 22},
  {"name": "입추", "month": 8, "day": 8},
  //{"name": "처서", "month": 8, "day": 23},
  {"name": "백로", "month": 9, "day": 8},
  //{"name": "추분", "month": 9, "day": 23},
  {"name": "한로", "month": 10, "day": 8},
  //{"name": "상강", "month": 10, "day": 23},
  {"name": "입동", "month": 11, "day": 8},
  //{"name": "소설", "month": 11, "day": 22},
  {"name": "대설", "month": 12, "day": 7},
  //{"name": "동지", "month": 12, "day": 22},
  {"name": "소한", "month": 1, "day": 5},
];


const List<String> ganList = ["갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"];
const List<String> ganListHanja = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"];

const List<String> jiList = ["자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해"];
const List<String> jiListHanja = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"];

 const List<List<String>> monthStemTable = [
    ['丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉', '甲戌', '乙亥', '丙子', '丁丑'], // 甲, 己
    ['戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未', '甲申', '乙酉', '丙戌', '丁亥', '戊子', '己丑'], // 乙, 庚
    ['庚寅', '辛卯', '壬辰', '癸巳', '甲午', '乙未', '丙申', '丁酉', '戊戌', '己亥', '庚子', '辛丑'], // 丙, 辛
    ['壬寅', '癸卯', '甲辰', '乙巳', '丙午', '丁未', '戊申', '己酉', '庚戌', '辛亥', '壬子', '癸丑'], // 丁, 壬
    ['甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉', '壬戌', '癸亥', '甲子', '乙丑'], // 戊, 癸
  ];


  // 연간에 따른 index 분류
  int getYearGroupIndex(String yearStem) {
    switch (yearStem) {
      case '갑':
      case '기':
        return 0;
      case '을':
      case '경':
        return 1;
      case '병':
      case '신':
        return 2;
      case '정':
      case '임':
        return 3;
      case '무':
      case '계':
        return 4;
      default:
        return -1;
    }
  }
// 양력 -> 음력
Future<String?> getLunarDateFromSolar(DateTime solarDate) async {
  final jsonString = await rootBundle.loadString('assets/converted.json');
  final List<dynamic> jsonData = json.decode(jsonString);

  DateTime? closestSolarDate;
  DateTime? closestLunarBaseDate;

  for (var item in jsonData) {
    final solarStr = item['양력기준일'];
    final lunarStr = item['음력기준일'];
    try {
      final currentSolarDate = DateTime.parse(solarStr);
      if (currentSolarDate.isAfter(solarDate)) continue;

      if (closestSolarDate == null || currentSolarDate.isAfter(closestSolarDate)) {
        closestSolarDate = currentSolarDate;
        closestLunarBaseDate = DateTime.parse(lunarStr);
      }
    } catch (e) {
      continue;
    }
  }

  if (closestSolarDate == null || closestLunarBaseDate == null) return null;

  // 날짜 차이 계산 후 음력 기준일에 더함
  final diff = solarDate.difference(closestSolarDate).inDays;
  final calculatedLunarDate = closestLunarBaseDate.add(Duration(days: diff));
  
  return "${calculatedLunarDate.year}-${calculatedLunarDate.month.toString().padLeft(2, '0')}-${calculatedLunarDate.day.toString().padLeft(2, '0')}";
}

// 음력 -> 양력
Future<DateTime?> getSolarDateFromLunar(DateTime lunarDate) async {
  final jsonString = await rootBundle.loadString('assets/converted.json');
  final List<dynamic> jsonData = json.decode(jsonString);

  DateTime? closestLunarDate;
  DateTime? closestSolarBaseDate;

  for (var item in jsonData) {
    final solarStr = item['양력기준일'];
    final lunarStr = item['음력기준일'];
    try {
      final currentLunarDate = DateTime.parse(lunarStr);
      if (currentLunarDate.isAfter(lunarDate)) continue;

      if (closestLunarDate == null || currentLunarDate.isAfter(closestLunarDate)) {
        closestLunarDate = currentLunarDate;
        closestSolarBaseDate = DateTime.parse(solarStr);
      }
    } catch (e) {
      continue;
    }
  }

  if (closestLunarDate == null || closestSolarBaseDate == null) return null;

  // 날짜 차이 계산 후 양력 기준일에 더함
  //final diff = lunarDate.difference(closestLunarDate).inDays;
  final diff = lunarDate.difference(closestLunarDate); // 🔥 시간 포함
  DateTime calculatedSolarDate = closestSolarBaseDate.add(diff);
  //DateTime calculatedSolarDate = closestSolarBaseDate.add(Duration(days: diff));
  print("음력 -> 양력 변환 : $calculatedSolarDate");

  return calculatedSolarDate;
  //return "${calculatedSolarDate.year}-${calculatedSolarDate.month.toString().padLeft(2, '0')}-${calculatedSolarDate.day.toString().padLeft(2, '0')}";
}


String convertGanjiToHanja(String ganji) {
  ganji = ganji.trim();
  if (ganji.length != 2) return ganji;
  
  String gan = ganji[0];
  String ji = ganji[1];

  int ganIndex = ganList.indexOf(gan);
  int jiIndex = jiList.indexOf(ji);

  if (ganIndex == -1 || jiIndex == -1) return ganji;
  
  return ganListHanja[ganIndex] + jiListHanja[jiIndex];
}

String convertGanToHanja(String ganji) {
  ganji = ganji.trim();
  if (ganji.length != 1) return ganji;
  
  String gan = ganji[0];

  int ganIndex = ganList.indexOf(gan);

  if (ganIndex == -1 ) return ganji;
  return ganListHanja[ganIndex] ;
}



Future<String> getYearGanjiFromJson(DateTime date) async {
  final String jsonStr = await rootBundle.loadString('assets/converted.json');
  final List<dynamic> jsonData = json.decode(jsonStr);
  getLunarDateFromSolar(date);
  // 기준일보다 같거나 이전 중 가장 최근 데이터를 찾음
  for (int i = jsonData.length - 1; i >= 0; i--) {
    final entry = jsonData[i];
    DateTime aa = DateTime.parse(entry["양력기준일"]);
    if (date.isAfter(aa) || date.isAtSameMomentAs(aa)) {
      String ganji = entry["년주"];
      return convertGanjiToHanja(ganji.trim());
    }
  }

  return "Unknown";
}
  
  Future<String?> getWolJuFromDate(DateTime solarDate) async {
    final jsonString = await rootBundle.loadString('assets/converted.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    DateTime? closestSolarDate;
    Map<String, dynamic>? selectedItem;

    for (final item in jsonData) {
      final solarStr = item['양력기준일'];
      try {
        final currentSolar = DateTime.parse(solarStr);
        if (currentSolar.isAfter(solarDate)) continue;
        if (closestSolarDate == null || currentSolar.isAfter(closestSolarDate)) {
          closestSolarDate = currentSolar;
          selectedItem = item;
        }
      } catch (_) {
        continue;
      }
    }

    if (selectedItem == null || closestSolarDate == null) return null;
    print("음력 변환 일 : $selectedItem");

    // 1. 연간 추출
    final String yearStem = selectedItem['년주'].toString().trim().substring(0, 1);
   // yearStem = convertGanToHanja(yearStem)
   
    final int groupIndex = getYearGroupIndex(yearStem);
    if (groupIndex == -1) return null;
    // 2. 절기 기준으로 월 인덱스 결정
    int monthIndex = -1;
    for (int i = 0; i < solarTerms.length; i++) {
      final term = solarTerms[i];
      var termDate = DateTime(solarDate.year, term['month'], term['day']);
      if(i == 11) {
        termDate = DateTime(solarDate.year+1, term['month'], term['day']);
      }
      if (!solarDate.isBefore(termDate)) {
        monthIndex = i;
      }
    }

    // 소한(1/6) 이전일 경우 전년도 12월로 간주
    if (monthIndex == -1) monthIndex = 11;

    return monthStemTable[groupIndex][monthIndex];
  }
  
const List<String> ganji60 = [
  '갑자', '을축', '병인', '정묘', '무진', '기사', '경오', '신미', '임신', '계유',
  '갑술', '을해', '병자', '정축', '무인', '기묘', '경진', '신사', '임오', '계미',
  '갑신', '을유', '병술', '정해', '무자', '기축', '경인', '신묘', '임진', '계사',
  '갑오', '을미', '병신', '정유', '무술', '기해', '경자', '신축', '임인', '계묘',
  '갑진', '을사', '병오', '정미', '무신', '기유', '경술', '신해', '임자', '계축',
  '갑인', '을묘', '병진', '정사', '무오', '기미', '경신', '신유', '임술', '계해'
];

Future<Map<String, dynamic>> getBaseJsonItem(DateTime solarDate) async {
  final jsonString = await rootBundle.loadString('assets/converted.json');
  final List<dynamic> jsonData = json.decode(jsonString);

  Map<String, dynamic>? closestData;
  DateTime? closestDate;

  for (var item in jsonData) {
    final itemDate = DateTime.parse(item["양력기준일"]);
    if (itemDate.isBefore(solarDate) || itemDate.isAtSameMomentAs(solarDate)) {
      if (closestDate == null || itemDate.isAfter(closestDate)) {
        closestDate = itemDate;
        closestData = item;
      }
    }
  }
  if (closestData == null) throw Exception('기준일을 찾을 수 없습니다.');
  return closestData;
}

Future<String> getIlJu(DateTime solarDate) async {
  final item = await getBaseJsonItem(solarDate);
  final baseIlju = item["일주"].trim();
  final baseDate = DateTime.parse(item["양력기준일"]);
  final baseIndex = ganji60.indexOf(baseIlju);
  final diffDays = solarDate.difference(baseDate).inDays;
    
  final iljuIndex = (baseIndex + diffDays) % 60;
  print("ganji60[$iljuIndex] : ${ganji60[iljuIndex]}");
  return convertGanjiToHanja(ganji60[iljuIndex].trim());//ganji60[iljuIndex];
}

//Future<Map<String, String>> getSiJu(DateTime time, String ilJu) async {
  String getSiJu(DateTime time, String ilJu) {
  final ilGan = ilJu.substring(0, 1);
  

  // 시지 인덱스 계산 (표 기준)
  int getSiIndex(DateTime time) {
    final totalMinutes = time.hour * 60 + time.minute;
    if (totalMinutes >= 1410 || totalMinutes < 90) return 0;   // 子시
    else if (totalMinutes < 210) return 1;  // 丑시
    else if (totalMinutes < 330) return 2;  // 寅시
    else if (totalMinutes < 450) return 3;  // 卯시
    else if (totalMinutes < 570) return 4;  // 辰시
    else if (totalMinutes < 690) return 5;  // 巳시
    else if (totalMinutes < 810) return 6;  // 午시
    else if (totalMinutes < 930) return 7;  // 未시
    else if (totalMinutes < 1050) return 8; // 申시
    else if (totalMinutes < 1170) return 9; // 酉시
    else if (totalMinutes < 1290) return 10;// 戌시
    else return 11;                         // 亥시
  }

  // 시주 표 (열: 일간 그룹, 행: 시간 index)
  const Map<String, List<String>> siJuTable = {
    'A': ['甲子', '乙丑', '丙寅', '丁卯', '戊辰', '己巳', '庚午', '辛未', '壬申', '癸酉', '甲戌', '乙亥'],
    'B': ['丙子', '丁丑', '戊寅', '己卯', '庚辰', '辛巳', '壬午', '癸未', '甲申', '乙酉', '丙戌', '丁亥'],
    'C': ['戊子', '己丑', '庚寅', '辛卯', '壬辰', '癸巳', '甲午', '乙未', '丙申', '丁酉', '戊戌', '己亥'],
    'D': ['庚子', '辛丑', '壬寅', '癸卯', '甲辰', '乙巳', '丙午', '丁未', '戊申', '己酉', '庚戌', '辛亥'],
    'E': ['壬子', '癸丑', '甲寅', '乙卯', '丙辰', '丁巳', '戊午', '己未', '庚申', '辛酉', '壬戌', '癸亥'],
  };

  // 일간 그룹 매핑
  String? group;
  if (['甲', '己'].contains(ilGan)) group = 'A';
  else if (['乙', '庚'].contains(ilGan)) group = 'B';
  else if (['丙', '辛'].contains(ilGan)) group = 'C';
  else if (['丁', '壬'].contains(ilGan)) group = 'D';
  else if (['戊', '癸'].contains(ilGan)) group = 'E';

  final siIndex = getSiIndex(time);
  final siJu = siJuTable[group]?[siIndex];
  return siJu ?? '시주 계산 오류';
}
