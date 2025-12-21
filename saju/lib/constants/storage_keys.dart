/// SharedPreferences에서 사용하는 키 상수 정의
class StorageKeys {
  StorageKeys._(); // 인스턴스화 방지

  // 사주 리스트
  static const String sajuList = 'saju_list';

  // 선택된 사주 정보
  static const String selectedSaju = 'selected_saju';
  static const String selectedGanji = 'selected_ganji';
  static const String selectedDaewoon = 'selected_daewoon';
  static const String selectedAge = 'selected_age';
  static const String selectedCurrentDaewoon = 'selected_current_daewoon';
  static const String selectedFirstLuckAge = 'selected_first_luck_age';

  // 십성 정보
  static const String sipseongYinyang = 'sipseong_yinyang';
  static const String sipseongFiveElement = 'sipseong_fiveElement';
  static const String sipseongYearGan = 'sipseong_year_gan';
  static const String sipseongYearJi = 'sipseong_year_ji';
  static const String sipseongWolGan = 'sipseong_wol_gan';
  static const String sipseongWolJi = 'sipseong_wol_ji';
  static const String sipseongIlGan = 'sipseong_il_gan';
  static const String sipseongIlJi = 'sipseong_il_ji';
  static const String sipseongSiGan = 'sipseong_si_gan';
  static const String sipseongSiJi = 'sipseong_si_ji';
  static const String sipseongCurrDaewoonGan = 'sipseong_curr_daewoon_gan';
  static const String sipseongCurrDaewoonJi = 'sipseong_curr_daewoon_ji';

  // 사용자 데이터 (레거시)
  static const String username = 'username';
  static const String gender = 'gender';
  static const String lunar = 'lunar';
  static const String selectedDate = 'selected_date';
  static const String selectedTime = 'selected_time';

  /// 모든 선택된 사주 관련 키 목록
  static List<String> get allSelectedSajuKeys => [
    selectedSaju,
    selectedGanji,
    selectedDaewoon,
    selectedAge,
    selectedCurrentDaewoon,
    selectedFirstLuckAge,
    sipseongYinyang,
    sipseongFiveElement,
    sipseongYearGan,
    sipseongYearJi,
    sipseongWolGan,
    sipseongWolJi,
    sipseongIlGan,
    sipseongIlJi,
    sipseongSiGan,
    sipseongSiJi,
    sipseongCurrDaewoonGan,
    sipseongCurrDaewoonJi,
  ];
}


