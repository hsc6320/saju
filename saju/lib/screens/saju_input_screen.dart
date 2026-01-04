import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../SajuProvider.dart';
import '../models/personal_info.dart';
import '../models/saju_info.dart';
import '../models/selected_saju_data.dart';
import '../services/daewoon_calculator.dart';
import '../services/ganji_calculator.dart';
import '../services/saju_storage_service.dart';
import '../services/settings_storage_service.dart';
import '../services/sipsin_calculator.dart';
import 'home_screen.dart';
import 'saju_list_screen.dart';
import 'saju_result_screen.dart';

/// 사주 정보 입력 화면
class SajuInputScreen extends StatefulWidget {
  final SajuInfo? saju;
  
  const SajuInputScreen({super.key, this.saju});

  @override
  State<SajuInputScreen> createState() => _SajuInputScreenState();
}

class _SajuInputScreenState extends State<SajuInputScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isTimeUnknown = false; // 출생 시간 모름 (기본값: 선택안함)

  bool _isLunar = false; // 양력으로 고정
  String _gender = '남자';

  final _formKeyDate = GlobalKey<FormState>();
  final _formKeyTime = GlobalKey<FormState>();
  final _formKeyName = GlobalKey<FormState>();
  
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _nameController;
  
  // 개인맞춤입력 관련
  PersonalInfo _personalInfo = PersonalInfo.empty();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _hobbyOtherController = TextEditingController();
  final TextEditingController _jobNameController = TextEditingController();
  
  // 선택 옵션들
  static const List<String> jobStatusOptions = [
    '직장인',
    '프리랜서',
    '자영업',
    '공무원',
    '취업준비',
    '학생',
    '무직/휴직',
  ];

  static const List<String> maritalStatusOptions = [
    '미혼',
    '기혼',
    '이혼',
    '사별',
  ];

  static const List<String> concernOptions = [
    '직업/커리어',
    '재물/투자',
    '연애/결혼',
    '건강',
    '인간관계',
    '자녀',
    '학업/시험',
  ];

  static const List<String> lifeStageOptions = [
    '사회초년',
    '성장기',
    '전환기(이직/변화)',
    '안정기',
    '은퇴준비',
  ];

  static const List<String> moneyActivityOptions = [
    '월급위주',
    '투자중',
    '사업중',
    '무소득',
  ];

  static const List<String> relationshipStatusOptions = [
    '연애중',
    '장기연애',
    '최근이별',
    '없음',
  ];

  static const List<String> hobbyOptions = [
    '운동',
    '창작(글/음악/그림)',
    '공부/독서',
    '게임/경쟁',
    '휴식위주',
    '자기계발',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFromExisting();
  }

  void _initializeControllers() {
    _dateController = TextEditingController(
      text: widget.saju != null
          ? DateFormat('yyyy-MM-dd').format(widget.saju!.birthDateTime)
          : DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    _timeController = TextEditingController(
      text: widget.saju != null
          ? (widget.saju!.time != null
              ? DateFormat('HH:mm').format(DateTime(
                  widget.saju!.birthDateTime.year,
                  widget.saju!.birthDateTime.month,
                  widget.saju!.birthDateTime.day,
                  widget.saju!.time!.hour,
                  widget.saju!.time!.minute,
                ))
              : '모름')
          : '', // 기본값: 선택안함 (빈 문자열)
    );

    _nameController = TextEditingController(
      text: widget.saju?.name ?? '',
    );
  }

  void _initializeFromExisting() async {
    if (widget.saju != null) {
      _isLunar = false; // 양력으로 고정
      _gender = widget.saju!.relation;
      _selectedDate = widget.saju!.birthDateTime;
      _selectedTime = widget.saju!.time;
      _isTimeUnknown = widget.saju!.time == null;
      
      // ✅ 기존 사주의 개인맞춤입력 정보 로드
      try {
        final loadedPersonalInfo = await settingsStorage.loadPersonalInfo(
          name: widget.saju!.name,
          birth: widget.saju!.birth,
        );
        if (mounted) {
          setState(() {
            _personalInfo = loadedPersonalInfo;
            // 텍스트 필드 컨트롤러 값도 업데이트
            _jobNameController.text = loadedPersonalInfo.jobName ?? '';
            _hobbyOtherController.text = loadedPersonalInfo.hobbyOther ?? '';
            _noteController.text = loadedPersonalInfo.note ?? '';
          });
        }
      } catch (e) {
        debugPrint('⚠️ 개인맞춤입력 정보 로드 실패: $e');
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    _hobbyOtherController.dispose();
    _jobNameController.dispose();
    super.dispose();
  }

  bool _validateAllForms() {
    final dateValid = _formKeyDate.currentState?.validate() ?? false;
    final timeValid = _isTimeUnknown || (_formKeyTime.currentState?.validate() ?? false);
    final nameValid = _formKeyName.currentState?.validate() ?? false;

    if (dateValid && timeValid && nameValid) {
      _formKeyDate.currentState?.save();
      if (!_isTimeUnknown) {
        _formKeyTime.currentState?.save();
      }
      _formKeyName.currentState?.save();
      return true;
    }
    return false;
  }

  SajuInfo _createSajuInfo() {
    return SajuInfo(
      name: _nameController.text.trim(),
      relation: _gender,
      birth: DateFormat('yyyy-MM-dd').format(_selectedDate),
      element: '',
      lunar: 'false', // 양력으로 고정
      time: _isTimeUnknown ? null : _selectedTime,
    );
  }

  List<Map<String, dynamic>> _generateInputOption(SajuInfo saju) {
    return [
      {
        'name': saju.name,
        'solar_date': _isLunar,
        'gender': saju.relation,
      }
    ];
  }

  void _showConfirmDialog(String title, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _handleInquiry() {
    if (!_validateAllForms()) return;

    _showConfirmDialog('조회하시겠습니까?', () {
      final saju = _createSajuInfo();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SajuResultScreen(
            selectedTime: saju.birthDateTime,
            inputOption: _generateInputOption(saju),
            saju: saju,
          ),
        ),
      );
    });
  }

  Future<void> _handleSave() async {
    // 각 필드별로 validation 체크 및 메시지 표시
    final dateValid = _formKeyDate.currentState?.validate() ?? false;
    final nameValid = _formKeyName.currentState?.validate() ?? false;

    if (!dateValid) {
      _formKeyDate.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('날짜를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 출생 시각 validation 체크
    // "선택안함" 상태인지 확인: 모름도 아니고 시간도 선택하지 않은 경우
    final isTimeNotSelected = !_isTimeUnknown && 
                              _selectedTime == null && 
                              (_timeController.text.isEmpty || _timeController.text.trim().isEmpty);
    
    if (isTimeNotSelected) {
      // "선택안함" 상태로 저장하려고 하면 알림창 표시
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('출생 시각 선택'),
          content: const Text('출생 시각을 선택하지 않았습니다.\n"모름" 또는 시간을 선택해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return; // 저장 중단
    }
    
    // "모름" 또는 "시간 선택" 상태면 통과

    if (!nameValid) {
      _formKeyName.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 모든 validation 통과 시 저장 진행
    _formKeyDate.currentState?.save();
    if (!_isTimeUnknown) {
      _formKeyTime.currentState?.save();
    }
    _formKeyName.currentState?.save();

    _showConfirmDialog('저장하시겠습니까?', () async {
      final saju = _createSajuInfo();
      final provider = Provider.of<SajuProvider>(context, listen: false);

      try {
        // 사주 저장
        if (widget.saju != null) {
          await provider.updateItem(widget.saju!, saju);
        } else {
          await provider.add(saju);
        }

        // 개인맞춤입력 정보 저장 (사주별로 저장)
        await settingsStorage.savePersonalInfo(
          _personalInfo,
          name: saju.name,
          birth: saju.birth,
        );

        // 사주 결과 계산 및 선택된 사주로 설정
        await _calculateAndSaveSelectedSaju(saju);

        if (mounted) {
          // 저장 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사주가 저장되고 선택되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );

          // HomeScreen으로 이동 (모든 이전 화면 제거)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  /// 사주 결과 계산 및 선택된 사주로 저장
  Future<void> _calculateAndSaveSelectedSaju(SajuInfo saju) async {
    try {
      final birthDateTime = saju.birthDateTime;
      final today = DateTime.now();
      final koreanAge = (today.year - birthDateTime.year + 1).toString();

      // 간지 계산
      final yearJu = await GanjiCalculator.getYearGanji(birthDateTime);
      final wolJu = await GanjiCalculator.getWolJu(birthDateTime) ?? '';
      
      String ilJu = '';
      int retry = 0;
      while (ilJu.isEmpty && retry < 5) {
        ilJu = await GanjiCalculator.getIlJu(birthDateTime);
        if (ilJu.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        retry++;
      }
      
      final siJu = GanjiCalculator.getSiJu(birthDateTime, ilJu);

      final ganji = {
        '년주': yearJu,
        '월주': wolJu,
        '일주': ilJu,
        '시주': siJu,
      };

      // 대운 계산
      final isSunHaeng = DaewoonCalculator.isSunHaeng(
        yearJu.isNotEmpty ? yearJu.substring(0, 1) : '',
        saju.relation,
      );
      final firstLuckAge = DaewoonCalculator.calculateFirstLuckAge(birthDateTime, isSunHaeng);
      
      final daewoonList = DaewoonCalculator.generateDaewoonList(
        startGan: wolJu.isNotEmpty ? wolJu.substring(0, 1) : '',
        startJi: wolJu.length > 1 ? wolJu.substring(1) : '',
        isSunHaeng: isSunHaeng,
      );

      final currentDaewoon = DaewoonCalculator.getCurrentDaewoon(
        int.tryParse(koreanAge) ?? 0,
        firstLuckAge,
        daewoonList,
      );

      // 십성 계산
      final ilGan = ilJu.isNotEmpty ? ilJu.substring(0, 1) : '';
      final result = SipsinCalculator.getElementAndYinyang(ilGan);

      final sipseong = SipseongInfo(
        yinYang: result['음양'] ?? '',
        fiveElement: result['오행'] ?? '',
        yearGan: SipsinCalculator.getSipsin(ilGan, yearJu.isNotEmpty ? yearJu.substring(0, 1) : ''),
        yearJi: SipsinCalculator.getJiSipsin(ilGan, yearJu.length > 1 ? yearJu.substring(1) : ''),
        wolGan: SipsinCalculator.getSipsin(ilGan, wolJu.isNotEmpty ? wolJu.substring(0, 1) : ''),
        wolJi: SipsinCalculator.getJiSipsin(ilGan, wolJu.length > 1 ? wolJu.substring(1) : ''),
        ilGan: ilGan,
        ilJi: SipsinCalculator.getJiSipsin(ilGan, ilJu.length > 1 ? ilJu.substring(1) : ''),
        siGan: SipsinCalculator.getSipsin(ilGan, siJu.isNotEmpty ? siJu.substring(0, 1) : ''),
        siJi: SipsinCalculator.getJiSipsin(ilGan, siJu.length > 1 ? siJu.substring(1) : ''),
        currDaewoonGan: SipsinCalculator.getSipsin(
          ilGan,
          currentDaewoon.isNotEmpty ? currentDaewoon.substring(0, 1) : '',
        ),
        currDaewoonJi: SipsinCalculator.getJiSipsin(
          ilGan,
          currentDaewoon.length > 1 ? currentDaewoon.substring(1) : '',
        ),
      );

      final selectedData = SelectedSajuData(
        saju: saju,
        ganji: ganji,
        daewoon: daewoonList,
        koreanAge: koreanAge,
        currentDaewoon: currentDaewoon,
        sipseong: sipseong,
        firstLuckAge: firstLuckAge,
      );

      // 선택된 사주로 저장
      await sajuStorage.saveSelectedSaju(selectedData);
    } catch (e) {
      debugPrint('사주 계산 중 오류: $e');
      rethrow;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    
    // "2025-01-01" 형식
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(value);
    } catch (_) {}
    
    // "20250101" 형식
    try {
      if (value.length == 8) {
        final year = int.parse(value.substring(0, 4));
        final month = int.parse(value.substring(4, 6));
        final day = int.parse(value.substring(6, 8));
        return DateTime(year, month, day);
      }
    } catch (_) {}
    
    return null;
  }

  Future<void> _selectTime() async {
    // 모름 선택 옵션 표시
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출생 시각'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('시간 선택'),
              leading: const Icon(Icons.access_time),
              onTap: () {
                Navigator.pop(context, 'select');
              },
            ),
            ListTile(
              title: const Text('모름'),
              leading: const Icon(Icons.help_outline),
              onTap: () {
                Navigator.pop(context, 'unknown');
              },
            ),
          ],
        ),
      ),
    );

    if (result == 'select') {
      final picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );
      if (picked != null) {
        setState(() {
          _isTimeUnknown = false;
          _selectedTime = picked;
          _timeController.text = DateFormat('HH:mm').format(DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            picked.hour,
            picked.minute,
          ));
        });
      }
    } else if (result == 'unknown') {
      setState(() {
        _isTimeUnknown = true;
        _selectedTime = null;
        _timeController.text = '모름';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.saju?.isEditing ?? false;
    final isNew = widget.saju == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '사주 들화',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // 프로필 섹션
              _buildProfileSection(),
              const SizedBox(height: 32),
              // 기본 정보 섹션
              _buildSectionTitle('기본 정보 섹션'),
              const SizedBox(height: 16),
              _buildGenderSection(),
              const SizedBox(height: 32),
              // 생년월일, 출생 시각 섹션
              _buildSectionTitle('태어난날(양력)'),
              const SizedBox(height: 16),
              _buildDateTimeFields(),
              const SizedBox(height: 32),
              // 이름 입력 섹션
              _buildSectionTitle('이름'),
              const SizedBox(height: 16),
              _buildNameField(),
              const SizedBox(height: 32),
              // 개인맞춤입력 섹션
              _buildPersonalInfoSection(),
              const SizedBox(height: 40),
              // 하단 버튼
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final isNew = widget.saju == null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.yellow[600],
                child: const Icon(Icons.person, size: 30, color: Colors.black),
              ),
              const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: Icon(Icons.check_circle, color: Colors.green, size: 18),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNew ? '새 사주' : widget.saju!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('yyyy-MM-dd').format(_selectedDate)} · $_gender',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildGenderSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildOvalButton(
          '남자',
          _gender == '남자',
          () => setState(() => _gender = '남자'),
        ),
        _buildOvalButton(
          '여자',
          _gender == '여자',
          () => setState(() => _gender = '여자'),
        ),
      ],
    );
  }


  Widget _buildOvalButton(
    String text,
    bool isSelected,
    VoidCallback onTap, {
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C27B0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF9C27B0) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && !isDisabled)
              const Icon(Icons.check, color: Colors.white, size: 18),
            if (isSelected && !isDisabled) const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      children: [
        Form(
          key: _formKeyDate,
          child: TextFormField(
            controller: _dateController,
            decoration: InputDecoration(
              hintText: '생년월일 (예: 2025-01-01 또는 20250101)',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              final parsedDate = _parseDate(value);
              if (parsedDate != null) {
                setState(() {
                  _selectedDate = parsedDate;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '날짜를 입력해주세요.';
              }
              final parsedDate = _parseDate(value);
              if (parsedDate == null) {
                return '올바른 날짜 형식을 입력해주세요. (예: 2025-01-01 또는 20250101)';
              }
              if (parsedDate.isAfter(DateTime.now())) {
                return '미래 날짜는 입력할 수 없습니다.';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null) {
                final parsedDate = _parseDate(value);
                if (parsedDate != null) {
                  _selectedDate = parsedDate;
                  _dateController.text = DateFormat('yyyy-MM-dd').format(parsedDate);
                }
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKeyTime,
          child: TextFormField(
            controller: _timeController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: '출생 시각 선택 (선택안함)',
              suffixIcon: const Icon(Icons.arrow_drop_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onTap: _selectTime,
            validator: (value) {
              if (!_isTimeUnknown && (value == null || value.isEmpty || value == '모름')) {
                return '시간을 선택해주세요.';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Form(
      key: _formKeyName,
      child: TextFormField(
        controller: _nameController,
        maxLength: 50,
        decoration: InputDecoration(
          hintText: '이름을 입력하세요 (선택사항)',
          prefixIcon: const Icon(Icons.person_outline),
          suffixText: '${_nameController.text.length}/50',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '이름을 입력해주세요.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _handleSave();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              '사주 저장하고 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.star, size: 20),
          ],
        ),
      ),
    );
  }

  // ============ 개인맞춤입력 섹션 ============
  
  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '개인맞춤입력',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // A. 필수
        _buildPersonalSectionTitle('A. 필수'),
        const SizedBox(height: 12),
        _buildPersonalDropdownField(
          label: '직업 상태',
          value: _personalInfo.jobStatus,
          items: jobStatusOptions,
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(jobStatus: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPersonalTextField(
          label: '직업명 (직접 입력)',
          controller: _jobNameController,
          maxLength: 50,
          maxLines: 1,
          hintText: '예: 소프트웨어 개발자, 마케터 등',
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(jobName: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPersonalDropdownField(
          label: '혼인 상태',
          value: _personalInfo.maritalStatus,
          items: maritalStatusOptions,
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(maritalStatus: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPersonalMultiSelectChips(
          label: '현재 고민 영역',
          selectedItems: _personalInfo.concerns,
          options: concernOptions,
          onChanged: (selected) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(concerns: selected);
            });
          },
        ),
        const SizedBox(height: 24),
        // B. 권장
        _buildPersonalSectionTitle('B. 권장'),
        const SizedBox(height: 12),
        _buildPersonalDropdownField(
          label: '현재 삶의 단계',
          value: _personalInfo.lifeStage,
          items: lifeStageOptions,
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(lifeStage: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPersonalDropdownField(
          label: '재물 활동',
          value: _personalInfo.moneyActivity,
          items: moneyActivityOptions,
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(moneyActivity: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPersonalDropdownField(
          label: '연애 상태',
          value: _personalInfo.relationshipStatus,
          items: relationshipStatusOptions,
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(relationshipStatus: value);
            });
          },
        ),
        const SizedBox(height: 24),
        // C. 보조(선택)
        _buildPersonalSectionTitle('C. 보조(선택)'),
        const SizedBox(height: 12),
        _buildPersonalMultiSelectChips(
          label: '취미 성향',
          selectedItems: _personalInfo.hobbies,
          options: hobbyOptions,
          onChanged: (selected) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(hobbies: selected);
              if (!selected.contains('기타')) {
                _hobbyOtherController.clear();
                _personalInfo = _personalInfo.copyWith(hobbyOther: null);
              }
            });
          },
        ),
        if (_personalInfo.hobbies.contains('기타')) ...[
          const SizedBox(height: 12),
          _buildPersonalTextField(
            label: '기타 취미 (직접 입력)',
            controller: _hobbyOtherController,
            maxLength: 100,
            maxLines: 1,
            hintText: '취미를 입력하세요',
            onChanged: (value) {
              setState(() {
                _personalInfo = _personalInfo.copyWith(hobbyOther: value);
              });
            },
          ),
        ],
        const SizedBox(height: 12),
        _buildPersonalRadioGroup(
          label: '계획형/즉흥형',
          value: _personalInfo.planningStyle,
          options: const ['계획형', '즉흥형'],
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(planningStyle: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPersonalRadioGroup(
          label: '안정추구/변화추구',
          value: _personalInfo.stabilityPreference,
          options: const ['안정추구', '변화추구'],
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(stabilityPreference: value);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildPersonalRadioGroup(
          label: '내향/외향',
          value: _personalInfo.personalityType,
          options: const ['내향', '외향'],
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(personalityType: value);
            });
          },
        ),
        const SizedBox(height: 24),
        // D. 민감(제한 입력)
        _buildPersonalSectionTitle('D. 민감(제한 입력)'),
        const SizedBox(height: 12),
        _buildPersonalSwitchField(
          label: '건강 이슈 존재 여부',
          value: _personalInfo.hasHealthConcern,
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(hasHealthConcern: value);
            });
          },
        ),
        const SizedBox(height: 24),
        // E. 기타사항(선택)
        _buildPersonalSectionTitle('E. 기타사항(선택)'),
        const SizedBox(height: 12),
        _buildPersonalTextField(
          label: '기타 메모',
          controller: _noteController,
          maxLength: 500,
          hintText: '사주 구조를 바꾸는 근거로 쓰지 않습니다',
          onChanged: (value) {
            setState(() {
              _personalInfo = _personalInfo.copyWith(note: value);
            });
          },
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            '※ 사주 구조를 바꾸는 근거로 쓰지 않습니다',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9C27B0),
      ),
    );
  }

  Widget _buildPersonalDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          hint: const Text('선택하세요'),
        ),
      ],
    );
  }

  Widget _buildPersonalMultiSelectChips({
    required String label,
    required List<String> selectedItems,
    required List<String> options,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedItems.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<String>.from(selectedItems);
                if (selected) {
                  newList.add(option);
                } else {
                  newList.remove(option);
                }
                onChanged(newList);
              },
              selectedColor: const Color(0xFF9C27B0).withOpacity(0.2),
              checkmarkColor: const Color(0xFF9C27B0),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalRadioGroup({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            return Expanded(
              child: RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: value,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildPersonalTextField({
    required String label,
    required TextEditingController controller,
    required int maxLength,
    int maxLines = 5,
    String? hintText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
