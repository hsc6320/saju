import 'package:flutter/material.dart';

const Map<String, Color> elementColors = {
  '木': Colors.green,
  '火': Colors.red,
  '土': Colors.brown,
  '金': Colors.grey,
  '水': Colors.blue,
};

const Map<String, String> fiveElement_Map = {
  '甲': '木', '乙': '木',
  '丙': '火', '丁': '火',
  '戊': '土', '己': '土',
  '庚': '金', '辛': '金',
  '壬': '水', '癸': '水',
};


const Map<String, String> jiElement = {
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


const List<Map<String, dynamic>> solarTerms = [
  {"name": "입춘", "month": 2, "day": 4},
  {"name": "경칩", "month": 3, "day": 5},
  {"name": "청명", "month": 4, "day": 5},
  {"name": "입하", "month": 5, "day": 5},
  {"name": "망종", "month": 6, "day": 6},
  {"name": "소서", "month": 7, "day": 7},
  {"name": "입추", "month": 8, "day": 8},
  {"name": "백로", "month": 9, "day": 8},
  {"name": "한로", "month": 10, "day": 8},
  {"name": "입동", "month": 11, "day": 8},
  {"name": "대설", "month": 12, "day": 7},
  {"name": "소한", "month": 1, "day": 5},
];


Color elementColor(String element) {
  switch (element) {
    case '木':
      return const Color(0xFF4CAF50); // sage green
    case '火':
      return const Color(0xFFF06292); // coral pink
    case '土':
      return const Color(0xFFFFD54F); // warm amber
    case '金':
      return const Color(0xFFB0BEC5); // silver gray
    case '水':
      return const Color(0xFF64B5F6); // cool blue
    default:
      return Colors.grey;
  }
}

// 예시 로직 (남자 양력 기준, 일반적으로 사용)
bool isSunHaeng(String yearGan, String gender) {
  final yangGans = ['甲', '丙', '戊', '庚', '壬']; // 양간
  final eumYang = yangGans.contains(yearGan) ? '양' : '음';

  if ((eumYang == '양' && gender == '남자') || (eumYang == '음' && gender == '여자')) {
    return true; // 순행
  } else {
    return false; // 역행
  }
}

DateTime getNearestSolarTerm(DateTime birthDate, bool isSunHaeng) {
  DateTime? nearest;
  int minDiff = 9999;
  print("birthDate : $birthDate");

  for (var term in solarTerms) {
    // 출생연도의 절기일
    DateTime termDate = DateTime(
      birthDate.month == 1 && term['month'] == 12
          ? birthDate.year - 1
          : birthDate.year,
      term['month'],
      term['day'],
    );
    //print("절기일 : $termDate,birthDate : $birthDate");
    
    int diff = birthDate.difference(termDate).inDays;
    if (isSunHaeng) {
      // 🔺 순행: 미래 절기 중 가장 가까운 것 (diff < 0)
      int futureDiff = termDate.difference(birthDate).inDays;
      if (futureDiff >= 0 && futureDiff < minDiff) {
        minDiff = futureDiff;
        nearest = termDate;
      }
    } else {
      // 🔻 역행: 과거 절기 중 가장 가까운 것 (diff >= 0)
      if (diff >= 0 && diff < minDiff) {
        minDiff = diff;
        nearest = termDate;
      }
    }
  }
  if (nearest == null) {
    print("birthDate : $birthDate");
    throw Exception("getNearestSolarTerm: 조건에 맞는 절기를 찾지 못했습니다.");
  }
  return nearest;
}


int calculateFirstLuckAge(DateTime birthDate, bool isSunHaeng) {
  
  DateTime nearestTerm = getNearestSolarTerm(birthDate, isSunHaeng);
  int days = nearestTerm.difference(birthDate).inDays;
  print("nearestTerm : $nearestTerm, birthDate : $birthDate, isSunHaeng : $isSunHaeng, days : $days");
  return (days.abs() / 3).floor();
}

const List<String> tenStems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> twelveBranches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

/// 1년 단위로 간지 리스트를 생성하는 함수
List<String> generateSewoonList({
  required String startGan,
  required String startJi,
  required int firstLuckAge,
  int count = 10, // 기본 10년치
}) {
  int ganIdx = tenStems.indexOf(startGan);
  int jiIdx  = twelveBranches.indexOf(startJi);

  ganIdx = firstLuckAge + ganIdx;
  jiIdx = firstLuckAge + jiIdx;

  if (ganIdx < 0 || jiIdx < 0) {
    throw ArgumentError('유효하지 않은 시작 간지: $startGan$startJi');
  }

  List<String> result = [];
  for (int i = 0; i < count; i++) {
    // i년 후(또는 전) 의 천간/지지 인덱스
    int g = (ganIdx + i) % 10;
    int j = (jiIdx  + i) % 12;

    result.add('${tenStems[g]}${twelveBranches[j]}');
  }
  //print("generateSewoonList result : $result");
  return result;
}

List<String> generateDaewoonList({
  required String startGan,
  required String startJi,
  required bool isSunHaeng,
  int count = 10,
}) {
  int ganIndex = tenStems.indexOf(startGan);
  int jiIndex = twelveBranches.indexOf(startJi);
  
  if (ganIndex == -1 || jiIndex == -1) {
    throw ArgumentError('유효하지 않은 간지 입력');
  }

  List<String> result = [];

  for (int i = 1; i <= count; i++) {
    int newGanIndex = (ganIndex + (isSunHaeng ? i : -i)) % 10;
    int newJiIndex = (jiIndex + (isSunHaeng ? i : -i)) % 12;

  //  if (newGanIndex < 0) newGanIndex += 10;
  //  if (newJiIndex < 0) newJiIndex += 12;

    result.add('${tenStems[newGanIndex]}${twelveBranches[newJiIndex]}');
  }

  return result;
}

class DaewoonChip extends StatelessWidget {
  final Daewoon item;
  final VoidCallback onTap;

  const DaewoonChip({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final baseColor = elementColors[item.element] ?? Colors.black;
    final backgroundColor = item.expanded ? baseColor : baseColor.withOpacity(0.6);
    final textColor = Colors.white;

    final String gan = item.ganji.substring(0, 1);
    final String ji = item.ganji.substring(1);
    final String ganElement = fiveElement_Map[gan] ?? '기타';
    
    final Color ganColor = elementColors[ganElement] ?? Colors.black;
    String ji2 = jiElement[ji]!;
    final Color jiColor = elementColors[ji2] ?? Colors.black;

    return GestureDetector(
      onTap: onTap,
      child : LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width * 0.12;
          final height = width * 1.1;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: width,
            child: Column(
              children: [
                Text(
                  '${item.age}세',
                  style: const TextStyle(fontSize: 12),
                ),
                if (item.tenGod != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      item.tenGod!,
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // 천간 박스
                Container(
                  width: width,
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ganColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Text(
                    gan,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 5),
                // 지지 박스
                Container(
                  width: width,
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: jiColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: Text(
                    ji,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                if (item.tenGod2 != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      item.tenGod2!,
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 1),
              ],
            ),
          );
        },
      ),
    );

/*
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.tenGod != null)
              Text(
                item.tenGod!,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: textColor),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 2),
            Text(
              gan,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ganColor,
              ),
            ),
            Text(
              ji,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: jiColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${item.age}세',
              style: TextStyle(fontSize: 11, color: textColor),
            ),
          ],
        ),
      ),
    );
    */
  }
}

class SewoonChip extends StatelessWidget {
  final int year;
  final String gan;
  final String ji;
  final String element;

  const SewoonChip({
    super.key,
    required this.year,
    required this.gan,
    required this.ji,
    required this.element,
  });

  @override
  Widget build(BuildContext context) {
    final color = elementColor(fiveElement_Map[gan]!).withOpacity(0.2);
    return Container(
      width: 60,
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
       // color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
          //width: 30,
        child : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$year년', style: const TextStyle(fontSize: 10)),
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: elementColor(fiveElement_Map[gan]!),//.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Text(
                gan,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: elementColor(jiElement[ji]!),//.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Text(
                ji,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SaeWoon {
  final String ganji;

  SaeWoon({
    required this.ganji,
  });
}
class Daewoon {
  //final DateTime year;
  final int age;
  final String ganji;
  final String element; // 오행
  final String? tenGod; // 십신
  final String? tenGod2; // 십신
  bool expanded;

  Daewoon({
 //   required this.year,
    required this.age,
    required this.ganji,
    required this.element,
    this.tenGod,
    this.tenGod2,
    this.expanded = false,
  });
  List<int> get years => List.generate(10, (i) => age + i);
}



class DaewoonView extends StatefulWidget {
  final List<Daewoon> daewoonList;
  final List<SaeWoon> saewoonList;
  final String yearGan;
  final String gender;
  final DateTime birthDate;
  final int firstLuckAge;

  const DaewoonView({
    super.key, 
    required this.daewoonList,
    required this.saewoonList,
    required this.yearGan,
    required this.gender,
    required this.birthDate,
    required this.firstLuckAge,
  });

  @override
  State<DaewoonView> createState() => _DaewoonViewState();
}

class _DaewoonViewState extends State<DaewoonView> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder (
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 6 * 4) / 5; // 한 줄에 5개 기준
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const Text("🔮 대운", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.daewoonList.length, (index) {
                  final item = widget.daewoonList[index];
                  return DaewoonChip(
                    item: item,
                    onTap: () {
                      setState(() {
                        expandedIndex = index == expandedIndex ? null : index;
                  //     print("expandedIndex : $expandedIndex");
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 5),
            const Text("🔮 세운", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (expandedIndex != null)
              Wrap(
                spacing: 6,
                runSpacing: 9,
                children: () {
                  //final daewoon = widget.daewoonList[expandedIndex!];
                  // 1) 해당 대운이 시작되는 연도
                  final startYear = widget.birthDate.year + widget.firstLuckAge + expandedIndex! * 10;
                
                  // 3) 칩 위젯으로 변환
                  return List.generate(10, (i) {
                    final year = startYear + i;
                    //final gj = sewoonGanji[i];
                    final ji = widget.saewoonList[i+(expandedIndex! * 10)].ganji.substring(1);
                    final gan = widget.saewoonList[i/*+(expandedIndex! * 10)*/].ganji.substring(0,1);
                    
                    final eGan = fiveElement_Map[gan]!;
                  //  print("eGan : $eGan, gan : $gan, ji : $ji, year : $year");
                    return SizedBox(
                      width: itemWidth,
                      child : SewoonChip (
                        element: eGan, 
                        gan: gan, 
                        ji : ji,
                        year: year
                      ),
                    );
                  });
                }(),
              ),
          ],
        );
      },
    );
  }
}
