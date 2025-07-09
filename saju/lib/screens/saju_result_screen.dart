import 'package:flutter/material.dart';
import 'package:saju/SharedPreferences.dart';
import 'package:saju/saju/CalculatorGanji.dart';
import 'package:saju/saju/Sipsin.dart';
import 'package:saju/saju/bigSolarTerm.dart';
import 'package:saju/saju/saju_grid.dart';
import 'package:saju/screens/home_screen.dart';

class SajuResultScreen extends StatefulWidget {
  final DateTime selectedTime;
  final List<Map<String, dynamic>> inputOption;
  final bool isSelectMode;
  final SajuInfo saju;
  const SajuResultScreen({super.key, required this.selectedTime, required this.inputOption, this.isSelectMode = false, required this.saju});
  @override
  State<SajuResultScreen> createState() => _SajuResultScreenState();
}

class _SajuResultScreenState extends State<SajuResultScreen> {

   String result = '간지 정보 없음';
   String? yearJi = '';
   String? wolJu = '';
   String ilJu = '';
   String siJuMap = '';
   String KoreanAge = '';
  late DateTime RealBirthTime;
   
  @override
  void initState() {
    super.initState();
    
  }


  Future<Map<String, String?>> loadSajuData() async {
    DateTime lunarDate;
    final today = DateTime.now(); // 오늘 날짜 자동
    int koreanAge = today.year - widget.selectedTime.year + 1;
    
    if (!widget.isSelectMode) {
      await Future.delayed(Duration(seconds: 2)); // 2초 동안 로딩 표시
    }
    print("selected Time : ${widget.selectedTime}, inputOption : ${widget.inputOption.first['solar_date']}");

    if(widget.inputOption.first['solar_date'] == 'true') {    //음력 선택시
      print("음력이 선택되었습니다.");
      lunarDate = (await getSolarDateFromLunar(widget.selectedTime))!;

      yearJi = await getYearGanjiFromJson(lunarDate);   //년주 구하기
      wolJu = await getWolJuFromDate(lunarDate);      //월주 구하기
      int retry = 0;
      while (ilJu.isEmpty && retry < 5) {
        ilJu = await getIlJu(lunarDate);          //일주 구하기
        await Future.delayed(Duration(milliseconds: 100));
        retry++;
      }
      siJuMap = getSiJu(lunarDate, ilJu); // 시주 구하기 , ilJu는 반드시 한글 간지 ('정미' 형식)
      print("년주 : $yearJi, 월주: $wolJu 일주 : $ilJu, 시주 : $siJuMap"); // 👉 '임신' 출력 예상
      
      RealBirthTime = lunarDate;
      return {
        "년주": yearJi,
        "월주": wolJu,
        "일주": ilJu,
        "시주": siJuMap,
      };
    }
    else {    //양력 선택시
      RealBirthTime = widget.selectedTime;
      yearJi = await getYearGanjiFromJson(RealBirthTime);
      wolJu = await getWolJuFromDate(RealBirthTime);
      int retry = 0;
      while (ilJu.isEmpty && retry < 5) {
        ilJu = await getIlJu(RealBirthTime);
        await Future.delayed(Duration(milliseconds: 100));
        retry++;
      }
      siJuMap = getSiJu(RealBirthTime, ilJu); // ilJu는 반드시 한글 간지 ('정미' 형식)
      print("년주 : $yearJi, 월주: $wolJu 일주 : $ilJu, 시주 : $siJuMap,. 나이 $koreanAge"); // 👉 '임신' 출력 예상
      
      return {
        "년주": yearJi,
        "월주": wolJu,
        "일주": ilJu,
        "시주": siJuMap,
        "나이": koreanAge.toString(),
      };
    }
  }
  
