import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/saju_info.dart';
import '../models/personal_info.dart';
import '../services/settings_storage_service.dart';

/// GPT API 호출 서비스
class GPTService {
  static const String _apiUrl = 'https://ask-saju-42xetdarfa-uc.a.run.app';

  // ✅ 일간 간지 추출 헬퍼 함수
  static String? _extractIlGanFromSajuganji(Map<String, String?> sajuganji) {
    final ilJu = sajuganji['일주'];
    if (ilJu != null && ilJu.isNotEmpty) {
      return ilJu.substring(0, 1);  // 일주에서 첫 글자(천간) 추출
    }
    return null;
  }

  /// GCS에서 대화 내용 불러오기
  /// app_uid, name, birth를 기반으로 저장된 대화 내용을 불러옵니다.
  static Future<List<Map<String, String>>> loadChatHistory(
    String appUid,
    String name,
    String birth, {
    String? sessionId,
  }) async {
    try {
      // ✅ 서버 API 엔드포인트 (POST 요청으로 변경)
      final url = Uri.parse(_apiUrl);

      // ✅ 서버가 기대하는 형식으로 요청 본문 구성
      final requestData = {
        'fetch_history': 'true',  // 서버에서 히스토리만 요청하는 경우로 인식
        'name': name,
        'birth': birth,
        'app_uid': appUid,
        'session_id': sessionId ?? 'single_global_session',
      };

      final headers = {
        'Content-Type': 'application/json; charset=utf-8',  // ✅ charset 추가
      };

      final body = jsonEncode(requestData);

      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 📥 대화 내용 불러오기 요청');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ 🌐 URL: $url');
      debugPrint('║ 📤 요청 본문: $body');
      debugPrint('║ 👤 사용자 정보');
      debugPrint('║    - app_uid: $appUid');
      debugPrint('║    - name: $name');
      debugPrint('║    - birth: $birth');
      debugPrint('║    - session_id: ${sessionId ?? 'single_global_session'}');
      debugPrint('╚══════════════════════════════════════════════════════════════');
      debugPrint('');

      // ✅ POST 요청으로 변경
      final response = await http.post(url, headers: headers, body: body);

      debugPrint('📥 응답 상태: ${response.statusCode}');
      debugPrint('📥 응답 본문: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        
        // ✅ 서버 응답 형식에 맞게 수정
        // 서버 응답 형식: {'user_id': '...', 'session_id': '...', 'turns': [...], 'meta': {...}}
        if (jsonResponse['turns'] != null && jsonResponse['turns'] is List) {
          final turns = jsonResponse['turns'] as List;
          
          // turns를 messages 형식으로 변환
          final messages = turns.map((turn) {
            final role = turn['role']?.toString() ?? 'user';
            final text = turn['text']?.toString() ?? '';
            return {
              'role': role,
              'content': text,
            };
          }).toList().cast<Map<String, String>>();
          
          debugPrint('✅ 대화 내용 불러오기 성공: ${messages.length}개 턴');
          debugPrint('   - user_id: ${jsonResponse['user_id']}');
          debugPrint('   - session_id: ${jsonResponse['session_id']}');
          debugPrint('   - path: ${jsonResponse['path'] ?? 'unknown'}');
          return messages;
        } else {
          debugPrint('⚠️ 대화 내용이 없거나 형식이 올바르지 않습니다.');
          debugPrint('   응답 구조: ${jsonResponse.keys}');
          return [];
        }
      } else if (response.statusCode == 404) {
        // 대화 내용이 없는 경우 (첫 대화)
        debugPrint('ℹ️ 저장된 대화 내용이 없습니다. (첫 대화)');
        return [];
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        debugPrint('❌ 대화 내용 불러오기 실패: ${response.statusCode}');
        debugPrint('   응답: $decodedBody');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 대화 내용 불러오기 중 오류 발생: $e');
      debugPrint('   스택 트레이스: $stackTrace');
      // 오류 발생 시 빈 리스트 반환 (앱이 계속 동작하도록)
      return [];
    }
  }

