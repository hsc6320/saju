import 'package:flutter/material.dart';

import '../constants/saju_constants.dart';
import '../models/saju_info.dart';
import '../services/daewoon_calculator.dart';
import '../services/ganji_calculator.dart';
import '../services/sipsin_calculator.dart';
import '../saju/saju_grid.dart';
import '../saju/bigSolarTerm.dart' show DaewoonView, Daewoon, SaeWoon;
import 'home_screen.dart';

/// 사주 결과 화면
class SajuResultScreen extends StatefulWidget {
  final DateTime selectedTime;
  final List<Map<String, dynamic>> inputOption;
  final bool isSelectMode;
  final SajuInfo saju;

  const SajuResultScreen({
    super.key,
    required this.selectedTime,
    required this.inputOption,
    this.isSelectMode = false,
    required this.saju,
  });

  @override
  State<SajuResultScreen> createState() => _SajuResultScreenState();
}

class _SajuResultScreenState extends State<SajuResultScreen> {
  late DateTime _realBirthTime;
  Map<String, String> _ganjiData = {};
  String _koreanAge = '';

  @override
  void initState() {
    super.initState();
    _realBirthTime = widget.selectedTime;
  }

  /// 사주 데이터 로드
  Future<Map<String, String?>> _loadSajuData() async {
    final today = DateTime.now();
    final koreanAge = today.year - widget.selectedTime.year + 1;

    if (!widget.isSelectMode) {
      await Future.delayed(const Duration(seconds: 2));
    }

    final isLunar = widget.inputOption.first['solar_date'] == 'true';

    if (isLunar) {
      // 음력 선택 시 양력으로 변환
      final solarDate = await GanjiCalculator.getSolarFromLunar(widget.selectedTime);
      if (solarDate != null) {
        _realBirthTime = solarDate;
      }
    } else {
      _realBirthTime = widget.selectedTime;
    }

    // 년주
    final yearJu = await GanjiCalculator.getYearGanji(_realBirthTime);
    
    // 월주
    final wolJu = await GanjiCalculator.getWolJu(_realBirthTime) ?? '';
    
    // 일주
    String ilJu = '';
    int retry = 0;
    while (ilJu.isEmpty && retry < 5) {
      ilJu = await GanjiCalculator.getIlJu(_realBirthTime);
      if (ilJu.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      retry++;
    }
    
    // 시주
    final siJu = GanjiCalculator.getSiJu(_realBirthTime, ilJu);

    _ganjiData = {
      '년주': yearJu,
      '월주': wolJu,
      '일주': ilJu,
      '시주': siJu,
    };
    _koreanAge = koreanAge.toString();

    return {
      '년주': yearJu,
      '월주': wolJu,
      '일주': ilJu,
      '시주': siJu,
      '나이': _koreanAge,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _loadSajuData(),
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

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('데이터가 없습니다.')),
          );
        }

