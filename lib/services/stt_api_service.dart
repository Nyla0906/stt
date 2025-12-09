import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';

import 'logger.dart';

enum SttModel { gemini, grok, elevenLabs }

class SttApiService {
  // static const String baseUrl = 'http://192.168.20.36:8080'; // Saidalo
  // static const String endpoint = '/api/voice/upload';

  static const String baseUrl = 'https://710b5c68b77c.ngrok-free.app';
  static const String endpoint = '/api/v1/transcribe';

  //? POST
  static Future<String> sendAudioFile(String filePath, SttModel model) async {
    String modelQueryParam;
    switch (model) {
      case SttModel.gemini:
        modelQueryParam = 'gemini';
        break;
      case SttModel.grok:
        modelQueryParam = 'groq';
        break;
      case SttModel.elevenLabs:
        modelQueryParam = 'elevenlabs';
        break;
    }

    final url = Uri.parse('$baseUrl$endpoint?model=$modelQueryParam');

    final extension = p.extension(filePath).toLowerCase();
    String? mimeType = lookupMimeType(filePath);

    if (mimeType == null) {
      if (extension == '.wav') {
        mimeType = 'audio/wav';
      } else if (extension == '.mp3') {
        mimeType = 'audio/mpeg';
      } else {
        customLogger.e('Unsupported file format detected: $extension.');
        throw Exception(
          'Unsupported file format: $extension. Please use WAV or MP3.',
        );
      }
    }

    final mimeParts = mimeType.split('/');
    final type = mimeParts[0];
    final subtype = mimeParts[1];
    // --------------------------------------------------------------------------

    final request = http.MultipartRequest('POST', url);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(type, subtype),
      ),
    );

    customLogger.i(
      'Sending audio file to STT API. Model: $modelQueryParam, MIME: $mimeType',
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    customLogger.d('API Status code: ${response.statusCode}');

    customLogger.d('API Response body: ${response.body}');

    if (response.statusCode != 200) {
      customLogger.e(
        'STT API xatosi (Error in STT Service).',
        error: 'Status: ${response.statusCode}. Response: ${response.body}',
      );
      throw Exception(
        'STT xizmatida xato: ${response.statusCode}. Javob: ${response.body}',
      );
    }

    customLogger.i('API call completed successfully for $modelQueryParam.');

    return response.body;
  }
}
