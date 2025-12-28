/// 개인맞춤입력 정보 모델
class PersonalInfo {
  // A. 필수
  String? jobStatus; // 직업 상태
  String? jobName; // 직업명 (직접 입력)
  String? maritalStatus; // 혼인 상태
  List<String> concerns; // 현재 고민 영역 (다중 선택)

  // B. 권장
  String? lifeStage; // 현재 삶의 단계
  String? moneyActivity; // 재물 활동
  String? relationshipStatus; // 연애 상태

  // C. 보조(선택)
  List<String> hobbies; // 취미 성향 (다중 선택)
  String? hobbyOther; // 기타 취미 (직접 입력)
  String? planningStyle; // 계획형/즉흥형
  String? stabilityPreference; // 안정추구/변화추구
  String? personalityType; // 내향/외향

  // D. 민감(제한 입력)
  bool hasHealthConcern; // 건강 이슈 존재 여부

  // E. 기타사항(선택)
  String? note; // 기타 메모 (최대 500자)

  PersonalInfo({
    this.jobStatus,
    this.jobName,
    this.maritalStatus,
    List<String>? concerns,
    this.lifeStage,
    this.moneyActivity,
    this.relationshipStatus,
    List<String>? hobbies,
    this.hobbyOther,
    this.planningStyle,
    this.stabilityPreference,
    this.personalityType,
    this.hasHealthConcern = false,
    this.note,
  })  : concerns = concerns ?? [],
        hobbies = hobbies ?? [];

  /// 빈 PersonalInfo 생성
  factory PersonalInfo.empty() {
    return PersonalInfo();
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'jobStatus': jobStatus,
      'jobName': jobName,
      'maritalStatus': maritalStatus,
      'concerns': concerns,
      'lifeStage': lifeStage,
      'moneyActivity': moneyActivity,
      'relationshipStatus': relationshipStatus,
      'hobbies': hobbies,
      'hobbyOther': hobbyOther,
      'planningStyle': planningStyle,
      'stabilityPreference': stabilityPreference,
      'personalityType': personalityType,
      'hasHealthConcern': hasHealthConcern,
      'note': note,
    };
  }

  /// JSON에서 생성
  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      jobStatus: json['jobStatus'] as String?,
      jobName: json['jobName'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      concerns: json['concerns'] != null
          ? List<String>.from(json['concerns'] as List)
          : [],
      lifeStage: json['lifeStage'] as String?,
      moneyActivity: json['moneyActivity'] as String?,
      relationshipStatus: json['relationshipStatus'] as String?,
      hobbies: json['hobbies'] != null
          ? List<String>.from(json['hobbies'] as List)
          : [],
      hobbyOther: json['hobbyOther'] as String?,
      planningStyle: json['planningStyle'] as String?,
      stabilityPreference: json['stabilityPreference'] as String?,
      personalityType: json['personalityType'] as String?,
      hasHealthConcern: json['hasHealthConcern'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  /// 복사 생성
  PersonalInfo copyWith({
    String? jobStatus,
    String? jobName,
    String? maritalStatus,
    List<String>? concerns,
    String? lifeStage,
    String? moneyActivity,
    String? relationshipStatus,
    List<String>? hobbies,
    String? hobbyOther,
    String? planningStyle,
    String? stabilityPreference,
    String? personalityType,
    bool? hasHealthConcern,
    String? note,
  }) {
    return PersonalInfo(
      jobStatus: jobStatus ?? this.jobStatus,
      jobName: jobName ?? this.jobName,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      concerns: concerns ?? this.concerns,
      lifeStage: lifeStage ?? this.lifeStage,
      moneyActivity: moneyActivity ?? this.moneyActivity,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      hobbies: hobbies ?? this.hobbies,
      hobbyOther: hobbyOther ?? this.hobbyOther,
      planningStyle: planningStyle ?? this.planningStyle,
      stabilityPreference: stabilityPreference ?? this.stabilityPreference,
      personalityType: personalityType ?? this.personalityType,
      hasHealthConcern: hasHealthConcern ?? this.hasHealthConcern,
      note: note ?? this.note,
    );
  }

  /// 입력된 항목만 포함하는 Map 반환 (서버 전송용)
  Map<String, dynamic> toServerJson() {
    final Map<String, dynamic> result = {};
    
    if (jobStatus != null && jobStatus!.isNotEmpty) {
      result['jobStatus'] = jobStatus;
    }
    if (jobName != null && jobName!.isNotEmpty) {
      result['jobName'] = jobName;
    }
    if (maritalStatus != null && maritalStatus!.isNotEmpty) {
      result['maritalStatus'] = maritalStatus;
    }
    if (concerns.isNotEmpty) {
      result['concerns'] = concerns;
    }
    if (lifeStage != null && lifeStage!.isNotEmpty) {
      result['lifeStage'] = lifeStage;
    }
    if (moneyActivity != null && moneyActivity!.isNotEmpty) {
      result['moneyActivity'] = moneyActivity;
    }
    if (relationshipStatus != null && relationshipStatus!.isNotEmpty) {
      result['relationshipStatus'] = relationshipStatus;
    }
    if (hobbies.isNotEmpty) {
      result['hobbies'] = hobbies;
    }
    if (hobbyOther != null && hobbyOther!.isNotEmpty) {
      result['hobbyOther'] = hobbyOther;
    }
    if (planningStyle != null && planningStyle!.isNotEmpty) {
      result['planningStyle'] = planningStyle;
    }
    if (stabilityPreference != null && stabilityPreference!.isNotEmpty) {
      result['stabilityPreference'] = stabilityPreference;
    }
    if (personalityType != null && personalityType!.isNotEmpty) {
      result['personalityType'] = personalityType;
    }
    if (hasHealthConcern) {
      result['hasHealthConcern'] = hasHealthConcern;
    }
    if (note != null && note!.isNotEmpty) {
      result['note'] = note;
    }
    
    return result;
  }
}

/// 알림 설정 모델
class NotificationSettings {
  bool enabled; // 알림 활성화 여부
  bool chatNotifications; // 채팅 알림
  bool fortuneNotifications; // 운세 알림

  NotificationSettings({
    this.enabled = true,
    this.chatNotifications = true,
    this.fortuneNotifications = true,
  });

  factory NotificationSettings.empty() {
    return NotificationSettings();
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'chatNotifications': chatNotifications,
      'fortuneNotifications': fortuneNotifications,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      chatNotifications: json['chatNotifications'] as bool? ?? true,
      fortuneNotifications: json['fortuneNotifications'] as bool? ?? true,
    );
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? chatNotifications,
    bool? fortuneNotifications,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      chatNotifications: chatNotifications ?? this.chatNotifications,
      fortuneNotifications: fortuneNotifications ?? this.fortuneNotifications,
    );
  }
}