  /// 운세 해석 요청
  static Future<String> getFortuneInterpretation(
    SajuInfo saju,
    String? currentDaewoon,
    Map<String, String?> sajuganji,
    List<String> daewoon,
    List<Map<String, String>> messages,
    String? yinYang,
    String? fiveElement,
    String? yearGan,
    String? yearJi,
    String? wolGan,
    String? wolJi,
    String? ilGan,
    String? ilJi,
    String? siGan,
    String? siJi,
    String? currDaewoonGan,
    String? currDaewoonJi,
    String apiKey,
    String model,
    String mode,
    int firstLuckAge,
    String appUid,
  ) async {
    final url = Uri.parse(_apiUrl);

    final systemMessage = messages.firstWhere(
      (m) => m['role'] == 'system',
      orElse: () => {'content': ''},
    );

    final userMessage = messages.firstWhere(
      (m) => m['role'] == 'user',
      orElse: () => {'content': ''},
    );

    final headers = {
      'Content-Type': 'application/json',
    };

    // ✅ 일간 간지 검증 및 추출 (일주에서 추출)
    final extractedIlGan = GPTService._extractIlGanFromSajuganji(sajuganji);
    final validIlGan = (ilGan != null && 
                       ilGan.isNotEmpty && 
                       ilGan != '일간' && 
                       ilGan.length == 1) 
                       ? ilGan 
                       : (extractedIlGan ?? '');

    // ✅ sipseong_info 객체 생성 (서버가 기대하는 형식)
    final sipseongInfo = {
      'yinYang': yinYang,
      'fiveElement': fiveElement,
      'yearGan': yearGan,
      'yearJi': yearJi,
      'wolGan': wolGan,
      'wolJi': wolJi,
      'ilGan': validIlGan,  // ✅ 실제 일간 간지 (예: "辛") - 일주에서 추출한 값 사용
      'ilJi': ilJi,
      'siGan': siGan,
      'siJi': siJi,
      'currDaewoonGan': currDaewoonGan,
      'currDaewoonJi': currDaewoonJi,
    };

    // 개인맞춤입력 정보 로드 (입력된 항목만 전달)
    PersonalInfo? personalInfo;
    Map<String, dynamic>? personalInfoJson;
    try {
      personalInfo = await settingsStorage.loadPersonalInfo();
      if (personalInfo != null) {
        personalInfoJson = personalInfo.toServerJson();
        debugPrint('✅ 개인맞춤입력 정보 로드 완료: ${personalInfoJson.isNotEmpty ? "입력된 항목 있음" : "입력된 항목 없음"}');
      } else {
        debugPrint('✅ 개인맞춤입력 정보: 없음 (미설정)');
      }
    } catch (e) {
      debugPrint('⚠️ 개인맞춤입력 정보 로드 실패: $e');
    }

    final requestData = {
      'question': userMessage['content'],
      'sajuganji': sajuganji,
      'name': saju.name,
      'daewoon': daewoon,
      'currentDaewoon': currentDaewoon,
      'sipseong_info': sipseongInfo,  // ✅ sipseong_info 객체 전송
      // 개별 필드도 유지 (하위 호환성)
      'yinYang': yinYang,
      'fiveElement': fiveElement,
      'yearGan': yearGan,
      'yearJi': yearJi,
      'wolGan': wolGan,
      'wolJi': wolJi,
      'ilGan': validIlGan,  // ✅ 검증된 일간 간지 사용
      'ilJi': ilJi,
      'siGan': siGan,
      'siJi': siJi,
      'currDaewoonGan': currDaewoonGan,
      'currDaewoonJi': currDaewoonJi,
      'system_prompt': systemMessage['content'],
      'mode': mode,
      'firstLuckAge': firstLuckAge,
      'birth': saju.birth,
      'app_uid': appUid,
      // 개인맞춤입력 정보 (입력된 항목이 있을 때만 전달)
      if (personalInfoJson != null && personalInfoJson.isNotEmpty) 
        'personal_info': personalInfoJson,
    };

    final body = jsonEncode(requestData);

    // 🔥 서버 전송 데이터 로그 출력
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 📤 서버 전송 데이터 (SajuApp_Server)');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 🌐 URL: $_apiUrl');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 👤 사용자 정보');
    debugPrint('║    - name: ${saju.name}');
    debugPrint('║    - birth: ${saju.birth}');
    debugPrint('║    - app_uid: $appUid');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 🔮 사주 원국 (sajuganji)');
    debugPrint('║    - 년주: ${sajuganji['년주']}');
    debugPrint('║    - 월주: ${sajuganji['월주']}');
    debugPrint('║    - 일주: ${sajuganji['일주']}');
    debugPrint('║    - 시주: ${sajuganji['시주']}');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 🌊 대운 정보');
    debugPrint('║    - currentDaewoon: $currentDaewoon');
    debugPrint('║    - firstLuckAge: $firstLuckAge');
    debugPrint('║    - daewoon: $daewoon');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ ⚖️ 십성 정보');
    debugPrint('║    - yinYang: $yinYang');
    debugPrint('║    - fiveElement: $fiveElement');
    debugPrint('║    - 년간/년지: $yearGan / $yearJi');
    debugPrint('║    - 월간/월지: $wolGan / $wolJi');
    debugPrint('║    - 일간/일지: $validIlGan / $ilJi (✅ 일간 검증 완료: ${validIlGan.isNotEmpty ? "정상" : "누락"})');
    debugPrint('║    - 시간/시지: $siGan / $siJi');
    debugPrint('║    - 대운간/대운지: $currDaewoonGan / $currDaewoonJi');
    debugPrint('║    - sipseong_info 객체: ${jsonEncode(sipseongInfo)}');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ ❓ 질문: ${userMessage['content']}');
    debugPrint('║ 🎯 mode: $mode');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    if (personalInfoJson != null && personalInfoJson.isNotEmpty) {
      debugPrint('║ 👤 개인맞춤입력 정보 (입력된 항목만) - ✅ 서버 전송됨');
      debugPrint('║    ${jsonEncode(personalInfoJson)}');
    } else {
      debugPrint('║ 👤 개인맞춤입력 정보: 없음 (입력된 항목 없음 또는 미설정) - ❌ 서버 전송 안됨');
    }
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 📦 서버 전송 요청 본문 (requestData)에 personal_info 포함 여부:');
    debugPrint('║    ${requestData.containsKey('personal_info') ? "✅ 포함됨" : "❌ 포함 안됨"}');
    if (requestData.containsKey('personal_info')) {
      debugPrint('║    personal_info 내용: ${jsonEncode(requestData['personal_info'])}');
    }
    debugPrint('╚══════════════════════════════════════════════════════════════');
    debugPrint('');

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final json = jsonDecode(decodedBody);
        return json['answer'] ?? 'GPT 응답이 비었습니다.';
      } else {
        throw Exception('GPT 요청 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('GPT 요청 중 오류 발생: $e');
    }
  }

  /// 서버에서 대화 내용 삭제
  /// app_uid, name, birth를 기반으로 저장된 대화 내용을 삭제합니다.
  static Future<bool> deleteChatHistory(
    String appUid,
    String name,
    String birth, {
    String? sessionId,
  }) async {
    try {
      final url = Uri.parse(_apiUrl);

      // 서버가 기대하는 형식으로 요청 본문 구성
      final requestData = {
        'delete_history': 'true',  // 대화 내용 삭제 요청
        'name': name,
        'birth': birth,
        'app_uid': appUid,
        'session_id': sessionId ?? 'single_global_session',
      };

      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
      };

      final body = jsonEncode(requestData);

      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 🗑️ 대화 내용 삭제 요청');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ 🌐 URL: $url');
      debugPrint('║ 📤 요청 본문: $body');
      debugPrint('║ 👤 사용자 정보');
      debugPrint('║    - app_uid: $appUid');
      debugPrint('║    - name: $name');
      debugPrint('║    - birth: $birth');
      debugPrint('║    - session_id: ${sessionId ?? 'single_global_session'}');
      debugPrint('╚══════════════════════════════════════════════════════════════');
      debugPrint('');

      final response = await http.post(url, headers: headers, body: body);

      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('📥 응답 상태: ${response.statusCode}');
      debugPrint('📥 응답 본문: ${decodedBody.length > 500 ? decodedBody.substring(0, 500) + "..." : decodedBody}');

      if (response.statusCode == 200) {
        // 응답 본문 확인
        try {
          final jsonResponse = jsonDecode(decodedBody);
          final success = jsonResponse['success'] ?? jsonResponse['deleted'] ?? true;
          if (success == true || success == 'true') {
            debugPrint('✅ 대화 내용 삭제 성공');
            return true;
          } else {
            debugPrint('⚠️ 서버에서 삭제 실패 응답: $jsonResponse');
            return false;
          }
        } catch (e) {
          // JSON 파싱 실패 시 상태 코드만으로 판단
          debugPrint('✅ 대화 내용 삭제 성공 (상태 코드: 200)');
          return true;
        }
      } else if (response.statusCode == 404) {
        // 대화 내용이 없는 경우 (이미 삭제되었거나 없음)
        debugPrint('ℹ️ 삭제할 대화 내용이 없습니다. (404)');
        return true;  // 이미 없으므로 성공으로 처리
      } else {
        debugPrint('❌ 대화 내용 삭제 실패: ${response.statusCode}');
        debugPrint('   응답: $decodedBody');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 대화 내용 삭제 중 오류 발생: $e');
      debugPrint('   스택 트레이스: $stackTrace');
      return false;
    }
  }
}
