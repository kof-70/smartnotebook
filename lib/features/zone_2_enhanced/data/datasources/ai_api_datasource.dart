import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/usecases/analyze_notes.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_utils.dart';

abstract class AIApiDataSource {
  Future<AIAnalysis> analyzeNotes(List<String> noteIds, String notesContent);
  Future<String> generateSpeech(String text);
  Future<List<String>> generateTags(String content);
  Future<String> chatWithAI(String message, List<Map<String, String>> conversationHistory);
}

class GPTDataSource implements AIApiDataSource {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  GPTDataSource({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage;

  @override
  Future<AIAnalysis> analyzeNotes(List<String> noteIds, String notesContent) async {
    try {
      final isConfigured = await ApiConfig.isOpenAIConfigured();
      if (!isConfigured) {
        throw const AIServiceException('OpenAI API key not configured');
      }

      final headers = await ApiConfig.getOpenAIHeaders();
      final baseUrl = await ApiConfig.getOpenAIBaseUrl();
      final model = await ApiConfig.getOpenAIModel();

      final systemPrompt = '''
You are an AI assistant specialized in analyzing personal notes. Your task is to provide insightful analysis of the user's notes.

Please analyze the provided notes and return a JSON response with the following structure:
{
  "summary": "A concise summary of the main themes and content",
  "keywords": ["keyword1", "keyword2", "keyword3"],
  "suggestions": ["suggestion1", "suggestion2", "suggestion3"]
}

Focus on:
- Main themes and topics
- Important insights or patterns
- Actionable suggestions for organization or follow-up
- Key concepts that appear frequently

Keep the summary under 200 words and provide 3-5 keywords and suggestions.
''';

      final userPrompt = '''
Please analyze these notes:

$notesContent

Provide analysis in the requested JSON format.
''';

      final requestBody = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userPrompt,
          },
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      };

      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: requestBody,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final content = responseData['choices'][0]['message']['content'];
        
        // Try to parse JSON response
        try {
          final analysisJson = jsonDecode(content);
          return AIAnalysis(
            summary: analysisJson['summary'] ?? 'Analysis completed successfully.',
            keywords: List<String>.from(analysisJson['keywords'] ?? []),
            suggestions: List<String>.from(analysisJson['suggestions'] ?? []),
          );
        } catch (e) {
          // Fallback if JSON parsing fails
          return AIAnalysis(
            summary: content,
            keywords: ['analysis', 'notes', 'insights'],
            suggestions: ['Review and organize your notes', 'Add more specific tags'],
          );
        }
      } else {
        throw AIServiceException('OpenAI API request failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AIServiceException('Invalid OpenAI API key');
      } else if (e.response?.statusCode == 429) {
        throw const AIServiceException('OpenAI API rate limit exceeded');
      } else {
        throw AIServiceException('OpenAI API error: ${e.message}');
      }
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to analyze notes: ${e.toString()}');
    }
  }

