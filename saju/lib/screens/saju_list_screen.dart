import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saju/SajuProvider.dart';
import 'package:saju/SharedPreferences.dart';
import 'package:saju/models/fortune.dart';
import 'package:saju/screens/fortune_screen.dart';
import 'package:saju/screens/home_screen.dart';
import 'package:saju/screens/saju_input_screen.dart';
import 'package:saju/screens/saju_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SajuListScreen extends StatefulWidget {
  final DateTime? selectedTime;
  final List<Map<String, dynamic>>? inputOption;
  const SajuListScreen({super.key, this.selectedTime, this.inputOption});

  @override
  State<SajuListScreen> createState() => _SajuListScreenState();
}

enum SortOption { date, nameAsc, nameDesc }

class _SajuListScreenState extends State<SajuListScreen> {
  String? yearJi = '';
  String? wolJu = '';
  String? ilJu = '';
  String? siju = '';

  SajuInfo? saju;
  String? koreanAge = '';
  String? currentDaewoon = '';
  Map<String, String?> ganji = {};
  List<String> daewoonList = [];

   
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSelectedSaju();
  }
  
  SajuInfo? selectedSaju;

  String searchQuery = "";
  SortOption sortOption = SortOption.date;

  Future<void> _loadSelectedSaju() async {
  final prefs = await SharedPreferences.getInstance();
  final sajuJson = prefs.getString('selected_saju');
  final ganjiJson = prefs.getString('selected_ganji');
  final daewoonJson = prefs.getString('selected_daewoon');
  final koreaAgeJson = prefs.getString('selected_age');
  final current_daewoonJson = prefs.getString('selected_current_daewoon');

  if (sajuJson == null) return;

  final SajuInfo saju = SajuInfo.fromJson(jsonDecode(sajuJson));
  final String koreanAge = koreaAgeJson != null ? jsonDecode(koreaAgeJson) : '';
  final String currentDaewoon = current_daewoonJson != null ? jsonDecode(current_daewoonJson) : '';
  final Map<String, String?> ganji =
      ganjiJson != null ? Map<String, String?>.from(jsonDecode(ganjiJson)) : {};
  final List<String> daewoonList =
      daewoonJson != null ? List<String>.from(jsonDecode(daewoonJson)) : [];

  setState(() {
    selectedSaju = saju;
    this.koreanAge = koreanAge;
    this.currentDaewoon = currentDaewoon;
    this.ganji = ganji;
    this.daewoonList = daewoonList;
  });

  print("✅ SajuListScreen 복구된 사주: ${saju.name}, 나이: $koreanAge, 현재 대운: $currentDaewoon");
}

  void _deleteItem(SajuInfo saju) async {
    final provider = Provider.of<SajuProvider>(context, listen: false);
    provider.remove(saju); // ✅ Provider 내부에서 SharedPreferences까지 삭제
    final prefs = await SharedPreferences.getInstance();
    
      // ✅ 만약 현재 선택된 사주가 삭제된 사주라면 SharedPreferences도 초기화
    if (selectedSaju?.name == saju.name && selectedSaju?.birth == saju.birth) {
      await prefs.remove('selected_saju');
      await prefs.remove('selected_ganji');
      await prefs.remove('selected_daewoon');
      await prefs.remove('selected_age');
      await prefs.remove('selected_current_daewoon');

      setState(() {
        selectedSaju = null;
        ganji = {};
        daewoonList = [];
        koreanAge = '';
        currentDaewoon = '';
      });
    }
      // ✅ 선택된 사주와 삭제 대상이 같으면 선택 해제
    setState(() {
      if (selectedSaju == saju) {
        selectedSaju = null;
      }
    });

    // ✅ 삭제 후 필터링된 리스트도 새로고침 필요
  //  _refreshFilteredList(); // 예: searchQuery 반영된 리스트 재계산 함수
  }


  void _editItem(SajuInfo saju) async {
    //edited 수정한 값 반환
    final edited = await Navigator.push(
      context,
      MaterialPageRoute(
        //builder: (_) => SajuInputScreen(saju : saju),
        builder: (_) => SajuInputScreen(
          saju: saju.copyWith(isEditing: true),
        )
      ),
    );
    if (edited != null && edited is SajuInfo) {
      final sajuProvider = Provider.of<SajuProvider>(context, listen: false);
      sajuProvider.updateItem(saju, edited);
    }
  }

  void _changeSort(SortOption option) {
    setState(() => sortOption = option);
  }
  List<Map<String, dynamic>> generateSolarTermsForSaju(SajuInfo saju, String isLunar ) {
    String lunar = isLunar.toString();
    return [
      {
       "name": saju.name,
       "solar_date": lunar, // true이면 양력
        "gender": saju.relation, // relation을 gender로 사용 중
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sajuProvider = Provider.of<SajuProvider>(context);
    final sajuList = sajuProvider.sajuList;
    if(sajuList.isEmpty) {
       print("❌ 사주 목록이 없습니다.");
    }

    List<SajuInfo> filteredList = sajuList
        .where((item) => item.name.contains(searchQuery))
        .toList();

    if (filteredList.isEmpty) {
      print("🔍 검색 결과 없음 or 사주 없음");
    }

    // 즐겨찾기 우선 정렬 후 일반 정렬 적용
    filteredList.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return b.isFavorite ? 1 : -1; // 즐겨찾기 true가 먼저
      }
      switch (sortOption) {
        case SortOption.date:
          return b.birth.compareTo(a.birth);
        case SortOption.nameAsc:
          return a.name.compareTo(b.name);
        case SortOption.nameDesc:
          return b.name.compareTo(a.name);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("등록된 사주 정보", style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          //onPressed: () => Navigator.pop(context),
          onPressed: () {
            if(sajuList.isEmpty) {
              // 사주 목록이 아예 없을 때 → HomeScreen으로 pop
              Navigator.pop(context, {
                "saju": null,
                "ganji": null,
                "daewoon": null,
              });
              return;
            }
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: Colors.grey),
            onSelected: _changeSort,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.date,
                child: Text("생년월일순"),
              ),
              const PopupMenuItem(
                value: SortOption.nameAsc,
                child: Text("이름 오름차순"),
              ),
              const PopupMenuItem(
                value: SortOption.nameDesc,
                child: Text("이름 내림차순"),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: '이름 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body : Stack(
        children: [
          Column(
            children: [
              if (selectedSaju != null && selectedSaju!.isValid) // ✅ 대표 회표시 영역
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                color: Colors.grey.shade100,
                child : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.yellow.shade100,
                          child: Icon(Icons.person, size: 28, color: Colors.black),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(Icons.check_circle, color: Colors.amber, size: 20),
                        )
                      ],
                    ),
                    const SizedBox(width : 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row (
                          children: [
                            Text(
                              selectedSaju!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                selectedSaju!.element,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedSaju!.birth} (${selectedSaju!.relation})',
                          style: const TextStyle(color: Colors.grey),
                        )
                      ],
                    )
                  ],
                )
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final saju = filteredList[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(
                          saju.relation == '남자' ? Icons.man : Icons.woman,
                          color: saju.isFavorite ? Colors.amber : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (selectedSaju == saju) {
                            // 이미 선택된 항목이면 → 선택 해제
                            print("이미 선택된 항목이면 → 선택 해제");
                            selectedSaju = null;
                          } else {
                            // 새 항목 선택
                            selectedSaju = saju;
                            print("클릭정보 : ${selectedSaju!.name}");
                          }
                        });
                     //   Navigator.pop(context, saju); // ← 선택된 사주 리턴
                      },
                      selected: selectedSaju == saju,
                      selectedTileColor: Colors.grey.shade100,
                      title: Row(
                        children: [
                          Text(saju.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                            //  color: _elementColor(saju.element/*, widget.selectedTime!*/),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              saju.element,
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text("${saju.birth} (${saju.relation})",
                        style: const TextStyle(color: Colors.grey)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          final saju = filteredList[index]; // 🔥 filteredList 기준으로 가져와야 함
                          //final saju = sajuList[index]; // 리스트에서 해당 SajuInfo 추출
                          if (value == 'edit') {
                            _editItem(saju);
                          } else if (value == 'delete') {
                            _deleteItem(saju);
                          } else if (value == 'favorite') {
                            //_toggleFavorite(index);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('수정')),
                          const PopupMenuItem(value: 'delete', child: Text('삭제')),
                          const PopupMenuItem(value: 'favorite', child: Text('즐겨찾기 토글')),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedSaju == null)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        //builder: (_) => SajuInputScreen(saju : saju),
                        builder: (_) => SajuInputScreen(
                      //   saju: saju.copyWith(isEditing: true),
                        )
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("사주 추가", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            if (selectedSaju != null)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8, // 🔹 전체 화면의 60%
                child : ElevatedButton(
                  onPressed: () {
                    print('selectedSaju!.lunar : ${selectedSaju!.lunar}, ${selectedSaju!.lunar}');
                    final inputOption = generateSolarTermsForSaju(selectedSaju!, selectedSaju!.lunar);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SajuResultScreen(inputOption: inputOption, selectedTime: selectedSaju!.birthDateTime, saju: selectedSaju!,),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("사주 조회", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            //const SizedBox(height: 12),
            const SizedBox(height: 8),
            if (selectedSaju != null)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () async {
                    final inputOption = generateSolarTermsForSaju(selectedSaju!, selectedSaju!.lunar);
                    
                     // 년주, 월주, 일주, 시주 정보 가져오기
                    final result = await Navigator.push (
                      context,
                      MaterialPageRoute(
                        builder: (_) => SajuResultScreen(
                          inputOption: inputOption,
                          selectedTime: selectedSaju!.birthDateTime,
                          isSelectMode: true, 
                          saju: selectedSaju!,
                        ),
                      ),
                    );
                    print('selectedSaju : ${selectedSaju!.name}');

                    if (result != null && result is Map<String, dynamic>) {
                      saju = result["saju"] as SajuInfo?;
                      koreanAge = result["age"] as String;
                      currentDaewoon = result["currentDaewoon"] as String;
                      ganji = Map<String, String?>.from(result["ganji"]);
                      daewoonList = List<String>.from(result["daewoon"] ?? []);


                      print("✅ 선택된 대운: $daewoonList, 현재 대운 : $currentDaewoon");

                      if (saju != null && ganji != null) {
                        print("✅ 선택된 사주 이름: ${saju!.name}");
                        print("✅ 선택된 간지들: $ganji");
                        print("✅ 선택된 대운: $daewoonList");

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('selected_saju', jsonEncode(saju!.toJson()));
                        await prefs.setString('selected_ganji', jsonEncode(ganji));
                        await prefs.setString('selected_daewoon', jsonEncode(daewoonList));
                        await prefs.setString('selected_age', jsonEncode(koreanAge));
                        await prefs.setString('selected_current_daewoon', jsonEncode(currentDaewoon));

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(
                              selectedResult: {
                                "saju": saju,
                                "ganji": ganji,
                                "daewoon": daewoonList,
                                "currentDaewoon": currentDaewoon,
                                "age": koreanAge,
                              },
                            ),
                          ),
                          (route) => false, // 모든 이전 화면 제거
                        );  
                      }
                    } else {
                      print("❌ 사주 선택이 취소되었거나 오류 발생");
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("사주 선택", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

          ],
        ),
      ),

    );
  }
Fortune pickFortuneByElement(List<Fortune> list, String element) {
  final filtered = list.where((f) => f.element == element).toList();
  if (filtered.isEmpty) return list.first; // fallback
  final random = Random();
  return filtered[random.nextInt(filtered.length)];
}

Future<List<Fortune>> getAllFortunesFromJson() async {
  final String response = await rootBundle.loadString('assets/fortune_data.json');
  final List<dynamic> data = json.decode(response);
  return data.map((json) => Fortune.fromJson(json)).toList();
}


Future<void> _loadUserData() async {
  final data = await loadSajuList();
  if (data.isNotEmpty) {
    // context는 initState에서는 바로 사용하면 안 되므로 Future.microtask로 감싸기
    Future.microtask(() {
      Provider.of<SajuProvider>(context, listen: false).setList(data);
    });
  }
}

Color _elementColor(String element/*, DateTime birthTime*/) {
  

  switch (element) {
      case "금":
        return Colors.grey;
      case "토":
        return Colors.orange;
      case "수":
        return Colors.blue;
      case "목":
        return Colors.green;
      case "화":
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}


class EditSajuScreen extends StatelessWidget {
  final SajuInfo saju;
  const EditSajuScreen({super.key, required this.saju});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사주 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("이름: ${saju.name}"),
            Text("생년월일: ${saju.birth}"),
            Text("관계: ${saju.relation}"),
            Text("오행: ${saju.element}"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, saju); // 그대로 반환
              },
              child: const Text("수정 완료"),
            )
          ],
        ),
      ),
    );
  }
}
