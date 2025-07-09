class Fortune {
  final String fromGua;       //괘의 시작 지점. 예: 乾 (건괘: 하늘을 뜻함)
  final String toGua;         //괘의 변화 방향. 예: 泰 (태괘: 태평하고 순조로운 상태)
  final String guaName;       //전체 괘 이름. "乾之泰"는 “건에서 태로 변화하는 괘”라는 뜻
  final String poem;          //괘에 대한 고대 한시 형식의 요약. 해석의 핵심 메시지를 운율로 표현
  final List<String> theme;     //이 괘가 주로 다루는 주제들: "운세", "금전", "성장"
  final String interpretation;      //주제별 해석 (여기서는 "운세" 항목만 있음)
  final String? element; // 🔹 오행 (optional)    	이 괘가 상징하는 오행 중 하나. "금"은 금(金)의 기운을 뜻함

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
      fromGua: json['from_gua'],
      toGua: json['to_gua'],
      guaName: json['gua_name'],
      poem: json['poem'],
      theme: List<String>.from(json['theme']),
      interpretation: json['interpretation']['운세'] ?? '',
      element: json['element'], // 🔹 JSON에서 불러옴
    );
  }
}