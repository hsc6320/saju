import 'package:flutter/material.dart';
import 'package:saju/SharedPreferences.dart';

class SajuChatScreen extends StatefulWidget {
  final SajuInfo saju;
  final Map<String, String?> sajuganji;
  final List<String> daewoon;

  const SajuChatScreen({Key? key, required this.saju, required this.sajuganji, required this.daewoon}) : super(key: key);

  @override
  State<SajuChatScreen> createState() => _SajuChatScreenState();
}

class _SajuChatScreenState extends State<SajuChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      // 나중에 여기에 GPT 응답 추가
      _messages.add({'role': 'gpt', 'content': 'GPT 응답 예시입니다.'});
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    print("넘겨받은 사주: ${widget.saju.name}");
    print("넘겨받은 대운 : ${widget.daewoon}");
    print("간지 정보: ${widget.sajuganji}"); // 예: {"년주": "임인", ...}
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.saju.name}님의 사주 대화'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '질문을 입력하세요...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: Text('전송'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
