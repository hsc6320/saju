import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../api/gpt_service.dart';
import '../models/fortune.dart';
import '../models/saju_info.dart';
import '../SajuProvider.dart';
import '../models/selected_saju_data.dart';
import '../services/saju_storage_service.dart';

/// 사주 AI 채팅 화면
class SajuChatScreen extends StatefulWidget {
  final SajuInfo saju;
  final String? currentDaewoon;
  final Map<String, String?> sajuganji;
  final List<String> daewoon;
  final String? yinYang;
  final String? fiveElement;
  final String? yearGan;
  final String? yearJi;
  final String? wolGan;
  final String? wolJi;
  final String? ilGan;
  final String? ilJi;
  final String? siGan;
  final String? siJi;
  final String? currDaewoonGan;
  final String? currDaewoonJi;
  final int firstLuckAge;  // 초대운 나이
  final String appUid;     // 앱 UID (로그인 ID)

  const SajuChatScreen({
    Key? key,
    required this.saju,
    required this.sajuganji,
    required this.daewoon,
    required this.currentDaewoon,
    required this.yinYang,
    required this.fiveElement,
    required this.yearGan,
    required this.yearJi,
    required this.wolGan,
    required this.wolJi,
    required this.ilGan,
    required this.ilJi,
    required this.siGan,
    required this.siJi,
    required this.currDaewoonGan,
    required this.currDaewoonJi,
    required this.firstLuckAge,
    required this.appUid,
  }) : super(key: key);

  @override
  State<SajuChatScreen> createState() => _SajuChatScreenState();
}

class _SajuChatScreenState extends State<SajuChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  String selectedModel = 'gpt-3.5-turbo';
  bool _isLoading = false;
  bool _isLoadingHistory = true; // 대화 내용 불러오기 중인지 여부
  SajuInfo? _selectedSajuForList; // 좌측 목록에서 선택된 사주

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// GCS에서 대화 내용 불러오기
  Future<void> _loadChatHistory() async {
    try {
      setState(() {
        _isLoadingHistory = true;
      });

      final messages = await GPTService.loadChatHistory(
        widget.appUid,
        widget.saju.name,
        widget.saju.birth,
      );

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoadingHistory = false;
        });
        
        // 대화 내용을 불러온 후 스크롤을 맨 아래로
        if (_messages.isNotEmpty) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        debugPrint('대화 내용 불러오기 실패: $e');
      }
    }
  }

  /// 메시지 전송
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final allMessages = buildFortuneMessages(
      question: text,
      currentDaewoon: widget.currentDaewoon,
      daewoon: widget.daewoon,
      saju: widget.saju,
      sajuganji: widget.sajuganji,
    );

    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      _addErrorMessage('API 키가 설정되지 않았습니다.');
      return;
    }

    try {
      final reply = await GPTService.getFortuneInterpretation(
        widget.saju,
        widget.currentDaewoon,
        widget.sajuganji,
        widget.daewoon,
        allMessages,
        widget.yinYang,
        widget.fiveElement,
        widget.yearGan,
        widget.yearJi,
        widget.wolGan,
        widget.wolJi,
        widget.ilGan,
        widget.ilJi,
        widget.siGan,
        widget.siJi,
        widget.currDaewoonGan,
        widget.currDaewoonJi,
        apiKey,
        selectedModel,
        'saju',
        widget.firstLuckAge,
        widget.appUid,
      );

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      _addErrorMessage('GPT 요청 실패: $e');
    }
  }

  void _addErrorMessage(String message) {
    setState(() {
      _messages.add({'role': 'assistant', 'content': message});
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.saju.name}님의 사주 대화'),
      ),
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
                  child: _buildSajuListPanel(),
                ),
                // 구분선
                Container(width: 1, color: Colors.grey.shade300),
                // 우측: 채팅 대화창
                Expanded(
                  child: _buildChatPanel(),
                ),
              ],
            );
          } else {
            // 작은 화면: 기존 레이아웃
            return _buildChatPanel();
          }
        },
      ),
    );
  }

  Widget _buildChatPanel() {
    return _isLoadingHistory
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return _buildLoadingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          );
  }

  Widget _buildSajuListPanel() {
    final sajuProvider = Provider.of<SajuProvider>(context);
    final sajuList = sajuProvider.sajuList;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const Icon(Icons.list, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                '사주 목록',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: sajuList.isEmpty
              ? const Center(
                  child: Text('등록된 사주가 없습니다', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: sajuList.length,
                  itemBuilder: (context, index) {
                    final saju = sajuList[index];
                    final isSelected = _selectedSajuForList?.name == saju.name &&
                        _selectedSajuForList?.birth == saju.birth;
                    
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.indigo.shade50,
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(
                          saju.relation == '남자' ? Icons.man : Icons.woman,
                          color: isSelected ? Colors.indigo : Colors.black87,
                        ),
                      ),
                      title: Text(
                        saju.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('${saju.birth} (${saju.relation})'),
                      onTap: () {
                        setState(() {
                          _selectedSajuForList = saju;
                        });
                        // 선택된 사주로 채팅 전환
                        _switchToSajuChat(saju);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _switchToSajuChat(SajuInfo saju) async {
    // 선택된 사주로 채팅 화면 이동
    final selectedData = await sajuStorage.loadSelectedSaju();
    
    // 선택된 사주와 일치하는 데이터가 있으면 해당 데이터 사용
    if (selectedData.saju?.name == saju.name && selectedData.saju?.birth == saju.birth) {
      // 현재 화면을 새로운 사주로 전환
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SajuChatScreen(
            saju: saju,
            sajuganji: selectedData.ganji,
            daewoon: selectedData.daewoon,
            currentDaewoon: selectedData.currentDaewoon,
            yinYang: selectedData.sipseong.yinYang,
            fiveElement: selectedData.sipseong.fiveElement,
            yearGan: selectedData.sipseong.yearGan,
            yearJi: selectedData.sipseong.yearJi,
            wolGan: selectedData.sipseong.wolGan,
            wolJi: selectedData.sipseong.wolJi,
            ilGan: selectedData.sipseong.ilGan,
            ilJi: selectedData.sipseong.ilJi,
            siGan: selectedData.sipseong.siGan,
            siJi: selectedData.sipseong.siJi,
            currDaewoonGan: selectedData.sipseong.currDaewoonGan,
            currDaewoonJi: selectedData.sipseong.currDaewoonJi,
            firstLuckAge: selectedData.firstLuckAge,
            appUid: widget.appUid,
          ),
        ),
      );
    } else {
      // 선택된 데이터가 없으면 사주 목록 화면으로 이동하여 선택하도록
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 사주 목록에서 해당 사주를 선택해주세요')),
      );
    }
  }


  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * 0.75;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: maxBubbleWidth,
            ),
            decoration: BoxDecoration(
              color: isUser ? Colors.indigo[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message['content'] ?? '',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('답변 중...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '질문을 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('전송'),
            ),
          ],
        ),
      ),
    );
  }
}
