import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:saju/SajuProvider.dart';
import 'package:saju/SharedPreferences.dart';
import 'package:saju/screens/saju_list_screen.dart';
//import 'package:saju/screens/saju_list_screen.dart';
import 'package:saju/screens/saju_result_screen.dart';

class SajuInputScreen extends StatefulWidget {
  final SajuInfo? saju;
  const SajuInputScreen({super.key, this.saju});

  @override
  State<SajuInputScreen> createState() => _SajuInputScreenState();
}

class _SajuInputScreenState extends State<SajuInputScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String name = "";

  bool isLunar = false;
  String gender = '남자';

  final _formKeyDate = GlobalKey<FormState>();
  final _formKeyTime = GlobalKey<FormState>();
  final _formKeyName = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _dateTimeController;
  late TextEditingController _nameController;
  
  String inputDate = '';
  String inputTime = '';
  String inputName = '';

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
     text: widget.saju != null
      ? DateFormat('yyyy-MM-dd').format(widget.saju!.birthDateTime)
      : '',
    );

    _dateTimeController = TextEditingController(
     //text: '${DateFormat('HH:mm').format(dateTime)} (태어난 시간)',
      text: widget.saju != null
      ? DateFormat('HH:mm').format(widget.saju!.birthDateTime)
      : '', // 신규 입력이면 빈 값
    );

    _nameController = TextEditingController(
      text: widget.saju != null 
      ? widget.saju!.name
      : '',
    );
    
    if(widget.saju != null) {
      print('widget.saju!.lunar : ${widget.saju!.lunar}');
      if(widget.saju!.lunar != 'true')
        isLunar = false;
      else
        isLunar = true;
    }

    widget.saju != null ? gender = widget.saju!.relation : gender='남자';
    //widget.saju != null ? isLunar = blunar: isLunar = blunar;
  }
  SajuInfo copyWith({
  String? name,
  String? relation,
  String? birth,
  String? element,
  String? isLunar,
  TimeOfDay? time,
  bool? isFavorite,
  bool? isEditing,
  }) {
    return SajuInfo(
      name: name ?? this.name,
      relation: relation ?? widget.saju!.relation,
      birth: birth ?? widget.saju!.birth,//this.birth,
      element: element ?? widget.saju!.element,//this.element,
      lunar: isLunar ?? widget.saju!.lunar,//this.isLunar,
      time: time ?? widget.saju!.time,//this.time,
      isFavorite: isFavorite ?? widget.saju!.isFavorite,//this.isFavorite,
      isEditing: isEditing ?? widget.saju!.isEditing,//this.isEditing,
    );
  }
  bool validateAndSaveForms(GlobalKey<FormState> dateKey, GlobalKey<FormState> timeKey, GlobalKey<FormState> nameKey) {
    final dateForm = dateKey.currentState;
    final timeForm = timeKey.currentState;
    final nameForm = nameKey.currentState;

    if (dateForm != null && timeForm != null && nameForm != null) {
      final isValid = dateForm.validate() && timeForm.validate() && nameForm.validate();
      if (isValid) {
        dateForm.save();
        timeForm.save();
        nameForm.save();
        return true;
      }
    }
    return false;
  }


  void _showConfirmDialog(String title, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(onPressed: () {
            Navigator.pop(context);
            onConfirm();
          }, child: const Text("확인")),
        ],
      ),
    );
  }
  Future<void> navigateToListScreen(
    BuildContext context,
    SajuInfo saju,
    bool isLunar,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SajuListScreen(
          selectedTime: saju.birthDateTime,
          inputOption: [
            {
              "name": saju.name,
              "solar_date": isLunar,
              "gender": saju.relation,
            }
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF3EA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '사주 입력',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // 음력/양력 토글
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleButton("양력", !isLunar, () => setState(() => isLunar = false)),
                  const SizedBox(width: 12),
                  _buildToggleButton("음력", isLunar, () => setState(() => isLunar = true)),
                  
                  const SizedBox(width: 30),
                      
                  _buildToggleButton("남자", gender == "남자", () => setState(() => gender = "남자")),
                  const SizedBox(width: 12),
                  _buildToggleButton("여자", gender == "여자", () => setState(() => gender = "여자")),
                ],
              ),
              const SizedBox(height: 30),
              // 이름 입력
              Row(
                children: [
                  Expanded(
                    child : Form (
                      key: _formKeyName,
                      child : Builder (
                        builder : (formContext) =>Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            style : TextStyle(fontSize : 25),
                            decoration: InputDecoration(
                              hintText: '이름 입력',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return '이름을 입력해주세요.';
                              return null;
                            },
                            onFieldSubmitted: (_) => _formKeyName.currentState?.validate(),

                            onSaved: (newValue) {
                              inputName = newValue!;
                              print('name : $inputName'); 
                            },
                          ),
                        ],
                      ),
                    ),
                    )
                  ),
                  const SizedBox(width: 12),
                //  OutlinedButton(onPressed: _pickDate, child: const Text("날짜 선택"))
                ],
              ),
              const SizedBox(height: 16),
              // 생년월일 입력
              Row(
                children: [
                  Expanded(
                    child : Form (
                      key: _formKeyDate,
                      child : Builder (
                        builder : (formContext) =>Column(
                        children: [
                          TextFormField(
                            controller: _dateController,
                            textInputAction: TextInputAction.next,
                            style : TextStyle(fontSize : 25),
                            decoration: InputDecoration(
                              hintText: '${DateFormat('yyyy-MM-dd').format(selectedDate)} (생년월일 입력)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return '날짜를 입력해주세요.';
                              final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                              if (!regex.hasMatch(value)) {
                                return '형식이 잘못되었습니다. 예: 1995-07-20';
                              }
                              try {
                                DateFormat('yyyy-MM-dd').parseStrict(value);
                                return null;
                              } catch (_) {
                                return '날짜 형식이 올바르지 않아요. 예: 1995-07-20';
                              }
                            },
                            onFieldSubmitted: (_) => _formKeyDate.currentState?.validate(),

                            onSaved: (newValue) {
                              inputDate = newValue!;
                              selectedDate = DateTime.parse(inputDate);
                              print('birthDateTime : $selectedDate'); 
                            },
                          ),
                        ],
                      ),
                    ),
                    )
                  ),
                  const SizedBox(width: 12),
                //  OutlinedButton(onPressed: _pickDate, child: const Text("날짜 선택"))
                ],
              ),
              const SizedBox(height: 16),

              // 출생시간 입력
              Row(
                  children: [
                  Expanded(
                    child: Form(
                      key: _formKeyTime,
                      child: Builder(
                        builder: (formContext) => Column(
                          children: [
                            TextFormField(
                              controller: _dateTimeController,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(fontSize: 25),
                              decoration: InputDecoration(
                                hintText: '시:분 (태어난시간)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '날짜와 시간을 입력해주세요.';
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
                              onFieldSubmitted: (_) => _formKeyTime.currentState?.validate(),
                              onSaved: (newValue) {
                                final parts = newValue!.split(':');
                                final hour = int.parse(parts[0]);
                                final minute = int.parse(parts[1]);
                                selectedTime = TimeOfDay(hour: hour, minute: minute);
                                print('생성된 시간 : $selectedTime');

                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                //  OutlinedButton(onPressed: _pickDate, child: const Text("날짜 선택"))
                ],
              ),
              const SizedBox(height: 24),
              const Spacer(),
              Row(
                children: [
                  if (!(widget.saju?.isEditing ?? false)) // 신규 입력일 때만
                   /* if (widget.saju != null) {
                      isEditing = widget.saju!.isEditing;
                    }*/
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (validateAndSaveForms(_formKeyDate, _formKeyTime, _formKeyName)) {
                          print("✅ inputDate : $inputDate");
                          print("✅ inputTime : ${selectedTime.hour} ${selectedTime.minute}");
                          print("✅ inputName : $inputName");

                          _showConfirmDialog("조회하시겠습니까?", () {
                            DateTime birthDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );

                            final SajuInfo tempSaju = SajuInfo(
                              name: inputName,
                              relation: gender,
                              birth: "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                              element: '', // 아직 미정이면 빈 문자열 처리
                              lunar: isLunar.toString(),
                              time: selectedTime,
                            );
                            print("tempSaju name : ${tempSaju.name}, birth : ${tempSaju.birth}");

                            List<Map<String, dynamic>> generateSolarTermsForYear (String name, String gender, bool isLunar) {
                              return [
                                {
                                  "name": name,
                                  "solar_date": isLunar,
                                  "gender": gender,
                                }
                              ];
                            }
                            print("현재 날짜 ${selectedDate.year},${selectedDate.month},${selectedDate.day},${selectedTime.hour},${selectedTime.minute},");
                            //isLunar = false (양력), isLunar = true (음력)
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SajuResultScreen(
                                          selectedTime: birthDateTime, 
                                          inputOption: generateSolarTermsForYear(inputName, gender, isLunar), saju: tempSaju,)),
                            );
                          });
                        } else {
                          print("❌ 유효성 검사 실패");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA88EDB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("조회하기", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (validateAndSaveForms(_formKeyDate, _formKeyTime, _formKeyName)) {
                          print("✅ inputDate : $inputDate");
                          print("✅ inputTime : ${selectedTime.hour} ${selectedTime.minute}");
                          print("✅ inputName : $inputName");
                      
                          _showConfirmDialog("저장하시겠습니까?", () async {
                             /* await saveUserDataAndNavigate(
                                context: context,
                                selectedDate: selectedDate,
                                selectedTime: selectedTime,
                                isLunar: isLunar,
                                inputName: inputName,
                                gender: gender,
                                originalSaju: widget.saju, // 🔥 수정 시 이전 사주 전달
                              );*/
                              final saju = SajuInfo(
                                name: inputName,
                                relation: gender,
                                birth: selectedDate.toIso8601String().split('T')[0],
                                element: '', // 오행 나중에 계산
                                lunar: isLunar.toString(),
                                time: selectedTime,
                              );

                              print("sjau  null ?name : ${saju.name} birth: ${saju.birth},  time : ${saju.time} ");
                              final provider = Provider.of<SajuProvider>(context, listen: false);
                              if (widget.saju != null) {
                                provider.updateItem(widget.saju!, saju);
                                
                              } else {
                                print("widget.saju : ${widget.saju}, saju : $saju");
                                provider.add(saju);
                              }
                              await navigateToListScreen(context, saju, isLunar);
                          });
                        } else {
                          print("❌ 유효성 검사 실패");
                        }

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFECECEC),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("저장하기", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
}
