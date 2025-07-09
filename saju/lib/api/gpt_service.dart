import 'dart:convert';
import 'package:http/http.dart' as http;

// ignore: slash_for_doc_comments
/************************************************************************** 
  모델이름	     |          설명	                     |             요금/성능
------------------------------------------------------------------------------  
gpt-4o	       |   최신 고성능, 빠르고 이미지도 처리 가능  	 |      ⭐️최고 성능, 중간 가격
gpt-4	         |   고성능 모델, 약간 느림	               |       높은 가격
gpt-3.5-turbo  |	  빠르고 저렴, 가벼운 용도에 적합	       |     💸 저렴, 가벼운 용도 추천
**************************************************************************** */

class GPTService {
  static Future<String> getFortuneInterpretation(
    String guaName,
    String poem,
    String apiKey,
  ) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    final body = jsonEncode({
      "model": "gpt-4o", // 또는 gpt-3.5-turbo
      "messages": [
        {
          "role": "system",
          "content": "당신은 전통 동양 철학에 정통한 사주 및 역학 전문가입니다. 간결하고 설득력 있는 해석을 제공해주세요."
        },
        {
          "role": "user",
          "content": "괘 이름: $guaName\n\n풀이 시: $poem\n\n이 운세를 해석해주세요."
        }
      ],
      "temperature": 0.7
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // ✅ 여기가 핵심
      final json = jsonDecode(decodedBody);
      final content = json['choices'][0]['message']['content'];
      return content.toString().trim();
    } else {
      throw Exception("❌ GPT 요청 실패: ${response.statusCode} ${response.body}");
    }
  }
}
