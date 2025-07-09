import 'dart:convert';
//import 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:saju/Login/LoginScreen.dart';
import 'package:saju/SajuProvider.dart';
import 'package:saju/SharedPreferences.dart';
import 'package:saju/screens/Saju_ChatScreen.dart';
import 'package:saju/screens/saju_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fortune.dart';
import '../api/gpt_service.dart';


class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedResult;
  const HomeScreen({super.key, this.selectedResult});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  List<Fortune> _allFortunes = [];
  List<String>? _daewoonList = [];  // 사주 선택 시 전달받는 대운 리스트
  String? _koreanAge = '';
  String? _currentDaewoon = '';
  SajuInfo? selectedSaju;
  Map<String, String?>? selectedGanji; // ← 간지 정보도 함께 저장하려면
  SajuInfo? _selectedSaju;
  String? gptSummary;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  //  WidgetsBinding.instance.addPostFrameCallback((_) {
  //  _loadSelectedSaju(); // 이 시점에는 Provider 데이터가 초기화되었을 확률이 높음
  //});
  }

 /* Future<void> _loadAllFortunes() async {
    final String response = await rootBundle.loadString('assets/fortune_data.json');
    //print("_loadAllFortunes() $response");
    final List<dynamic> data = json.decode(response);
    setState(() {
      _allFortunes = data.map((json) => Fortune.fromJson(json)).toList();
    });
  }*/


