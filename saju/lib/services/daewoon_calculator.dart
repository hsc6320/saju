import '../constants/saju_constants.dart';

/// 대운(大運) / 세운(歲運) 계산 서비스
class DaewoonCalculator {
  DaewoonCalculator._();

  /// 순행/역행 판단
  /// - 양간 남자 또는 음간 여자 = 순행
  /// - 음간 남자 또는 양간 여자 = 역행
  static bool isSunHaeng(String yearGan, String gender) {
    final isYang = SajuConstants.isYang(yearGan);
    if ((isYang && gender == '남자') || (!isYang && gender == '여자')) {
      return true; // 순행
    }
    return false; // 역행
  }

  /// 가장 가까운 절기 찾기
  static DateTime getNearestSolarTerm(DateTime birthDate, bool isSunHaeng) {
    DateTime? nearest;
    int minDiff = 9999;

    for (var term in SajuConstants.solarTerms) {
      DateTime termDate = DateTime(
        birthDate.month == 1 && term['month'] == 12
            ? birthDate.year - 1
            : birthDate.year,
        term['month'],
        term['day'],
      );

      int diff = birthDate.difference(termDate).inDays;
      if (isSunHaeng) {
        // 순행: 미래 절기 중 가장 가까운 것
        int futureDiff = termDate.difference(birthDate).inDays;
        if (futureDiff >= 0 && futureDiff < minDiff) {
          minDiff = futureDiff;
          nearest = termDate;
        }
      } else {
        // 역행: 과거 절기 중 가장 가까운 것
        if (diff >= 0 && diff < minDiff) {
          minDiff = diff;
          nearest = termDate;
        }
      }
    }

    if (nearest == null) {
      throw Exception('조건에 맞는 절기를 찾지 못했습니다.');
    }
    return nearest;
  }

  /// 초대운 나이 계산 (절기까지 일수 ÷ 3)
  static int calculateFirstLuckAge(DateTime birthDate, bool isSunHaeng) {
    final nearestTerm = getNearestSolarTerm(birthDate, isSunHaeng);
    final days = nearestTerm.difference(birthDate).inDays;
    return (days.abs() / 3).floor();
  }

  /// 현재 대운 반환
  static String getCurrentDaewoon(int koreanAge, int firstLuckAge, List<String> daewoonList) {
    if (koreanAge < firstLuckAge) return '대운 없음';

    final index = (koreanAge - firstLuckAge) ~/ 10;
    if (index >= 0 && index < daewoonList.length) {
      return daewoonList[index];
    }
    return '대운 없음';
  }

  /// 대운 리스트 생성
  static List<String> generateDaewoonList({
    required String startGan,
    required String startJi,
    required bool isSunHaeng,
    int count = 10,
  }) {
    int ganIndex = SajuConstants.ganListHanja.indexOf(startGan);
    int jiIndex = SajuConstants.jiListHanja.indexOf(startJi);

    // 한글 인덱스 찾기 (한자가 아닌 경우)
    if (ganIndex == -1) ganIndex = SajuConstants.ganList.indexOf(startGan);
    if (jiIndex == -1) jiIndex = SajuConstants.jiList.indexOf(startJi);

    if (ganIndex == -1 || jiIndex == -1) {
      throw ArgumentError('유효하지 않은 간지 입력: $startGan$startJi');
    }

    List<String> result = [];
    for (int i = 1; i <= count; i++) {
      int newGanIndex = (ganIndex + (isSunHaeng ? i : -i)) % 10;
      int newJiIndex = (jiIndex + (isSunHaeng ? i : -i)) % 12;

      if (newGanIndex < 0) newGanIndex += 10;
      if (newJiIndex < 0) newJiIndex += 12;

      result.add('${SajuConstants.ganListHanja[newGanIndex]}${SajuConstants.jiListHanja[newJiIndex]}');
    }

    return result;
  }

  /// 세운 리스트 생성
  static List<String> generateSewoonList({
    required String startGan,
    required String startJi,
    required int firstLuckAge,
    int count = 100,
  }) {
    int ganIndex = SajuConstants.ganListHanja.indexOf(startGan);
    int jiIndex = SajuConstants.jiListHanja.indexOf(startJi);

    if (ganIndex == -1) ganIndex = SajuConstants.ganList.indexOf(startGan);
    if (jiIndex == -1) jiIndex = SajuConstants.jiList.indexOf(startJi);

    if (ganIndex < 0 || jiIndex < 0) {
      throw ArgumentError('유효하지 않은 시작 간지: $startGan$startJi');
    }

    ganIndex = firstLuckAge + ganIndex;
    jiIndex = firstLuckAge + jiIndex;

    List<String> result = [];
    for (int i = 0; i < count; i++) {
      int g = (ganIndex + i) % 10;
      int j = (jiIndex + i) % 12;
      result.add('${SajuConstants.ganListHanja[g]}${SajuConstants.jiListHanja[j]}');
    }

    return result;
  }
}


