import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../SajuProvider.dart';
import '../models/saju_info.dart';
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
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isLunar = false;
  String _gender = '남자';

  final _formKeyDate = GlobalKey<FormState>();
  final _formKeyTime = GlobalKey<FormState>();
  final _formKeyName = GlobalKey<FormState>();
  
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _nameController;

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
          : '',
    );

    _timeController = TextEditingController(
      text: widget.saju != null
          ? DateFormat('HH:mm').format(widget.saju!.birthDateTime)
          : '',
    );

    _nameController = TextEditingController(
      text: widget.saju?.name ?? '',
    );
  }

  void _initializeFromExisting() {
    if (widget.saju != null) {
      _isLunar = widget.saju!.lunar == 'true';
      _gender = widget.saju!.relation;
      _selectedDate = widget.saju!.birthDateTime;
      _selectedTime = widget.saju!.time;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _validateAllForms() {
    final dateValid = _formKeyDate.currentState?.validate() ?? false;
    final timeValid = _formKeyTime.currentState?.validate() ?? false;
    final nameValid = _formKeyName.currentState?.validate() ?? false;

    if (dateValid && timeValid && nameValid) {
      _formKeyDate.currentState?.save();
      _formKeyTime.currentState?.save();
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
      lunar: _isLunar.toString(),
      time: _selectedTime,
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
    if (!_validateAllForms()) return;

    _showConfirmDialog('저장하시겠습니까?', () async {
      final saju = _createSajuInfo();
      final provider = Provider.of<SajuProvider>(context, listen: false);

      if (widget.saju != null) {
        await provider.updateItem(widget.saju!, saju);
      } else {
        await provider.add(saju);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SajuListScreen(
              selectedTime: saju.birthDateTime,
              inputOption: _generateInputOption(saju),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.saju?.isEditing ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF3EA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEditing ? '사주 수정' : '사주 입력',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 700 ? 700.0 : constraints.maxWidth;
            
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      _buildToggleRow(),
                      const SizedBox(height: 30),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildTimeField(),
                      const SizedBox(height: 24),
                      const Spacer(),
                      _buildActionButtons(isEditing),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton('양력', !_isLunar, () => setState(() => _isLunar = false)),
        const SizedBox(width: 12),
        _buildToggleButton('음력', _isLunar, () => setState(() => _isLunar = true)),
        const SizedBox(width: 30),
        _buildToggleButton('남자', _gender == '남자', () => setState(() => _gender = '남자')),
        const SizedBox(width: 12),
        _buildToggleButton('여자', _gender == '여자', () => setState(() => _gender = '여자')),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9E0F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? const Color(0xFFA88EDB) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? const Color(0xFF5B4A87) : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Form(
      key: _formKeyName,
      child: TextFormField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 25),
        decoration: InputDecoration(
          hintText: '이름 입력',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '이름을 입력해주세요.';
          return null;
        },
      ),
    );
  }

  Widget _buildDateField() {
    return Form(
      key: _formKeyDate,
      child: TextFormField(
        controller: _dateController,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 25),
        decoration: InputDecoration(
          hintText: '${DateFormat('yyyy-MM-dd').format(_selectedDate)} (생년월일 입력)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '날짜를 입력해주세요.';
          final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
          if (!regex.hasMatch(value)) return '형식이 잘못되었습니다. 예: 1995-07-20';
          try {
            DateFormat('yyyy-MM-dd').parseStrict(value);
            return null;
          } catch (_) {
            return '날짜 형식이 올바르지 않아요. 예: 1995-07-20';
          }
        },
        onSaved: (value) {
          if (value != null && value.isNotEmpty) {
            _selectedDate = DateTime.parse(value);
          }
        },
      ),
    );
  }

  Widget _buildTimeField() {
    return Form(
      key: _formKeyTime,
      child: TextFormField(
        controller: _timeController,
        textInputAction: TextInputAction.done,
        style: const TextStyle(fontSize: 25),
        decoration: InputDecoration(
          hintText: '시:분 (태어난 시간)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '시간을 입력해주세요.';
          final regex = RegExp(r'^\d{2}:\d{2}$');
          if (!regex.hasMatch(value)) return '형식이 잘못되었습니다. 예: 08:45';
          try {
            final parts = value.split(':');
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            if (hour > 23 || minute > 59) return '올바른 시간이 아닙니다.';
            return null;
          } catch (_) {
            return '시간 파싱 실패';
          }
        },
        onSaved: (value) {
          if (value != null && value.isNotEmpty) {
            final parts = value.split(':');
            _selectedTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        },
      ),
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    return Row(
      children: [
        if (!isEditing)
          Expanded(
            child: ElevatedButton(
              onPressed: _handleInquiry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA88EDB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('조회하기', style: TextStyle(fontSize: 16)),
            ),
          ),
        if (!isEditing) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEditing ? const Color(0xFFA88EDB) : const Color(0xFFECECEC),
              foregroundColor: isEditing ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(isEditing ? '수정하기' : '저장하기', style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
