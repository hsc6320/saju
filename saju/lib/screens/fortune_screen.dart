import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saju/api/gpt_service.dart';
import 'package:saju/models/fortune.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FortuneScreen extends StatefulWidget {
  final Fortune? currentFortune;
  final List<Fortune> allFortunes;
  FortuneScreen({super.key, required this.currentFortune, required this.allFortunes});

  
  @override
  State<FortuneScreen> createState() => FortuneScreenState();
}

class FortuneScreenState extends State<FortuneScreen> {
  Fortune? _currentFortune;
  List<Fortune> _allFortunes = [];
  String? gptResult;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadFortunes();
    print("currentFortune : ${widget.currentFortune}");
    _currentFortune = widget.currentFortune; // ✅ 이 한 줄이 필요합니다!
    _allFortunes = widget.allFortunes;       // 리스트도 같이 복사
  }

  Future<void> _loadFortunes() async {
    final String response = await rootBundle.loadString('assets/fortune_data.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _allFortunes = data.map((json) => Fortune.fromJson(json)).toList();
    });
  }

  void _pickRandomFortune() {
      print("_pickRandomFortune()222 $_currentFortune");
    if (_allFortunes.isNotEmpty) {
      print("_pickRandomFortune()");
      final random = Random();
      setState(() {
        _currentFortune = _allFortunes[random.nextInt(_allFortunes.length)];
        gptResult = null;
      });
    }
  }
  Future<void> _getGPTInterpretation() async {
    print('해석 보기... $_currentFortune');
    if (_currentFortune == null) return;

    await dotenv.load(fileName: ".env");

    print("🔑 API KEY: ${dotenv.env['OPENAI_API_KEY']}");
    setState(() => loading = true);

    final result = await GPTService.getFortuneInterpretation(
      _currentFortune!.guaName,
      _currentFortune!.poem,
      dotenv.env['OPENAI_API_KEY']!,
    );

    if (result != null) {
      print("✅ GPT 응답 결과:\n$result");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_gpt_result", result);
    }

    setState(() {
      gptResult = result;
      loading = false;
    });
  }

  
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("운세 보기")),
      body : Padding (
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: SingleChildScrollView(
          child : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentFortune!.guaName ?? "안녕하세요", 
                style: Theme.of(context).textTheme.headlineSmall
              ),
              const SizedBox(height: 10),
              Text("시:", style: Theme.of(context).textTheme.titleMedium),
              Text(_currentFortune!.poem ?? "기다려주세요"),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: loading ? null : _getGPTInterpretation,
                icon: const Icon(Icons.auto_fix_high),
                label: Text(loading ? "해석 중..." : "AI 해석 보기"),
              ),
              const SizedBox(height: 16),
              if (gptResult != null) ...[
                Text("해석", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  gptResult!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              //const Spacer(),
               const SizedBox(height: 40), // Spacer 대신 공간 확보
              Center(
                child: TextButton(
                //  onPressed: _pickRandomFortune,
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final saved = prefs.getString("last_gpt_result");

                    setState(() {
                      gptResult = saved ?? "저장된 해석 결과가 없습니다.";
                    });
                  },
                  child: const Text("다시 보기"),
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}