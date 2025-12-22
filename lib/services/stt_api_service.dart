import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_recording/configuration/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'logger.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class SttApiService {
  static const int _timeoutSeconds = 30;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Fetch available models from the API with retry logic
  static Future<List<String>> getModels(ApiEnvironment environment) async {
    final String baseUrl = ApiConfig.getBaseUrl(environment);
    final url = Uri.parse('$baseUrl/api/voice/models');

    customLogger.i('Fetching models from: $url');

    return _retryOperation(
      operation: () async {
        try {
          final response = await http
              .get(url)
              .timeout(const Duration(seconds: _timeoutSeconds));

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = jsonDecode(response.body);

            if (!data.containsKey('models')) {
              throw ApiException('Invalid response format: missing "models" field');
            }

            final List<dynamic> modelsList = data['models'];

            if (modelsList.isEmpty) {
              customLogger.w('No models returned from API');
              return <String>[];
            }

            final models = modelsList.map((e) => e.toString()).toList();
            customLogger.i('Successfully fetched ${models.length} models');
            return models;
          } else {
            throw ApiException(
              'Failed to fetch models',
              statusCode: response.statusCode,
            );
          }
        } on SocketException catch (e) {
          throw ApiException(
            'Network error: Please check your connection',
            originalError: e,
          );
        } on TimeoutException catch (e) {
          throw ApiException(
            'Request timeout: Server is not responding',
            originalError: e,
          );
        } on FormatException catch (e) {
          throw ApiException(
            'Invalid response format from server',
            originalError: e,
          );
        }
      },
      operationName: 'getModels',
    );
  }

  /// Send audio file to the API for transcription
  static Future<String> sendAudioFile(
      String filePath,
      String modelName,
      ApiEnvironment environment,
      ) async {
    final String baseUrl = ApiConfig.getBaseUrl(environment);
    final String endpoint = ApiConfig.getEndpoint(environment);
    final url = Uri.parse('$baseUrl$endpoint?model=$modelName');

    customLogger.i('Sending audio file to: $url');
    customLogger.d('File: $filePath, Model: $modelName');

    // Validate file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw ApiException('Audio file not found at path: $filePath');
    }

    // Get file size
    final fileSize = await file.length();
    customLogger.d('File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

    // Determine MIME type
    final extension = p.extension(filePath).toLowerCase();
    String? mimeType = lookupMimeType(filePath);

    if (mimeType == null) {
      mimeType = _getMimeTypeFromExtension(extension);
      customLogger.w('MIME type not detected, using default: $mimeType');
    }

    return _retryOperation(
      operation: () async {
        try {
          final mimeParts = mimeType!.split('/');
          final request = http.MultipartRequest('POST', url);

          // Add the file
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              filePath,
              contentType: MediaType(mimeParts[0], mimeParts[1]),
            ),
          );

          customLogger.i('Uploading file with MIME type: $mimeType');

          // Send request with timeout
          final streamedResponse = await request
              .send()
              .timeout(const Duration(seconds: _timeoutSeconds));

          final response = await http.Response.fromStream(streamedResponse);

          customLogger.d('Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            // Validate response is valid JSON
            try {
              jsonDecode(response.body);
              customLogger.i('Transcription completed successfully');
              return response.body;
            } catch (e) {
              throw ApiException(
                'Invalid JSON response from server',
                originalError: e,
              );
            }
          } else {
            final errorBody = response.body.isNotEmpty
                ? response.body
                : 'No error details provided';

            throw ApiException(
              'Transcription failed: $errorBody',
              statusCode: response.statusCode,
            );
          }
        } on SocketException catch (e) {
          throw ApiException(
            'Network error: Please check your connection',
            originalError: e,
          );
        } on TimeoutException catch (e) {
          throw ApiException(
            'Upload timeout: File may be too large or connection is slow',
            originalError: e,
          );
        } on http.ClientException catch (e) {
          throw ApiException(
            'Client error: ${e.message}',
            originalError: e,
          );
        }
      },
      operationName: 'sendAudioFile',
      maxRetries: 2, // Fewer retries for file uploads
    );
  }

  /// Retry operation with exponential backoff
  static Future<T> _retryOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = _maxRetries,
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (e) {
        final isLastAttempt = attempt >= maxRetries;

        customLogger.w(
          '$operationName attempt $attempt/$maxRetries failed: $e',
        );

        if (isLastAttempt) {
          customLogger.e('$operationName failed after $maxRetries attempts');
          rethrow;
        }

        // Exponential backoff
        final delayMs = _retryDelay.inMilliseconds * attempt;
        customLogger.d('Retrying in ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Get MIME type from file extension
  static String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.wav':
        return 'audio/wav';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/mp4';
      case '.ogg':
        return 'audio/ogg';
      case '.flac':
        return 'audio/flac';
      default:
        return 'audio/wav'; // Default fallback
    }
  }

  /// Test connection to the API
  static Future<bool> testConnection(ApiEnvironment environment) async {
    final String baseUrl = ApiConfig.getBaseUrl(environment);
    final url = Uri.parse('$baseUrl/api/voice/models');

    try {
      customLogger.i('Testing connection to: $url');

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      final isSuccess = response.statusCode == 200;

      if (isSuccess) {
        customLogger.i('Connection test successful');
      } else {
        customLogger.w('Connection test failed with status: ${response.statusCode}');
      }

      return isSuccess;
    } catch (e) {
      customLogger.e('Connection test failed', error: e);
      return false;
    }
  }
}