import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SttApiService {
  static const String baseUrl = 'http://192.168.20.214:8081';
  static const String endpoint = '/api/v1/transcribe';

  /// Faylni bevosita POST qiluvchi funksiya (query param: model)
  static Future<String> sendAudioFile(String filePath) async {
    // model query param qo‘shish
    final url = Uri.parse(baseUrl + endpoint + '?model=gemini');

    final request = http.MultipartRequest('POST', url);

    // Fayl qo‘shish
    request.files.add(await http.MultipartFile.fromPath(
      'file',             // Swagger field nomi
      filePath,
      contentType: MediaType('audio', 'ogg'), // backend kutgan format
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('STT error: ${response.statusCode}');
    }

    return response.body;
  }
}