        return _buildResultScreen(snapshot.data!);
      },
    );
  }

  Widget _buildResultScreen(Map<String, String?> data) {
    final yearJu = data['년주'] ?? '';
    final wolJu = data['월주'] ?? '';
    final ilJu = data['일주'] ?? '';
    final siJu = data['시주'] ?? '';
    final koreanAge = data['나이'] ?? '';

    final gender = widget.inputOption.first['gender'];
    final isSunHaeng = DaewoonCalculator.isSunHaeng(yearJu.substring(0, 1), gender);
    final firstLuckAge = DaewoonCalculator.calculateFirstLuckAge(_realBirthTime, isSunHaeng);

    // 대운/세운 생성
    final daewoonList = DaewoonCalculator.generateDaewoonList(
      startGan: wolJu.isNotEmpty ? wolJu.substring(0, 1) : '',
      startJi: wolJu.length > 1 ? wolJu.substring(1) : '',
      isSunHaeng: isSunHaeng,
    );

    final saewoonList = DaewoonCalculator.generateSewoonList(
      startGan: yearJu.isNotEmpty ? yearJu.substring(0, 1) : '',
      startJi: yearJu.length > 1 ? yearJu.substring(1) : '',
      firstLuckAge: firstLuckAge,
    );

    final currentDaewoon = DaewoonCalculator.getCurrentDaewoon(
      int.tryParse(koreanAge) ?? 0,
      firstLuckAge,
      daewoonList,
    );

    // 선택 모드일 경우 결과 반환
    if (widget.isSelectMode) {
      _returnSelectResult(data, daewoonList, currentDaewoon, ilJu, firstLuckAge);
      return _buildSelectModeScreen(data);
    }

    // 사주 기둥 생성
    final pillars = _buildPillars(yearJu, wolJu, ilJu, siJu);

    // 대운 UI 데이터
    final sampleDaewoon = _buildDaewoonList(daewoonList, ilJu, firstLuckAge);
    final sampleSaewoon = saewoonList.map((g) => SaeWoon(ganji: g)).toList();

    return _buildFullResultScreen(
      pillars: pillars,
      daewoon: sampleDaewoon,
      saewoon: sampleSaewoon,
      firstLuckAge: firstLuckAge,
    );
  }

  List<SajuPillar> _buildPillars(String yearJu, String wolJu, String ilJu, String siJu) {
    final ilGan = ilJu.isNotEmpty ? ilJu.substring(0, 1) : '';

    return [
      SajuPillar(
        title: '시주',
        gan: siJu.isNotEmpty ? siJu.substring(0, 1) : '',
        ji: siJu.length > 1 ? siJu.substring(1) : '',
        tenRelation: SipsinCalculator.getSipsin(ilGan, siJu.isNotEmpty ? siJu.substring(0, 1) : ''),
        hiddenSipSins: SipsinCalculator.getJiSipsin(ilGan, siJu.length > 1 ? siJu.substring(1) : ''),
        hiddenStems: SipsinCalculator.getHiddenStemsSipsin(ilGan, siJu.length > 1 ? siJu.substring(1) : ''),
        elementGan: SajuConstants.ganToElement[siJu.isNotEmpty ? siJu.substring(0, 1) : ''] ?? '',
        elementJi: SajuConstants.jiToElement[siJu.length > 1 ? siJu.substring(1) : ''] ?? '',
      ),
      SajuPillar(
        title: '일주',
        gan: ilGan,
        ji: ilJu.length > 1 ? ilJu.substring(1) : '',
        tenRelation: '일간',
        hiddenSipSins: SipsinCalculator.getJiSipsin(ilGan, ilJu.length > 1 ? ilJu.substring(1) : ''),
        hiddenStems: SipsinCalculator.getHiddenStemsSipsin(ilGan, ilJu.length > 1 ? ilJu.substring(1) : ''),
        elementGan: SajuConstants.ganToElement[ilGan] ?? '',
        elementJi: SajuConstants.jiToElement[ilJu.length > 1 ? ilJu.substring(1) : ''] ?? '',
      ),
      SajuPillar(
        title: '월주',
        gan: wolJu.isNotEmpty ? wolJu.substring(0, 1) : '',
        ji: wolJu.length > 1 ? wolJu.substring(1) : '',
        tenRelation: SipsinCalculator.getSipsin(ilGan, wolJu.isNotEmpty ? wolJu.substring(0, 1) : ''),
        hiddenSipSins: SipsinCalculator.getJiSipsin(ilGan, wolJu.length > 1 ? wolJu.substring(1) : ''),
        hiddenStems: SipsinCalculator.getHiddenStemsSipsin(ilGan, wolJu.length > 1 ? wolJu.substring(1) : ''),
        elementGan: SajuConstants.ganToElement[wolJu.isNotEmpty ? wolJu.substring(0, 1) : ''] ?? '',
        elementJi: SajuConstants.jiToElement[wolJu.length > 1 ? wolJu.substring(1) : ''] ?? '',
      ),
      SajuPillar(
        title: '년주',
        gan: yearJu.isNotEmpty ? yearJu.substring(0, 1) : '',
        ji: yearJu.length > 1 ? yearJu.substring(1) : '',
        tenRelation: SipsinCalculator.getSipsin(ilGan, yearJu.isNotEmpty ? yearJu.substring(0, 1) : ''),
        hiddenSipSins: SipsinCalculator.getJiSipsin(ilGan, yearJu.length > 1 ? yearJu.substring(1) : ''),
        hiddenStems: SipsinCalculator.getHiddenStemsSipsin(ilGan, yearJu.length > 1 ? yearJu.substring(1) : ''),
        elementGan: SajuConstants.ganToElement[yearJu.isNotEmpty ? yearJu.substring(0, 1) : ''] ?? '',
        elementJi: SajuConstants.jiToElement[yearJu.length > 1 ? yearJu.substring(1) : ''] ?? '',
      ),
    ];
  }

  List<Daewoon> _buildDaewoonList(List<String> daewoonList, String ilJu, int firstLuckAge) {
    final ilGan = ilJu.isNotEmpty ? ilJu.substring(0, 1) : '';

    return List.generate(daewoonList.length, (index) {
      final ganji = daewoonList[index];
      final gan = ganji.isNotEmpty ? ganji.substring(0, 1) : '';
      final ji = ganji.length > 1 ? ganji.substring(1) : '';
      final element = SajuConstants.ganToElement[gan] ?? '기타';
      final age = firstLuckAge + index * 10;

      return Daewoon(
        age: age,
        ganji: ganji,
        element: element,
        tenGod: SipsinCalculator.getSipsin(ilGan, gan),
        tenGod2: SipsinCalculator.getJiSipsin(ilGan, ji),
      );
    });
  }

  void _returnSelectResult(
    Map<String, String?> data,
    List<String> daewoonList,
    String currentDaewoon,
    String ilJu,
    int firstLuckAge,
  ) {
    final ilGan = ilJu.isNotEmpty ? ilJu.substring(0, 1) : '';
    final result = SipsinCalculator.getElementAndYinyang(ilGan);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context, {
        'saju': widget.saju,
        'daewoon': List<String>.from(daewoonList),
        'currentDaewoon': currentDaewoon,
        'age': _koreanAge,
        'ganji': _ganjiData,
        'firstLuckAge': firstLuckAge, // 초대운 나이 추가
        'sipseong_info': {
          '일간': ilGan,
          '기준오행': result['오행'],
          '기준음양': result['음양'],
          '년주십성': {
            '천간': {'십성': SipsinCalculator.getSipsin(ilGan, data['년주']?.substring(0, 1) ?? '')},
            '지지': {'십성': SipsinCalculator.getJiSipsin(ilGan, data['년주']?.substring(1) ?? '')},
          },
          '월주십성': {
            '천간': {'십성': SipsinCalculator.getSipsin(ilGan, data['월주']?.substring(0, 1) ?? '')},
            '지지': {'십성': SipsinCalculator.getJiSipsin(ilGan, data['월주']?.substring(1) ?? '')},
          },
          '일주십성': {
            '천간': {'십성': ilGan},  // ✅ "일간" 라벨 대신 실제 일간 간지 사용
            '지지': {'십성': SipsinCalculator.getJiSipsin(ilGan, ilJu.length > 1 ? ilJu.substring(1) : '')},
          },
          '시주십성': {
            '천간': {'십성': SipsinCalculator.getSipsin(ilGan, data['시주']?.substring(0, 1) ?? '')},
            '지지': {'십성': SipsinCalculator.getJiSipsin(ilGan, data['시주']?.substring(1) ?? '')},
          },
          '현재대운': {
            '천간': {'십성': SipsinCalculator.getSipsin(ilGan, currentDaewoon.isNotEmpty ? currentDaewoon.substring(0, 1) : '')},
            '지지': {'십성': SipsinCalculator.getJiSipsin(ilGan, currentDaewoon.length > 1 ? currentDaewoon.substring(1) : '')},
          },
        },
      });
    });
  }

  Widget _buildSelectModeScreen(Map<String, String?> data) {
    return Scaffold(
      appBar: AppBar(title: const Text('사주 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('년주: ${data['년주']}, 월주: ${data['월주']}\n일주: ${data['일주']}, 시주: ${data['시주']}'),
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildFullResultScreen({
    required List<SajuPillar> pillars,
    required List<Daewoon> daewoon,
    required List<SaeWoon> saewoon,
    required int firstLuckAge,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            title: const Text(
              '사주 결과',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.normal),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '성별: ${widget.inputOption.first['gender']}\n이름: ${widget.inputOption.first['name']}',
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                    Text('나이: $_koreanAge', style: const TextStyle(fontWeight: FontWeight.normal)),
                    Text(
                      '생년월일(양력): ${_realBirthTime.year}.${_realBirthTime.month}.${_realBirthTime.day}\n태어난 시간: ${_realBirthTime.hour}시 ${_realBirthTime.minute}분',
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                    const SizedBox(height: 10),
                    SajuGrid(pillars: pillars),
                    const SizedBox(height: 16),
                    DaewoonView(
                      daewoonList: daewoon,
                      saewoonList: saewoon,
                      birthDate: _realBirthTime,
                      firstLuckAge: firstLuckAge,
                      gender: widget.inputOption.first['gender'],
                      yearGan: _ganjiData['년주'] ?? '',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
