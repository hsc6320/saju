const Map<String, String> fiveElementMap = {
  '甲': '木', '乙': '木',
  '丙': '火', '丁': '火',
  '戊': '土', '己': '土',
  '庚': '金', '辛': '金',
  '壬': '水', '癸': '水',
};

const Map<String, String> jiToElement = {
  '子': '水',
  '丑': '土',
  '寅': '木',
  '卯': '木',
  '辰': '土',
  '巳': '火',
  '午': '火',
  '未': '土',
  '申': '金',
  '酉': '金',
  '戌': '土',
  '亥': '水',
};


const Map<String, List<String>> jiToHiddenStems = {
  '子': ['壬', '癸'],
  '丑': ['癸', '辛', '己'],
  '寅': ['戊', '丙', '甲'],
  '卯': ['甲', '乙'],
  '辰': ['乙', '癸', '戊'],
  '巳': ['戊', '庚', '丙'],
  '午': ['丙', '己', '丁'],
  '未': ['丁', '乙', '己' ],
  '申': ['戊', '壬', '庚'],
  '酉': ['庚'],
  '戌': ['辛', '丁', '戊'],
  '亥': ['戊', '甲', '壬'],
};

String showHiddenStems (String ilGan, String ji) {
  final hiddenStems = jiToHiddenStems[ji] ?? [];
  
  //for(var key in jiToHiddenStems.entries) {
    //test = getSipSin_Jangan(ilGan, key.key);
  //}

//  return "    $hiddenStems\n${hiddenStems.map((stem) => getSipSin(ilGan, stem)).toList()}";
    return "${hiddenStems.map((e) => getSipSin_Jangan(ilGan, e)).join('\n')}";
}

/// 일간 + 지지 입력 → 지장간 십신만 리스트로 반환
String getJiSipSinOnly(String ilGan, String ji) {
  final hiddenStems = jiToHiddenStems[ji] ?? [];
  
  if (hiddenStems.isNotEmpty) {
    final lastStem = hiddenStems.last;
    return getSipSin(ilGan, lastStem);
  } 
  return '없음';
}

String getSipSin_Jangan(String ilGan, String targetGan) {
   bool isYang(String gan) {
    return ['甲', '丙', '戊', '庚', '壬'].contains(gan);
  }

  final ilElement = fiveElementMap[ilGan]!;
  final targetElement = fiveElementMap[targetGan]!;
  final sameYang = isYang(ilGan);
  final sameYang2 = isYang(targetGan);

  final Map<String, String> elementProduces = {
    '木': '火',
    '火': '土',
    '土': '金',
    '金': '水',
    '水': '木',
  };

  final Map<String, String> elementOvercomes = {
    '木': '土',
    '火': '金',
    '土': '水',
    '金': '木',
    '水': '火',
  };

  if (ilElement == targetElement) {
    return sameYang==sameYang2 ? '비견($targetGan)' : '겁재($targetGan)';
  }

  if (elementProduces[ilElement] == targetElement) {
    return sameYang==sameYang2 ? '식신($targetGan)' : '상관($targetGan)';
  }

  if (elementProduces[targetElement] == ilElement) {
    return sameYang==sameYang2 ? '편인($targetGan)' : '정인($targetGan)';
  }

  if (elementOvercomes[ilElement] == targetElement) {
    return sameYang==sameYang2 ? '편재($targetGan)' : '정재($targetGan)';
  }

  if (elementOvercomes[targetElement] == ilElement) {
    return sameYang==sameYang2 ? '편관($targetGan)' : '정관($targetGan)';
  }

  return '미정';

}

String getSipSin(String ilGan, String targetGan) {

  bool isYang(String gan) {
    return ['甲', '丙', '戊', '庚', '壬'].contains(gan);
  }
  ilGan = ilGan.trim();
  targetGan = targetGan.trim();
  final ilElement = fiveElementMap[ilGan];
  final targetElement = fiveElementMap[targetGan];
  final sameYang = isYang(ilGan);
  final sameYang2 = isYang(targetGan);

  final Map<String, String> elementProduces = {
    '木': '火',
    '火': '土',
    '土': '金',
    '金': '水',
    '水': '木',
  };

  final Map<String, String> elementOvercomes = {
    '木': '土',
    '火': '金',
    '土': '水',
    '金': '木',
    '水': '火',
  };
  
  if (ilElement == targetElement) {
    return sameYang==sameYang2 ? '비견' : '겁재';
  }

  if (elementProduces[ilElement] == targetElement) {
    return sameYang==sameYang2 ? '식신' : '상관';
  }

  if (elementProduces[targetElement] == ilElement) {
    return sameYang==sameYang2 ? '편인' : '정인';
  }

  if (elementOvercomes[ilElement] == targetElement) {
    return sameYang==sameYang2 ? '편재' : '정재';
  }

  if (elementOvercomes[targetElement] == ilElement) {
    return sameYang==sameYang2 ? '편관' : '정관';
  }

  return '미정';
}
