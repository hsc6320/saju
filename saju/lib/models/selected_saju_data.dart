import 'saju_info.dart';

/// 선택된 사주의 전체 데이터를 담는 클래스
class SelectedSajuData {
  final SajuInfo? saju;
  final Map<String, String?> ganji;
  final List<String> daewoon;
  final String koreanAge;
  final String currentDaewoon;
  final SipseongInfo sipseong;
  final int firstLuckAge; // 초대운 나이

  SelectedSajuData({
    this.saju,
    this.ganji = const {},
    this.daewoon = const [],
    this.koreanAge = '',
    this.currentDaewoon = '',
    SipseongInfo? sipseong,
    this.firstLuckAge = 0,
  }) : sipseong = sipseong ?? SipseongInfo();

  bool get isValid => saju != null && saju!.isValid;

  /// 빈 데이터 생성
  factory SelectedSajuData.empty() => SelectedSajuData();

  /// 복사 메서드
  SelectedSajuData copyWith({
    SajuInfo? saju,
    Map<String, String?>? ganji,
    List<String>? daewoon,
    String? koreanAge,
    String? currentDaewoon,
    SipseongInfo? sipseong,
    int? firstLuckAge,
  }) {
    return SelectedSajuData(
      saju: saju ?? this.saju,
      ganji: ganji ?? this.ganji,
      daewoon: daewoon ?? this.daewoon,
      koreanAge: koreanAge ?? this.koreanAge,
      currentDaewoon: currentDaewoon ?? this.currentDaewoon,
      sipseong: sipseong ?? this.sipseong,
      firstLuckAge: firstLuckAge ?? this.firstLuckAge,
    );
  }
}

/// 십성 정보를 담는 클래스
class SipseongInfo {
  final String yinYang;
  final String fiveElement;
  final String yearGan;
  final String yearJi;
  final String wolGan;
  final String wolJi;
  final String ilGan;
  final String ilJi;
  final String siGan;
  final String siJi;
  final String currDaewoonGan;
  final String currDaewoonJi;

  SipseongInfo({
    this.yinYang = '',
    this.fiveElement = '',
    this.yearGan = '',
    this.yearJi = '',
    this.wolGan = '',
    this.wolJi = '',
    this.ilGan = '',
    this.ilJi = '',
    this.siGan = '',
    this.siJi = '',
    this.currDaewoonGan = '',
    this.currDaewoonJi = '',
  });

  /// Map에서 생성
  factory SipseongInfo.fromMap(Map<String, String>? map) {
    if (map == null) return SipseongInfo();
    return SipseongInfo(
      yinYang: map['sipseong_yinyang'] ?? '',
      fiveElement: map['sipseong_fiveElement'] ?? '',
      yearGan: map['sipseong_year_gan'] ?? '',
      yearJi: map['sipseong_year_ji'] ?? '',
      wolGan: map['sipseong_wol_gan'] ?? '',
      wolJi: map['sipseong_wol_ji'] ?? '',
      ilGan: map['sipseong_il_gan'] ?? '',
      ilJi: map['sipseong_il_ji'] ?? '',
      siGan: map['sipseong_si_gan'] ?? '',
      siJi: map['sipseong_si_ji'] ?? '',
      currDaewoonGan: map['sipseong_curr_daewoon_gan'] ?? '',
      currDaewoonJi: map['sipseong_curr_daewoon_ji'] ?? '',
    );
  }

  /// Map으로 변환
  Map<String, String> toMap() => {
        'sipseong_yinyang': yinYang,
        'sipseong_fiveElement': fiveElement,
        'sipseong_year_gan': yearGan,
        'sipseong_year_ji': yearJi,
        'sipseong_wol_gan': wolGan,
        'sipseong_wol_ji': wolJi,
        'sipseong_il_gan': ilGan,
        'sipseong_il_ji': ilJi,
        'sipseong_si_gan': siGan,
        'sipseong_si_ji': siJi,
        'sipseong_curr_daewoon_gan': currDaewoonGan,
        'sipseong_curr_daewoon_ji': currDaewoonJi,
      };
}


