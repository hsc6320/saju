import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../Login/LoginScreen.dart';
import '../SajuProvider.dart';
import '../models/saju_info.dart';
import '../models/selected_saju_data.dart';
import '../services/saju_storage_service.dart';
import 'Saju_ChatScreen.dart';
import 'saju_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedResult;
  const HomeScreen({super.key, this.selectedResult});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SelectedSajuData _selectedData = SelectedSajuData.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 초기 데이터 로드
  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadSelectedSaju();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 사주 리스트 로드 및 Provider 설정
  Future<void> _loadUserData() async {
    final data = await sajuStorage.loadSajuList();
    if (data.isNotEmpty && mounted) {
      Future.microtask(() {
        Provider.of<SajuProvider>(context, listen: false).setList(data);
      });
    }
  }

  /// 선택된 사주 불러오기
  Future<void> _loadSelectedSaju() async {
    final data = await sajuStorage.loadSelectedSaju();
    
    // Provider에서 사주 리스트 확인
    if (mounted) {
      final sajuProvider = Provider.of<SajuProvider>(context, listen: false);
      if (sajuProvider.sajuList.isEmpty) {
        await sajuStorage.clearSelectedSaju();
        setState(() {
          _selectedData = SelectedSajuData.empty();
        });
        return;
      }
    }

    setState(() {
      _selectedData = data;
    });

    if (data.isValid) {
      debugPrint('✅ 저장된 사주 불러오기: ${data.saju!.name}, 나이: ${data.koreanAge}');
    }
  }

  /// 사주 변경 및 저장
  Future<void> _changeSaju(SelectedSajuData data) async {
    if (data.saju == null || !data.saju!.isValid) {
      await sajuStorage.clearSelectedSaju();
      setState(() {
        _selectedData = SelectedSajuData.empty();
      });
      return;
    }

    await sajuStorage.saveSelectedSaju(data);
    setState(() {
      _selectedData = data;
    });

    debugPrint('선택된 사주: ${data.saju!.name}, 현재 대운: ${data.currentDaewoon}');
  }

  /// 로그아웃 처리
  Future<void> _handleLogout(User user) async {
    try {
      // Firestore 상태 업데이트
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isLoggedIn': false,
        'lastLogoutAt': FieldValue.serverTimestamp(),
      });

      // Google 로그인 세션 정리
      final providerIds = user.providerData.map((p) => p.providerId).toList();
      if (providerIds.contains('google.com')) {
        try {
          await GoogleSignIn().signOut();
        } catch (e) {
          debugPrint('GoogleSignIn 로그아웃 실패: $e');
        }
      }

      // FirebaseAuth 로그아웃
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃 되었습니다')),
        );
      }
    } catch (e) {
      debugPrint('로그아웃 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃 중 오류 발생')),
        );
      }
    }
  }

  /// 사주 목록에서 선택 결과 처리
  void _handleSajuSelection(Map<String, dynamic> selected) {
    final saju = selected['saju'] as SajuInfo?;
    
    if (saju == null || !saju.isValid) {
      _changeSaju(SelectedSajuData.empty());
      return;
    }

    final sipseong = SipseongInfo(
      yinYang: selected['sipseong_yinyang'] ?? '',
      fiveElement: selected['sipseong_fiveElement'] ?? '',
      yearGan: selected['sipseong_year_gan'] ?? '',
      yearJi: selected['sipseong_year_ji'] ?? '',
      wolGan: selected['sipseong_wol_gan'] ?? '',
      wolJi: selected['sipseong_wol_ji'] ?? '',
      ilGan: selected['sipseong_il_gan'] ?? '',
      ilJi: selected['sipseong_il_ji'] ?? '',
      siGan: selected['sipseong_si_gan'] ?? '',
      siJi: selected['sipseong_si_ji'] ?? '',
      currDaewoonGan: selected['sipseong_curr_daewoon_gan'] ?? '',
      currDaewoonJi: selected['sipseong_curr_daewoon_ji'] ?? '',
    );

    final data = SelectedSajuData(
      saju: saju,
      ganji: selected['ganji'] != null 
          ? Map<String, String?>.from(selected['ganji']) 
          : {},
      daewoon: selected['daewoon'] != null 
          ? List<String>.from(selected['daewoon']) 
          : [],
      koreanAge: selected['age'] as String? ?? '',
      currentDaewoon: selected['currentDaewoon'] as String? ?? '',
      sipseong: sipseong,
      firstLuckAge: selected['firstLuckAge'] as int? ?? 0,
    );

    _changeSaju(data);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(user),
      drawer: _buildDrawer(user),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedData.isValid)
              _buildSelectedSajuView()
            else
              _buildEmptySajuView(),
          ],
        ),
      ),
    );
  }

  /// AppBar 빌드
  PreferredSizeWidget _buildAppBar(User? user) {
    return AppBar(
      title: const Text('운세 대화', style: TextStyle(color: Colors.black)),
      backgroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      actions: [
        TextButton(
          onPressed: () => _handleLoginButton(user),
          child: Text(
            user != null ? (user.displayName ?? user.email ?? '사용자') : '로그인',
            style: const TextStyle(color: Colors.indigo),
          ),
        ),
      ],
    );
  }

  /// 로그인 버튼 처리
  Future<void> _handleLoginButton(User? user) async {
    if (user == null) {
      final loginId = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );

      if (loginId != null && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$loginId님 😊')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName ?? user.email}님 😊')),
      );
    }
  }

  /// Drawer 빌드
  Widget _buildDrawer(User? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(
                user?.displayName?.substring(0, 1) ?? '?',
                style: const TextStyle(fontSize: 28, color: Colors.black),
              ),
            ),
            accountName: Text(user?.displayName ?? '비회원'),
            accountEmail: Text(user?.email ?? '로그인이 필요합니다'),
            decoration: BoxDecoration(color: Colors.indigo[100]),
          ),
          ListTile(
            title: const Text('사주목록'),
            onTap: () => _navigateToSajuList(),
          ),
          ListTile(
            title: const Text('설정'),
            onTap: () => _navigateToSettings(),
          ),
          if (user != null)
            ListTile(
              title: const Text('로그아웃'),
              onTap: () => _handleLogout(user),
            ),
        ],
      ),
    );
  }

  /// 사주 목록으로 이동
  Future<void> _navigateToSajuList() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SajuListScreen()),
    );

    if (selected != null && selected is Map<String, dynamic>) {
      _handleSajuSelection(selected);
    }
  }

  /// 설정 화면으로 이동
  void _navigateToSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsScreen(),
    );
  }

  /// 선택된 사주 뷰
  Widget _buildSelectedSajuView() {
    final saju = _selectedData.saju!;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.yellow[600],
              child: const Icon(Icons.person, size: 40, color: Colors.black),
            ),
            const CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white,
              child: Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          saju.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '${saju.birth} (${saju.relation})',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _navigateToChat,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text('사주 대화 시작', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  /// 이메일에서 ID 추출 (@ 앞 부분)
  String? _emailId(String? email) {
    if (email == null || !email.contains('@')) return null;
    return email.split('@').first;
  }

  /// 앱 UID 생성 (로그인 ID 우선순위: 이메일ID > displayName > uid)
  String _getAppUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    
    return _emailId(user.email)    // 1순위: hsc6320
        ?? user.displayName        // 2순위: 홍승창
        ?? user.uid;               // 3순위: uid
  }

  /// 채팅 화면으로 이동
  void _navigateToChat() {
    final saju = _selectedData.saju!;
    final ganji = _selectedData.ganji;
    final appUid = _getAppUid();

    // 🔥 사주 대화 시작 버튼 클릭 시 로그 출력
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 🚀 사주 대화 시작 - 채팅 화면으로 전달되는 데이터');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 👤 사용자 정보');
    debugPrint('║    - name: ${saju.name}');
    debugPrint('║    - birth: ${saju.birth}');
    debugPrint('║    - relation: ${saju.relation}');
    debugPrint('║    - app_uid: $appUid');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 🔮 사주 원국 (sajuganji)');
    debugPrint('║    - 년주: ${ganji['년주']}');
    debugPrint('║    - 월주: ${ganji['월주']}');
    debugPrint('║    - 일주: ${ganji['일주']}');
    debugPrint('║    - 시주: ${ganji['시주']}');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 🌊 대운 정보');
    debugPrint('║    - currentDaewoon: ${_selectedData.currentDaewoon}');
    debugPrint('║    - firstLuckAge: ${_selectedData.firstLuckAge}');
    debugPrint('║    - koreanAge: ${_selectedData.koreanAge}');
    debugPrint('║    - daewoon: ${_selectedData.daewoon}');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ ⚖️ 십성 정보');
    debugPrint('║    - yinYang: ${_selectedData.sipseong.yinYang}');
    debugPrint('║    - fiveElement: ${_selectedData.sipseong.fiveElement}');
    debugPrint('║    - 년간/년지: ${_selectedData.sipseong.yearGan} / ${_selectedData.sipseong.yearJi}');
    debugPrint('║    - 월간/월지: ${_selectedData.sipseong.wolGan} / ${_selectedData.sipseong.wolJi}');
    debugPrint('║    - 일간/일지: ${_selectedData.sipseong.ilGan} / ${_selectedData.sipseong.ilJi}');
    debugPrint('║    - 시간/시지: ${_selectedData.sipseong.siGan} / ${_selectedData.sipseong.siJi}');
    debugPrint('║    - 대운간/대운지: ${_selectedData.sipseong.currDaewoonGan} / ${_selectedData.sipseong.currDaewoonJi}');
    debugPrint('╚══════════════════════════════════════════════════════════════');
    debugPrint('');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SajuChatScreen(
          saju: saju,
          sajuganji: Map<String, String?>.from(ganji),
          daewoon: _selectedData.daewoon,
          currentDaewoon: _selectedData.currentDaewoon,
          yinYang: _selectedData.sipseong.yinYang,
          fiveElement: _selectedData.sipseong.fiveElement,
          yearGan: _selectedData.sipseong.yearGan,
          yearJi: _selectedData.sipseong.yearJi,
          wolGan: _selectedData.sipseong.wolGan,
          wolJi: _selectedData.sipseong.wolJi,
          ilGan: _selectedData.sipseong.ilGan,
          ilJi: _selectedData.sipseong.ilJi,
          siGan: _selectedData.sipseong.siGan,
          siJi: _selectedData.sipseong.siJi,
          currDaewoonGan: _selectedData.sipseong.currDaewoonGan,
          currDaewoonJi: _selectedData.sipseong.currDaewoonJi,
          firstLuckAge: _selectedData.firstLuckAge,
          appUid: appUid,
        ),
      ),
    );
  }

  /// 빈 사주 뷰
  Widget _buildEmptySajuView() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person_outline, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              '사주를 선택하세요',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Text(
              '선택된 사주 없음',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
