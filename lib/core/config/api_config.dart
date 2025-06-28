import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Storage keys
  static const String _openAIApiKeyKey = 'openai_api_key';
  static const String _openAIModelKey = 'openai_model';
  static const String _openAIBaseUrlKey = 'openai_base_url';
  
  // Default values
  static const String defaultModel = 'gpt-3.5-turbo';
  static const String defaultBaseUrl = 'https://api.openai.com/v1';
  
  // OpenAI API Key management
  static Future<String?> getOpenAIApiKey() async {
    try {
      return await _secureStorage.read(key: _openAIApiKeyKey);
    } catch (e) {
      print('Error reading OpenAI API key: $e');
      return null;
    }
  }
  
  static Future<void> setOpenAIApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _openAIApiKeyKey, value: apiKey);
    } catch (e) {
      print('Error storing OpenAI API key: $e');
      rethrow;
    }
  }
  
  static Future<void> removeOpenAIApiKey() async {
    try {
      await _secureStorage.delete(key: _openAIApiKeyKey);
    } catch (e) {
      print('Error removing OpenAI API key: $e');
    }
  }
  
  // Model configuration
  static Future<String> getOpenAIModel() async {
    try {
      final model = await _secureStorage.read(key: _openAIModelKey);
      return model ?? defaultModel;
    } catch (e) {
      print('Error reading OpenAI model: $e');
      return defaultModel;
    }
  }
  
  static Future<void> setOpenAIModel(String model) async {
    try {
      await _secureStorage.write(key: _openAIModelKey, value: model);
    } catch (e) {
      print('Error storing OpenAI model: $e');
      rethrow;
    }
  }
  
  // Base URL configuration
  static Future<String> getOpenAIBaseUrl() async {
    try {
      final baseUrl = await _secureStorage.read(key: _openAIBaseUrlKey);
      return baseUrl ?? defaultBaseUrl;
    } catch (e) {
      print('Error reading OpenAI base URL: $e');
      return defaultBaseUrl;
    }
  }
  
  static Future<void> setOpenAIBaseUrl(String baseUrl) async {
    try {
      await _secureStorage.write(key: _openAIBaseUrlKey, value: baseUrl);
    } catch (e) {
      print('Error storing OpenAI base URL: $e');
      rethrow;
    }
  }
  
  // Check if API is configured
  static Future<bool> isOpenAIConfigured() async {
    final apiKey = await getOpenAIApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  // Validate API key format
  static bool isValidOpenAIApiKey(String apiKey) {
    // OpenAI API keys typically start with 'sk-' and are 51 characters long
    return apiKey.startsWith('sk-') && apiKey.length >= 20;
  }
  
  // Get headers for API requests
  static Future<Map<String, String>> getOpenAIHeaders() async {
    final apiKey = await getOpenAIApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }
    
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
  }
}