Future<void> _loadUserData() async {
  final data = await loadSajuList();
  if (data.isNotEmpty) {
    // context는 initState에서는 바로 사용하면 안 되므로 Future.microtask로 감싸기
    Future.microtask(() {
      Provider.of<SajuProvider>(context, listen: false).setList(data);
      
      // 💡 Provider 데이터 등록 후 실행
      _loadSelectedSaju(); 
    });
  }
}

  void _loadSelectedSaju() async {
    final prefs = await SharedPreferences.getInstance();
    final sajuJson = prefs.getString('selected_saju');
    final ganjiJson = prefs.getString('selected_ganji');
    final daewoonJson = prefs.getString('selected_daewoon');
    final koreaAgeJson = prefs.getString('selected_age');
    final current_daewoonJson = prefs.getString('selected_current_daewoon');
  

    if (sajuJson != null) {
      final saju = SajuInfo.fromJson(jsonDecode(sajuJson));
      final String? age = koreaAgeJson != null ? jsonDecode(koreaAgeJson) : null;
      final String? currentDaewoon = current_daewoonJson != null ? jsonDecode(current_daewoonJson) : null;
      final Map<String, String?> ganji = ganjiJson != null ? Map<String, String?>.from(jsonDecode(ganjiJson)):  {};
      final List<String> daewoon = daewoonJson != null
                                  ? List<String>.from(jsonDecode(daewoonJson)) // ✅ JSON 문자열 → List<String> 변환
                                  : [];
      
      setState(() {
        _selectedSaju = saju;
        selectedGanji = ganji;
        _daewoonList = daewoon;
        _currentDaewoon = currentDaewoon ?? '미정';
        _koreanAge = age ?? '미정';
      });
      print("✅ 저장된 사주 불러오기: ${saju.birth}, ${saju.name}, 나이: $_koreanAge, 현재대운 : $_currentDaewoon");

    } else {
      print("⚠️ 저장된 사주 정보 없음");
    }

    final sajuProvider = Provider.of<SajuProvider>(context,  listen: false);
    final sajuList = sajuProvider.sajuList;
    if (sajuList.isEmpty) {
        print("🧹 사주 목록이 비어있어서 SharedPreferences 초기화");
        await prefs.remove('selected_saju');
        await prefs.remove('selected_ganji');
        await prefs.remove('selected_daewoon');
        await prefs.remove('selected_age');
        await prefs.remove('selected_current_daewoon');

        setState(() {
          _selectedSaju = null;
          selectedGanji = {};
          _daewoonList = [];
          _koreanAge = '';
          _currentDaewoon = '';
        });
        return;
    }
    print("_loadSelectedSaju : $sajuJson");
    
  }

  void _changeSaju(SajuInfo saju, Map<String, String?> ganji, List<String>? daewoon, String age, String currentdaewoon) async {

    if (saju.name.isEmpty) return; // 빈 사주는 저장 안 함

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_saju', jsonEncode(saju.toJson()));
    await prefs.setString('selected_ganji', jsonEncode(ganji));
    await prefs.setString('selected_daewoon', jsonEncode(daewoon));
    await prefs.setString('selected_age', jsonEncode(age));
    await prefs.setString('selected_current_daewoon', jsonEncode(currentdaewoon));

    setState(() {
      _daewoonList = daewoon ?? []; // ← 대운 리스트도 저장
      _selectedSaju = saju;
      selectedGanji = ganji;  // 🔥 이렇게 간지 정보도 상태에 저장
      _currentDaewoon = currentdaewoon;
      _koreanAge = age;
    });

    // 필요하다면 Provider에 저장하거나 채팅 화면에 전달
    print("선택된 간지 정보: $_selectedSaju, 현재 대운 : $_currentDaewoon, 나이 : $age");
    
    // 🔥 명시적으로 다시 불러오기
    _loadSelectedSaju();
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('운세 대화', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.displayName ?? user.email}님 😊')),
                );
              }
            },
            child: Text(
              user != null ? (user.displayName ?? user.email ?? '사용자') : '로그인',
              style: TextStyle(color: Colors.indigo),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text(
                  user?.displayName?.substring(0, 1) ?? '?',
                  style: TextStyle(fontSize: 28, color: Colors.black),
                ),
              ),
              accountName: Text(user?.displayName ?? '비회원'),
              accountEmail: Text(user?.email ?? '로그인이 필요합니다'),
              decoration: BoxDecoration(color: Colors.indigo[100]),
            ),
            ListTile(
              title: Text('사주목록'),
              onTap: () async {
              //  Navigator.pop(context);
                final selected = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SajuListScreen()),
                );
               if (selected != null && selected is Map<String, dynamic>) {
                  final SajuInfo? saju = selected['saju'] as SajuInfo ?;
                  final String koreanAge = selected['age'] as String? ?? '';
                  final String currentDaewoon = selected['currentDaewoon'] as String? ?? '';


                  final Map<String, String?>? ganji =
                      selected['ganji'] != null ? Map<String, String?>.from(selected['ganji']) : null;
                  
                  final List<String> daewoon = selected['daewoon'] != null
                                                              ? List<String>.from(selected['daewoon'])
                                                              : [];
                  print('homescreen 대운 : $daewoon, 현재 대운 : $currentDaewoon, 나이 : $koreanAge');

                  if (saju != null) {
                    print('간지정보까지 전달');
                    _changeSaju(saju, ganji!, daewoon, koreanAge, currentDaewoon); // 🟡 간지 정보까지 함께 전달
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      print('✅ homescreen 대운2222 (postFrame): $_daewoonList');
                    });
                  } else {
                    print("❌ 선택된 사주 정보가 null입니다.");
                    setState(() {
                      _selectedSaju = null;
                      selectedGanji = null;
                      _currentDaewoon = '';
                      _koreanAge = '';
                    });
                    _changeSaju(
                      SajuInfo(name: '', relation: '', birth: '', element: '', lunar: '', time: const TimeOfDay(hour: 0, minute: 0)),
                      {},
                      [],
                      koreanAge,
                      currentDaewoon,
                    );
                    return;
                   
                  }
                } else {
                  print("❌ 사주 선택이 취소되었거나 형식이 잘못됨");
                }
              },
            ),
            ListTile(title: Text('설정')),
            if (user != null)
              ListTile(
                title: Text('로그아웃'),
                onTap: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'isLoggedIn': false,
                      'lastLogoutAt': FieldValue.serverTimestamp(),
                    });
                    await FirebaseAuth.instance.signOut();
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그아웃 되었습니다')),
                    );
                  } catch (e) {
                    print('로그아웃 실패: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그아웃 중 오류 발생')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedSaju != null && _selectedSaju!.isValid)
              Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.yellow[600],
                        child: Icon(Icons.person, size: 40, color: Colors.black),
                      ),
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.check_circle, color: Colors.green, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedSaju!.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_selectedSaju!.birth} (${_selectedSaju!.relation})2222',
                   //'222222',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SajuChatScreen(
                            saju: _selectedSaju!, 
                            sajuganji: selectedGanji!, 
                            daewoon: _daewoonList!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('사주 대화 시작', style: TextStyle(fontSize: 18)),
                  ),
                ],
              )
            else
            Expanded (
              child : Center (
                child : Column(
             //     mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // 이게 중요!
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[400],
                      child: Icon(Icons.person_outline, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "사주를 선택하세요",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "선택된 사주 없음",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),


               
          ],
        ),
      ),
    );
  }
}

