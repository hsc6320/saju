import '../constants/saju_constants.dart';

/// 십성(十星) 계산 서비스
class SipsinCalculator {
  SipsinCalculator._();

  /// 일간과 대상 천간의 십성 관계 계산
  static String getSipsin(String ilGan, String targetGan) {
    ilGan = ilGan.trim();
    targetGan = targetGan.trim();

    final ilElement = SajuConstants.ganToElement[ilGan];
    final targetElement = SajuConstants.ganToElement[targetGan];

    if (ilElement == null || targetElement == null) {
      return '미정';
    }

    final sameYinYang = SajuConstants.isYang(ilGan) == SajuConstants.isYang(targetGan);

    // 비견/겁재: 같은 오행
    if (ilElement == targetElement) {
      return sameYinYang ? '비견' : '겁재';
    }

    // 식신/상관: 일간이 생하는 오행
    if (SajuConstants.elementProduces[ilElement] == targetElement) {
      return sameYinYang ? '식신' : '상관';
    }

    // 편인/정인: 일간을 생하는 오행
    if (SajuConstants.elementProduces[targetElement] == ilElement) {
      return sameYinYang ? '편인' : '정인';
    }

    // 편재/정재: 일간이 극하는 오행
    if (SajuConstants.elementOvercomes[ilElement] == targetElement) {
      return sameYinYang ? '편재' : '정재';
    }

    // 편관/정관: 일간을 극하는 오행
    if (SajuConstants.elementOvercomes[targetElement] == ilElement) {
      return sameYinYang ? '편관' : '정관';
    }

    return '미정';
  }

  /// 지장간 포함 십성 계산 (천간 표시)
  static String getSipsinWithGan(String ilGan, String targetGan) {
    final sipsin = getSipsin(ilGan, targetGan);
    return '$sipsin($targetGan)';
  }

  /// 지지의 지장간에서 주요 십성 추출 (마지막 지장간 기준)
  static String getJiSipsin(String ilGan, String ji) {
    final hiddenStems = SajuConstants.jiToHiddenStems[ji];
    if (hiddenStems == null || hiddenStems.isEmpty) {
      return '없음';
    }
    return getSipsin(ilGan, hiddenStems.last);
  }

  /// 지장간 모든 십성 계산 (줄바꿈 형식)
  static String getHiddenStemsSipsin(String ilGan, String ji) {
    final hiddenStems = SajuConstants.jiToHiddenStems[ji] ?? [];
    return hiddenStems.map((stem) => getSipsinWithGan(ilGan, stem)).join('\n');
  }

  /// 오행 및 음양 정보 반환
  static Map<String, String> getElementAndYinyang(String gan) {
    final element = SajuConstants.ganToElement[gan];
    final yinyang = SajuConstants.isYang(gan) ? '양' : '음';

    // 한글 오행명으로 변환
    const elementKorean = {
      '木': '목', '火': '화', '土': '토', '金': '금', '水': '수',
    };

    return {
      '오행': elementKorean[element] ?? '알 수 없음',
      '음양': yinyang,
    };
  }
}


