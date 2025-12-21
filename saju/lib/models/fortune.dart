import 'saju_info.dart';

/// 점괘 모델
class Fortune {
  final String fromGua;       // 본괘
  final String toGua;         // 변괘
  final String guaName;       // 괘 이름
  final String poem;          // 시(詩)
  final List<String> theme;   // 주제
  final String interpretation; // 해석
  final String? element;      // 오행

  Fortune({
    required this.fromGua,
    required this.toGua,
    required this.guaName,
    required this.poem,
    required this.theme,
    required this.interpretation,
    this.element,
  });

  factory Fortune.fromJson(Map<String, dynamic> json) {
    return Fortune(
      fromGua: json['from_gua'] ?? '',
      toGua: json['to_gua'] ?? '',
      guaName: json['gua_name'] ?? '',
      poem: json['poem'] ?? '',
      theme: List<String>.from(json['theme'] ?? []),
      interpretation: json['interpretation']?['운세'] ?? '',
      element: json['element'],
    );
  }

  Map<String, dynamic> toJson() => {
        'from_gua': fromGua,
        'to_gua': toGua,
        'gua_name': guaName,
        'poem': poem,
        'theme': theme,
        'interpretation': {'운세': interpretation},
        'element': element,
      };
}

/// GPT 메시지 빌더
List<Map<String, String>> buildFortuneMessages({
  required SajuInfo saju,
  required String? currentDaewoon,
  required Map<String, String?> sajuganji,
  required List<String> daewoon,
  required String question,
}) {
  return [
    {
      'role': 'system',
      'content': '''
너는 초씨역림과 사주명리학에 모두 정통한 점술가야.
질문자 이름: ${saju.name},  
간지 정보: $sajuganji,  
대운: $daewoon, 현재 대운: $currentDaewoon

사용자의 질문을 보고 먼저 아래 기준에 따라 판단해줘:
- 질문이 "올해 사주", "25년 운세", "내년 이직운"처럼 **시기 기반**이거나 **운세 중심**일 경우  
  → 간지 정보와 대운을 활용한 **사주 해석**으로 대답해줘.

- 질문이 "지금 매수 어때?", "이번 달 풀릴까?", "이직할까?"처럼 **선택/판단**을 요구하면  
  → 스스로 본괘와 변괘, 괘 번호를 정해서 **초씨역림 점괘로 해석**해줘.
---
응답 형식은 질문 유형에 따라 다음 중 하나로 맞춰줘:
[사주 해석]
- 사주 구조 요약
- 대운 흐름 설명
- 해석: 질문에 대한 사주 기반 해석
- 조언: 핵심 행동 요약

[점괘]
- 본괘: 괘이름 - "간단 해석"
- 변괘: 괘이름 - "간단 해석"
- 괘 번호: X호 변화
[풀이]
- 해석: 점괘를 종합해 질문에 대한 해석
- 포인트: 핵심 요약이나 행동 조언
---
말투는 딱딱하지 않게, 친구처럼 부드럽고 자연스럽게. 상황에 따라서는 사주나 점보다는 위로나 칭찬을 해줘
너무 점잖거나 어려운 표현은 쓰지 말고, 마치 친한 사람이 진심 어린 조언을 건네듯 편하게 말해줘.
''',
    },
    {
      'role': 'user',
      'content': question,
    }
  ];
}