  @override
  Future<String> chatWithAI(String message, List<Map<String, String>> conversationHistory) async {
    try {
      final isConfigured = await ApiConfig.isOpenAIConfigured();
      if (!isConfigured) {
        throw const AIServiceException('OpenAI API key not configured');
      }

      final headers = await ApiConfig.getOpenAIHeaders();
      final baseUrl = await ApiConfig.getOpenAIBaseUrl();
      final model = await ApiConfig.getOpenAIModel();

      final systemPrompt = '''
You are a helpful AI assistant for a personal note-taking app called Smart Notebook. 
You help users with:
- Organizing and understanding their notes
- Providing insights about their content
- Suggesting improvements and connections
- Answering questions about their notes
- General productivity and note-taking advice

Be concise, helpful, and friendly. Focus on practical advice related to note-taking and personal knowledge management.
''';

      // Build conversation messages
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      // Add conversation history
      messages.addAll(conversationHistory);

      // Add current user message
      messages.add({'role': 'user', 'content': message});

      final requestBody = {
        'model': model,
        'messages': messages,
        'max_tokens': 500,
        'temperature': 0.8,
      };

      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: requestBody,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final content = responseData['choices'][0]['message']['content'];
        return content.trim();
      } else {
        throw AIServiceException('OpenAI API request failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AIServiceException('Invalid OpenAI API key');
      } else if (e.response?.statusCode == 429) {
        throw const AIServiceException('OpenAI API rate limit exceeded');
      } else {
        throw AIServiceException('OpenAI API error: ${e.message}');
      }
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to chat with AI: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> generateTags(String content) async {
    try {
      final isConfigured = await ApiConfig.isOpenAIConfigured();
      if (!isConfigured) {
        throw const AIServiceException('OpenAI API key not configured');
      }

      final headers = await ApiConfig.getOpenAIHeaders();
      final baseUrl = await ApiConfig.getOpenAIBaseUrl();
      final model = await ApiConfig.getOpenAIModel();

      final systemPrompt = '''
You are an AI assistant that generates relevant tags for notes. 
Analyze the provided content and suggest 3-7 relevant tags that would help organize and find this note later.

Return only a JSON array of strings, like: ["tag1", "tag2", "tag3"]

Guidelines:
- Use lowercase tags
- Keep tags concise (1-2 words)
- Focus on main topics, categories, and key concepts
- Avoid overly generic tags like "note" or "text"
- Include both specific and general tags
''';

      final userPrompt = '''
Generate tags for this content:

$content
''';

      final requestBody = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userPrompt,
          },
        ],
        'max_tokens': 200,
        'temperature': 0.5,
      };

      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: requestBody,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final content = responseData['choices'][0]['message']['content'];
        
        try {
          final tagsJson = jsonDecode(content);
          if (tagsJson is List) {
            return List<String>.from(tagsJson);
          } else {
            throw const AIServiceException('Invalid tags format received');
          }
        } catch (e) {
          // Fallback: extract tags from text response
          final lines = content.split('\n');
          final tags = <String>[];
          for (final line in lines) {
            final cleaned = line.trim().replaceAll(RegExp(r'[^\w\s-]'), '');
            if (cleaned.isNotEmpty && cleaned.length < 20) {
              tags.add(cleaned.toLowerCase());
            }
          }
          return tags.take(7).toList();
        }
      } else {
        throw AIServiceException('OpenAI API request failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AIServiceException('Invalid OpenAI API key');
      } else if (e.response?.statusCode == 429) {
        throw const AIServiceException('OpenAI API rate limit exceeded');
      } else {
        throw AIServiceException('OpenAI API error: ${e.message}');
      }
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to generate tags: ${e.toString()}');
    }
  }

  @override
  Future<String> generateSpeech(String text) async {
    try {
      final isConfigured = await ApiConfig.isOpenAIConfigured();
      if (!isConfigured) {
        throw const AIServiceException('OpenAI API key not configured');
      }

      final headers = await ApiConfig.getOpenAIHeaders();
      final baseUrl = await ApiConfig.getOpenAIBaseUrl();

      final requestBody = {
        'model': 'tts-1',
        'input': text,
        'voice': 'alloy',
        'response_format': 'mp3',
      };

      final response = await _dio.post(
        '$baseUrl/audio/speech',
        data: requestBody,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        // Create TTS directory if it doesn't exist
        final ttsDirectory = await FileUtils.createDirectory(AppConstants.ttsDirectory);
        
        // Generate unique filename
        final fileName = await FileUtils.generateUniqueFileName('mp3');
        final filePath = '${ttsDirectory.path}/$fileName';
        
        // Save audio data to file
        final audioFile = File(filePath);
        await audioFile.writeAsBytes(response.data as Uint8List);
        
        print('TTS audio saved to: $filePath');
        return filePath;
      } else {
        throw AIServiceException('OpenAI TTS API request failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AIServiceException('Invalid OpenAI API key');
      } else if (e.response?.statusCode == 429) {
        throw const AIServiceException('OpenAI API rate limit exceeded');
      } else {
        throw AIServiceException('OpenAI TTS API error: ${e.message}');
      }
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to generate speech: ${e.toString()}');
    }
  }
}