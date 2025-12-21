import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../constants/saju_constants.dart';

/// 간지(干支) 계산 서비스
class GanjiCalculator {
  GanjiCalculator._();

  static List<dynamic>? _jsonData;

  /// JSON 데이터 로드 (캐싱)
  static Future<List<dynamic>> _loadJsonData() async {
    if (_jsonData != null) return _jsonData!;
    final jsonString = await rootBundle.loadString('assets/converted.json');
    _jsonData = json.decode(jsonString);
    return _jsonData!;
  }

  // ============ 음력/양력 변환 ============

  /// 양력 → 음력 변환
  static Future<String?> getLunarFromSolar(DateTime solarDate) async {
    final jsonData = await _loadJsonData();

    DateTime? closestSolarDate;
    DateTime? closestLunarBaseDate;

    for (var item in jsonData) {
      try {
        final currentSolarDate = DateTime.parse(item['양력기준일']);
        if (currentSolarDate.isAfter(solarDate)) continue;

        if (closestSolarDate == null || currentSolarDate.isAfter(closestSolarDate)) {
          closestSolarDate = currentSolarDate;
          closestLunarBaseDate = DateTime.parse(item['음력기준일']);
        }
      } catch (_) {
        continue;
      }
    }

    if (closestSolarDate == null || closestLunarBaseDate == null) return null;

    final diff = solarDate.difference(closestSolarDate).inDays;
    final calculatedLunarDate = closestLunarBaseDate.add(Duration(days: diff));

    return '${calculatedLunarDate.year}-${calculatedLunarDate.month.toString().padLeft(2, '0')}-${calculatedLunarDate.day.toString().padLeft(2, '0')}';
  }

  /// 음력 → 양력 변환
  static Future<DateTime?> getSolarFromLunar(DateTime lunarDate) async {
    final jsonData = await _loadJsonData();

    DateTime? closestLunarDate;
    DateTime? closestSolarBaseDate;

    for (var item in jsonData) {
      try {
        final currentLunarDate = DateTime.parse(item['음력기준일']);
        if (currentLunarDate.isAfter(lunarDate)) continue;

        if (closestLunarDate == null || currentLunarDate.isAfter(closestLunarDate)) {
          closestLunarDate = currentLunarDate;
          closestSolarBaseDate = DateTime.parse(item['양력기준일']);
        }
      } catch (_) {
        continue;
      }
    }

    if (closestLunarDate == null || closestSolarBaseDate == null) return null;

    final diff = lunarDate.difference(closestLunarDate);
    return closestSolarBaseDate.add(diff);
  }

  // ============ 간지 변환 ============

  /// 한글 간지 → 한자 변환
  static String convertToHanja(String ganji) {
    ganji = ganji.trim();
    if (ganji.length != 2) return ganji;

    final ganIndex = SajuConstants.ganList.indexOf(ganji[0]);
    final jiIndex = SajuConstants.jiList.indexOf(ganji[1]);

    if (ganIndex == -1 || jiIndex == -1) return ganji;

    return SajuConstants.ganListHanja[ganIndex] + SajuConstants.jiListHanja[jiIndex];
  }

  /// 한글 천간 → 한자 변환
  static String convertGanToHanja(String gan) {
    gan = gan.trim();
    if (gan.length != 1) return gan;

    final ganIndex = SajuConstants.ganList.indexOf(gan[0]);
    if (ganIndex == -1) return gan;

    return SajuConstants.ganListHanja[ganIndex];
  }

  // ============ 사주 계산 ============

  /// 년주(年柱) 계산
  static Future<String> getYearGanji(DateTime date) async {
    final jsonData = await _loadJsonData();

    for (int i = jsonData.length - 1; i >= 0; i--) {
      final entry = jsonData[i];
      final baseDate = DateTime.parse(entry['양력기준일']);
      if (date.isAfter(baseDate) || date.isAtSameMomentAs(baseDate)) {
        final ganji = entry['년주'].toString().trim();
        return convertToHanja(ganji);
      }
    }
    return 'Unknown';
  }