  String getCurrentDaewoon(int koreanAge, int firstLuckAge, List<String> daewoonList) {
    if (koreanAge < firstLuckAge) return '대운 없음';

    final index = ((koreanAge - firstLuckAge) ~/ 10);
    if (index >= 0 && index < daewoonList.length) {
      return daewoonList[index];
    } else {
      return '대운 없음';
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<Map<String, String?>>(
      future: loadSajuData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('에러 발생: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('데이터가 없습니다.')),
          );
        }

        final data = snapshot.data!;
        final ilJu = data["일주"]!.trim();
        final wolJu = data["월주"]!;
        final yearJi = data["년주"]!;
        final siju = data["시주"]!;
        final koreanAge = data["나이"]!;
        KoreanAge = koreanAge;
        int firstLuckAge = calculateFirstLuckAge(RealBirthTime, isSunHaeng(yearJi.substring(0,1), widget.inputOption.first['gender']));
        print("firstLuckAge : $firstLuckAge");
        List<String> saewoonList = generateSewoonList(
          startGan: yearJi.substring(0,1),
          startJi: yearJi.substring(1),
        //  isSunHaeng: isSunHaeng(yearJi.substring(0,1), widget.inputOption.first['gender']),
          firstLuckAge : firstLuckAge,
          count: 100,
        );

        List<String> daewoonList = generateDaewoonList(
          startGan: wolJu.substring(0,1),
          startJi: wolJu.substring(1),
          isSunHaeng: isSunHaeng(yearJi.substring(0,1), widget.inputOption.first['gender']),
        );

        final List<SaeWoon> sampleSaewoon = List.generate(saewoonList.length, (index) {
          final ganji = saewoonList[index];

          return SaeWoon(ganji: ganji);
        });

        for (int i = 0; i < daewoonList.length; i++) {
          int age = firstLuckAge + i * 10;
          print('$age세 : ${daewoonList[i]}');
        }
        final DateTime birthDate = RealBirthTime;        // 사용자가 선택한 출생일

        final String currentDaewoon = getCurrentDaewoon(int.parse(KoreanAge), firstLuckAge, daewoonList);
        print('현재 대운은 $currentDaewoon');

           // 👉 간지 정보 팝업 후 이전 화면으로 복귀
        if (widget.isSelectMode) {
          print("saju Result Screen 나이 : $koreanAge, isSelectMode [${widget.isSelectMode}]");
          print("년주 : $yearJi, 월주 $wolJu, 대운 : $daewoonList");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context, {
            /*  "년주": yearJi,
              "월주": wolJu,
              "일주": ilJu,
              "시주": siju,*/
              "saju": widget.saju,
              "daewoon" : List<String>.from(daewoonList),
              "currentDaewoon" : currentDaewoon,
              "age": koreanAge,
              "ganji": {
                "년주": yearJi,
                "월주": wolJu,
                "일주": ilJu,
                "시주": siju,
              }
            });
          });
        }

        final List<Daewoon> sampleDaewoon = List.generate(daewoonList.length, (index) {
            final ganji = daewoonList[index];
            final gan = ganji.substring(0, 1);
            final element = fiveElementMap[gan] ?? '기타';
            final age = firstLuckAge + index * 10;
            
            final tengod = getSipSin(ilJu.substring(0,1), daewoonList[index].substring(0,1));
            final tengod2 = getJiSipSinOnly(ilJu.substring(0,1), daewoonList[index].substring(1));
            //print("sampleDaewoon () age : $age");
            return Daewoon(age: age, ganji: ganji, element: element, tenGod: tengod, tenGod2: tengod2/*, year: widget.selectedTime*/);
        });

        final samplePillars = [
          SajuPillar(title: "시주", 
                    gan: siju.substring(0,1), ji: siju.substring(1), 
                    tenRelation: getSipSin(ilJu.substring(0,1), siju.substring(0,1)), 
                    hiddenSipSins: getJiSipSinOnly(ilJu.substring(0,1), siju.substring(1)), 
                    hiddenStems: showHiddenStems(ilJu.substring(0,1),siju.substring(1)), 
                    elementGan: fiveElementMap[siju.substring(0,1)] ?? '', elementJi: jiToElement[siju.substring(1)] ?? ''),

          SajuPillar(title: "일주", 
                    gan: ilJu.substring(0,1), ji: ilJu.substring(1), 
                    tenRelation: "일간",  
                    hiddenSipSins: getJiSipSinOnly(ilJu.substring(0,1),ilJu.substring(1)), 
                    hiddenStems: showHiddenStems(ilJu.substring(0,1),ilJu.substring(1)), 
                    elementGan: fiveElementMap[ilJu.substring(0,1)] ?? '', elementJi: jiToElement[ilJu.substring(1)] ?? ''),

          SajuPillar(title: "월주", 
                    gan: wolJu.substring(0,1), ji: wolJu.substring(1), 
                    tenRelation: getSipSin(ilJu.substring(0,1), wolJu.substring(0,1)),  
                    hiddenSipSins: getJiSipSinOnly(ilJu.substring(0,1),wolJu.substring(1)),
                    hiddenStems: showHiddenStems(ilJu.substring(0,1), wolJu.substring(1)), 
                    elementGan: fiveElementMap[wolJu.substring(0,1)] ?? '', elementJi: jiToElement[wolJu.substring(1)] ?? ''),

          SajuPillar(title: "년주",
                    gan: yearJi.substring(0,1), ji: yearJi.substring(1), 
                    tenRelation: getSipSin(ilJu.substring(0,1), yearJi.substring(0,1)),  
                    hiddenSipSins: getJiSipSinOnly(ilJu.substring(0,1),yearJi.substring(1)),
                    hiddenStems: showHiddenStems(ilJu.substring(0,1), yearJi.substring(1)), 
                    elementGan: fiveElementMap[yearJi.substring(0,1)] ?? '', elementJi: jiToElement[yearJi.substring(1)] ?? ''),
        ];
       

      // 👉 조건 분기
        if (widget.isSelectMode) {
          // ✅ 사주 선택용 간단한 요약 UI
          return Scaffold(
            appBar: AppBar(title: const Text("사주 선택")),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("년주주주: $yearJi, 월주주주: $wolJu\n일주: $ilJu, 시주: $siju"),
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()), // 혹시 딜레이가 있다면
                ],
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
            
            return Scaffold(
              appBar: //AppBar(title: const Text("사주 결과")),
                AppBar(
            //      backgroundColor: const Color(0xFFFAF3EA),
                  elevation: 0,
                  centerTitle: true,
                  title: const Text(
                    "사주 결과 ",
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.normal),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
                    //onPressed: () => Navigator.pop(context),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              body: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding (
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("성별 : ${widget.inputOption.first['gender']}\n이름 : ${widget.inputOption.first['name']}", style: const TextStyle(fontWeight: FontWeight.normal)),
                        Text("나이 : $KoreanAge", style: const TextStyle(fontWeight: FontWeight.normal)),
                        Text("생년월일(양력)   : ${RealBirthTime.year}.${RealBirthTime.month}.${RealBirthTime.day}\n태어난 시간 :${RealBirthTime.hour}시 ${RealBirthTime.minute}분",style: const TextStyle(fontWeight: FontWeight.normal)),
                        const SizedBox(height: 10),
                        SajuGrid(pillars: samplePillars),
                        const SizedBox(height: 16),
                        DaewoonView(daewoonList: sampleDaewoon, saewoonList: sampleSaewoon, birthDate: birthDate, firstLuckAge: firstLuckAge, gender: widget.inputOption.first['gender'], yearGan: yearJi ),
                      //  Text(widget.inputOption.first['gender'] +" / " +widget.inputOption.first['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}