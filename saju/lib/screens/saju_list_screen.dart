import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../SajuProvider.dart';
import '../constants/saju_constants.dart';
import '../models/fortune.dart';
import '../models/saju_info.dart';
import '../models/selected_saju_data.dart';
import '../services/saju_storage_service.dart';
import 'home_screen.dart';
import 'saju_input_screen.dart';
import 'saju_result_screen.dart';

/// 정렬 옵션
enum SortOption { date, nameAsc, nameDesc }

/// 사주 목록 화면
class SajuListScreen extends StatefulWidget {
  final DateTime? selectedTime;
  final List<Map<String, dynamic>>? inputOption;

  const SajuListScreen({
    super.key,
    this.selectedTime,
    this.inputOption,
  });

  @override
  State<SajuListScreen> createState() => _SajuListScreenState();
}

class _SajuListScreenState extends State<SajuListScreen> {
  SajuInfo? _selectedSaju;
  SelectedSajuData _selectedData = SelectedSajuData.empty();
  Widget? _rightPanelContent; // 우측 패널 내용

  String _searchQuery = '';
  SortOption _sortOption = SortOption.date;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadUserData();
    await _loadSelectedSaju();
  }

  Future<void> _loadUserData() async {
    final data = await sajuStorage.loadSajuList();
    if (data.isNotEmpty && mounted) {
      Future.microtask(() {
        Provider.of<SajuProvider>(context, listen: false).setList(data);
      });
    }
  }

  Future<void> _loadSelectedSaju() async {
    final data = await sajuStorage.loadSelectedSaju();
    if (data.isValid) {
      setState(() {
        _selectedSaju = data.saju;
        _selectedData = data;
      });
    }
  }

  /// 사주 삭제
  Future<void> _deleteItem(SajuInfo saju) async {
    final provider = Provider.of<SajuProvider>(context, listen: false);
    await provider.remove(saju);

    // 선택된 사주가 삭제된 경우 초기화
    if (_selectedSaju?.name == saju.name && _selectedSaju?.birth == saju.birth) {
      await sajuStorage.clearSelectedSaju();
      setState(() {
        _selectedSaju = null;
        _selectedData = SelectedSajuData.empty();
      });
    }
  }

  /// 사주 수정
  Future<void> _editItem(SajuInfo saju) async {
    final edited = await Navigator.push<SajuInfo>(
      context,
      MaterialPageRoute(
        builder: (_) => SajuInputScreen(
          saju: saju.copyWith(isEditing: true),
        ),
      ),
    );

    if (edited != null && mounted) {
      final provider = Provider.of<SajuProvider>(context, listen: false);
      await provider.updateItem(saju, edited);
    }
  }

  /// 사주 조회용 inputOption 생성
  List<Map<String, dynamic>> _generateInputOption(SajuInfo saju) {
    return [
      {
        'name': saju.name,
        'solar_date': saju.lunar,
        'gender': saju.relation,
      }
    ];
  }

  /// 정렬된 리스트 반환
  List<SajuInfo> _getSortedList(List<SajuInfo> list) {
    final filtered = list.where((item) => item.name.contains(_searchQuery)).toList();

    filtered.sort((a, b) {
      // 즐겨찾기 우선
      if (a.isFavorite != b.isFavorite) {
        return b.isFavorite ? 1 : -1;
      }
      // 정렬 옵션 적용
      switch (_sortOption) {
        case SortOption.date:
          return b.birth.compareTo(a.birth);
        case SortOption.nameAsc:
          return a.name.compareTo(b.name);
        case SortOption.nameDesc:
          return b.name.compareTo(a.name);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final sajuProvider = Provider.of<SajuProvider>(context);
    final filteredList = _getSortedList(sajuProvider.sajuList);

    return Scaffold(
      appBar: _buildAppBar(sajuProvider.isEmpty),
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;
          
          if (isWideScreen) {
            // 큰 화면: 좌우 분할 레이아웃
            return Row(
              children: [
                // 좌측: 사주 목록 (고정 너비)
                SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      if (_selectedSaju != null && _selectedSaju!.isValid)
                        _buildSelectedHeader(),
                      Expanded(
                        child: _buildSajuList(filteredList),
                      ),
                    ],
                  ),
                ),
                // 구분선
                Container(width: 1, color: Colors.grey.shade300),
                // 우측: 선택된 사주 결과 또는 빈 화면
                Expanded(
                  child: _rightPanelContent ?? _buildEmptyRightPanel(),
                ),
              ],
            );
          } else {
            // 작은 화면: 기존 레이아웃
            return Stack(
              children: [
                Column(
                  children: [
                    if (_selectedSaju != null && _selectedSaju!.isValid)
                      _buildSelectedHeader(),
                    Expanded(
                      child: _buildSajuList(filteredList),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          // 작은 화면에서만 하단 바 표시
          if (constraints.maxWidth > 800) {
            return const SizedBox.shrink();
          }
          return _buildBottomBar();
        },
      ),
    );
  }

  Widget _buildEmptyRightPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '좌측에서 사주를 선택하세요',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isEmpty) {
    return AppBar(
      title: const Text('등록된 사주 정보', style: TextStyle(color: Colors.black)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
        onPressed: () {
          if (isEmpty) {
            Navigator.pop(context, {'saju': null, 'ganji': null, 'daewoon': null});
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        },
      ),
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        PopupMenuButton<SortOption>(
          icon: const Icon(Icons.sort, color: Colors.grey),
          onSelected: (option) => setState(() => _sortOption = option),
          itemBuilder: (context) => const [
            PopupMenuItem(value: SortOption.date, child: Text('생년월일순')),
            PopupMenuItem(value: SortOption.nameAsc, child: Text('이름 오름차순')),
            PopupMenuItem(value: SortOption.nameDesc, child: Text('이름 내림차순')),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
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
    );
  }

  Widget _buildSelectedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.yellow.shade100,
                child: const Icon(Icons.person, size: 28, color: Colors.black),
              ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.check_circle, color: Colors.amber, size: 20),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _selectedSaju!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  if (_selectedSaju!.element.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedSaju!.element,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedSaju!.birth} (${_selectedSaju!.relation})',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSajuList(List<SajuInfo> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('등록된 사주가 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final saju = list[index];
        final isSelected = _selectedSaju == saju;

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
              _selectedSaju = isSelected ? null : saju;
              if (_selectedSaju != null) {
                // 우측 패널에 결과 화면 표시
                _loadResultForSelectedSaju(_selectedSaju!);
              } else {
                _rightPanelContent = null;
              }
            });
          },
          selected: isSelected,
          selectedTileColor: Colors.grey.shade100,
          title: Row(
            children: [
              Text(saju.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              if (saju.element.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SajuConstants.getElementColor(saju.element),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    saju.element,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            '${saju.birth} (${saju.relation})',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editItem(saju);
              } else if (value == 'delete') {
                _deleteItem(saju);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedSaju == null)
            _buildButton('사주 추가', Colors.indigo, _navigateToInput),
          if (_selectedSaju != null) ...[
            _buildButton('사주 조회', Colors.deepPurpleAccent, _navigateToResult),
            const SizedBox(height: 8),
            _buildButton('사주 선택', Colors.indigo, _selectAndNavigateHome),
          ],
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  void _navigateToInput() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SajuInputScreen()),
    );
  }

  void _loadResultForSelectedSaju(SajuInfo saju) {
    setState(() {
      _rightPanelContent = SajuResultScreen(
        inputOption: _generateInputOption(saju),
        selectedTime: saju.birthDateTime,
        saju: saju,
      );
    });
  }

  void _navigateToResult() {
    if (_selectedSaju == null) return;
    
    // 작은 화면에서는 네비게이션으로 이동
    final constraints = MediaQuery.of(context).size.width;
    if (constraints <= 800) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SajuResultScreen(
            inputOption: _generateInputOption(_selectedSaju!),
            selectedTime: _selectedSaju!.birthDateTime,
            saju: _selectedSaju!,
          ),
        ),
      );
    } else {
      // 큰 화면에서는 우측 패널에 표시
      _loadResultForSelectedSaju(_selectedSaju!);
    }
  }

  Future<void> _selectAndNavigateHome() async {
    if (_selectedSaju == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SajuResultScreen(
          inputOption: _generateInputOption(_selectedSaju!),
          selectedTime: _selectedSaju!.birthDateTime,
          isSelectMode: true,
          saju: _selectedSaju!,
        ),
      ),
    );

    if (result == null) return;

    // ✅ 일간 추출: sipseong_info의 '일간' 필드 우선, 없으면 일주에서 추출
    final ganji = result['ganji'] != null ? Map<String, String?>.from(result['ganji']) : {};
    final ilJu = ganji['일주'] ?? '';
    final ilGanFromSipseong = result['sipseong_info']?['일간'] ?? '';
    final ilGanFromIlJu = ilJu.isNotEmpty ? ilJu.substring(0, 1) : '';
    // "일간"이라는 라벨이 아닌 실제 간지인지 확인
    final validIlGan = (ilGanFromSipseong.isNotEmpty && 
                       ilGanFromSipseong != '일간' && 
                       ilGanFromSipseong.length == 1) 
                       ? ilGanFromSipseong 
                       : ilGanFromIlJu;

    final sipseong = SipseongInfo(
      yinYang: result['sipseong_info']?['기준음양'] ?? '',
      fiveElement: result['sipseong_info']?['기준오행'] ?? '',
      yearGan: result['sipseong_info']?['년주십성']?['천간']?['십성'] ?? '',
      yearJi: result['sipseong_info']?['년주십성']?['지지']?['십성'] ?? '',
      wolGan: result['sipseong_info']?['월주십성']?['천간']?['십성'] ?? '',
      wolJi: result['sipseong_info']?['월주십성']?['지지']?['십성'] ?? '',
      ilGan: validIlGan,  // ✅ 실제 일간 간지 사용 (예: "辛")
      ilJi: result['sipseong_info']?['일주십성']?['지지']?['십성'] ?? '',
      siGan: result['sipseong_info']?['시주십성']?['천간']?['십성'] ?? '',
      siJi: result['sipseong_info']?['시주십성']?['지지']?['십성'] ?? '',
      currDaewoonGan: result['sipseong_info']?['현재대운']?['천간']?['십성'] ?? '',
      currDaewoonJi: result['sipseong_info']?['현재대운']?['지지']?['십성'] ?? '',
    );

    final selectedData = SelectedSajuData(
      saju: result['saju'] as SajuInfo?,
      ganji: result['ganji'] != null ? Map<String, String?>.from(result['ganji']) : {},
      daewoon: result['daewoon'] != null ? List<String>.from(result['daewoon']) : [],
      koreanAge: result['age'] as String? ?? '',
      currentDaewoon: result['currentDaewoon'] as String? ?? '',
      sipseong: sipseong,
      firstLuckAge: result['firstLuckAge'] as int? ?? 0,
    );

    await sajuStorage.saveSelectedSaju(selectedData);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            selectedResult: {
              'saju': selectedData.saju,
              'ganji': selectedData.ganji,
              'daewoon': selectedData.daewoon,
              'currentDaewoon': selectedData.currentDaewoon,
              'age': selectedData.koreanAge,
              'firstLuckAge': selectedData.firstLuckAge,
              'sipseong_yinyang': sipseong.yinYang,
              'sipseong_fiveElement': sipseong.fiveElement,
              'sipseong_year_gan': sipseong.yearGan,
              'sipseong_year_ji': sipseong.yearJi,
              'sipseong_wol_gan': sipseong.wolGan,
              'sipseong_wol_ji': sipseong.wolJi,
              'sipseong_il_gan': sipseong.ilGan,
              'sipseong_il_ji': sipseong.ilJi,
              'sipseong_si_gan': sipseong.siGan,
              'sipseong_si_ji': sipseong.siJi,
              'sipseong_curr_daewoon_gan': sipseong.currDaewoonGan,
              'sipseong_curr_daewoon_ji': sipseong.currDaewoonJi,
            },
          ),
        ),
        (route) => false,
      );
    }
  }
}
