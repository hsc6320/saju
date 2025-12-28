import 'package:flutter/material.dart';

/// 사주 정보를 담는 모델 클래스
class SajuInfo {
  final String name;
  final String relation;
  final String birth;
  final String element;
  final String lunar;
  final TimeOfDay? time;
  bool isFavorite;
  final bool isEditing;

  SajuInfo({
    required this.name,
    required this.relation,
    required this.birth,
    required this.element,
    required this.lunar,
    this.time,
    this.isFavorite = false,
    this.isEditing = false,
  });

  /// 유효한 사주 정보인지 확인
  bool get isValid =>
      name.isNotEmpty &&
      relation.isNotEmpty &&
      birth.isNotEmpty &&
      lunar.isNotEmpty;

  /// 생년월일 DateTime 변환
  DateTime get birthDateTime {
    final parts = birth.split('-');
    if (parts.length != 3) {
      return DateTime.now();
    }
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    final hour = time?.hour ?? 0;
    final minute = time?.minute ?? 0;
    return DateTime(year, month, day, hour, minute);
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'birth': birth,
        'element': element,
        'isLunar': lunar,
        'time': time != null ? '${time!.hour}:${time!.minute}' : null,
        'isFavorite': isFavorite,
      };

  /// JSON 역직렬화
  factory SajuInfo.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['time'] != null) {
      final timeParts = (json['time'] as String).split(':');
      time = TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? 0,
        minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
      );
    }
    return SajuInfo(
      name: json['name'] ?? '',
      relation: json['relation'] ?? '',
      birth: json['birth'] ?? '',
      element: json['element'] ?? '',
      lunar: json['isLunar'] ?? 'false',
      time: time,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  /// 빈 SajuInfo 생성
  factory SajuInfo.empty() => SajuInfo(
        name: '',
        relation: '',
        birth: '',
        element: '',
        lunar: 'false',
        time: null,
      );

  /// 복사 메서드
  SajuInfo copyWith({
    String? name,
    String? relation,
    String? birth,
    String? element,
    String? lunar,
    TimeOfDay? time,
    bool? isFavorite,
    bool? isEditing,
  }) {
    return SajuInfo(
      name: name ?? this.name,
      relation: relation ?? this.relation,
      birth: birth ?? this.birth,
      element: element ?? this.element,
      lunar: lunar ?? this.lunar,
      time: time ?? this.time,
      isFavorite: isFavorite ?? this.isFavorite,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SajuInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          birth == other.birth;

  @override
  int get hashCode => name.hashCode ^ birth.hashCode;

  @override
  String toString() => 'SajuInfo(name: $name, birth: $birth, relation: $relation)';
}