  /// 월주(月柱) 계산
  static Future<String?> getWolJu(DateTime solarDate) async {
    final jsonData = await _loadJsonData();

    DateTime? closestSolarDate;
    Map<String, dynamic>? selectedItem;

    for (final item in jsonData) {
      try {
        final currentSolar = DateTime.parse(item['양력기준일']);
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

    // 연간 추출
    final String yearStem = selectedItem['년주'].toString().trim().substring(0, 1);
    final int groupIndex = _getYearGroupIndex(yearStem);
    if (groupIndex == -1) return null;

    // 절기 기준으로 월 인덱스 결정
    int monthIndex = -1;
    for (int i = 0; i < SajuConstants.solarTerms.length; i++) {
      final term = SajuConstants.solarTerms[i];
      var termDate = DateTime(solarDate.year, term['month'], term['day']);
      if (i == 11) {
        termDate = DateTime(solarDate.year + 1, term['month'], term['day']);
      }
      if (!solarDate.isBefore(termDate)) {
        monthIndex = i;
      }
    }

    if (monthIndex == -1) monthIndex = 11;

    return SajuConstants.monthStemTable[groupIndex][monthIndex];
  }

  /// 일주(日柱) 계산
  static Future<String> getIlJu(DateTime solarDate) async {
    final jsonData = await _loadJsonData();

    Map<String, dynamic>? closestData;
    DateTime? closestDate;

    for (var item in jsonData) {
      final itemDate = DateTime.parse(item['양력기준일']);
      if (itemDate.isBefore(solarDate) || itemDate.isAtSameMomentAs(solarDate)) {
        if (closestDate == null || itemDate.isAfter(closestDate)) {
          closestDate = itemDate;
          closestData = item;
        }
      }
    }

    if (closestData == null) throw Exception('기준일을 찾을 수 없습니다.');

    final baseIlju = closestData['일주'].trim();
    final baseDate = DateTime.parse(closestData['양력기준일']);
    final baseIndex = SajuConstants.ganji60.indexOf(baseIlju);
    final diffDays = solarDate.difference(baseDate).inDays;

    final iljuIndex = (baseIndex + diffDays) % 60;
    return convertToHanja(SajuConstants.ganji60[iljuIndex].trim());
  }

  /// 시주(時柱) 계산
  static String getSiJu(DateTime time, String ilJu) {
    final ilGan = ilJu.substring(0, 1);

    // 시간 인덱스 계산
    final totalMinutes = time.hour * 60 + time.minute;
    int siIndex;
    if (totalMinutes >= 1410 || totalMinutes < 90) {
      siIndex = 0; // 子시
    } else if (totalMinutes < 210) {
      siIndex = 1; // 丑시
    } else if (totalMinutes < 330) {
      siIndex = 2; // 寅시
    } else if (totalMinutes < 450) {
      siIndex = 3; // 卯시
    } else if (totalMinutes < 570) {
      siIndex = 4; // 辰시
    } else if (totalMinutes < 690) {
      siIndex = 5; // 巳시
    } else if (totalMinutes < 810) {
      siIndex = 6; // 午시
    } else if (totalMinutes < 930) {
      siIndex = 7; // 未시
    } else if (totalMinutes < 1050) {
      siIndex = 8; // 申시
    } else if (totalMinutes < 1170) {
      siIndex = 9; // 酉시
    } else if (totalMinutes < 1290) {
      siIndex = 10; // 戌시
    } else {
      siIndex = 11; // 亥시
    }

    // 일간 그룹 매핑
    String? group;
    if (['甲', '己'].contains(ilGan)) {
      group = 'A';
    } else if (['乙', '庚'].contains(ilGan)) {
      group = 'B';
    } else if (['丙', '辛'].contains(ilGan)) {
      group = 'C';
    } else if (['丁', '壬'].contains(ilGan)) {
      group = 'D';
    } else if (['戊', '癸'].contains(ilGan)) {
      group = 'E';
    }

    return SajuConstants.siJuTable[group]?[siIndex] ?? '시주 계산 오류';
  }

  /// 연간 그룹 인덱스 반환
  static int _getYearGroupIndex(String yearStem) {
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
}


