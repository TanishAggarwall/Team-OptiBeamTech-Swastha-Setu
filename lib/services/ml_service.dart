import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MLService {
  // 🚀 YOUR LIVE RENDER API URL
  static const String _baseUrl = 'https://swasthasetu-medical-ai.onrender.com';
  
  // Extended timeout for Render (handles cold starts)
  static const Duration _timeout = Duration(seconds: 60);
  static const Duration _connectionTimeout = Duration(seconds: 30);

  /// Predict disease using your deployed SwasthaSetu AI models
  static Future<Map<String, dynamic>> predictDisease({
    required File imageFile,
    required String analysisType,
  }) async {
    try {
      print('🔄 Connecting to SwasthaSetu AI: $_baseUrl');

      // Create multipart request for image upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );

      // Add headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
        'User-Agent': 'SwasthaSetu-Flutter-App/1.0',
      });

      // Add image file
      var multipartFile = await http.MultipartFile.fromPath(
        'image', // Parameter name your deployed model expects
        imageFile.path,
      );
      request.files.add(multipartFile);

      // Add analysis type if needed
      request.fields['analysis_type'] = analysisType;

      print('📤 Sending image to your trained AI models...');
      
      // Send request with timeout
      var streamedResponse = await request.send().timeout(_timeout);
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 SwasthaSetu AI Response Status: ${response.statusCode}');
      print('📥 SwasthaSetu AI Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        return _processSwasthaSetuResponse(result);
      } else if (response.statusCode == 503) {
        // Render service might be cold starting
        print('⚠️ Render cold start detected, retrying...');
        await Future.delayed(const Duration(seconds: 15));
        return predictDisease(imageFile: imageFile, analysisType: analysisType);
      } else {
        throw Exception('SwasthaSetu API Error: ${response.statusCode} - ${response.body}');
      }

    } on http.ClientException catch (e) {
      print('❌ Network Error: $e');
      return _getNetworkErrorResponse();
    } on FormatException catch (e) {
      print('❌ JSON Parse Error: $e');
      return _getParseErrorResponse();
    } catch (e) {
      print('❌ SwasthaSetu ML Service Error: $e');
      return _getFallbackResponse();
    }
  }

  /// Process response from your deployed SwasthaSetu AI models
  static Map<String, dynamic> _processSwasthaSetuResponse(Map<String, dynamic> rawResponse) {
    try {
      // Extract data from your API response format
      String diagnosis = rawResponse['diagnosis'] ?? 'UNKNOWN';
      String confidence = rawResponse['confidence'] ?? 'Low';
      bool hasDisease = rawResponse['hasDisease'] ?? false;
      double confidenceScore = (rawResponse['confidenceScore'] ?? 0.0).toDouble();
      
      // Handle AI predictions from your 3 models (Pneumonia, TB, Malaria)
      Map<String, dynamic> predictions = rawResponse['predictions'] ?? {};
      Map<String, double> analysisScores = {};
      
      predictions.forEach((key, value) {
        analysisScores[key] = (value is double ? value : (value as num).toDouble());
      });

      // If no predictions found, create basic ones
      if (analysisScores.isEmpty) {
        analysisScores[diagnosis] = confidenceScore * 100;
        analysisScores['Other'] = (1.0 - confidenceScore) * 100;
      }

      return {
        'success': true,
        'diagnosis': diagnosis,
        'confidence': confidence,
        'hasDisease': hasDisease,
        'aiAnalysis': analysisScores,
        'rawPrediction': diagnosis,
        'confidenceScore': confidenceScore,
        'processingTime': DateTime.now().toIso8601String(),
        'modelSource': 'SwasthaSetu Trained Models (Pneumonia, TB, Malaria)',
        'apiUrl': _baseUrl,
        'rawResponse': rawResponse, // For debugging
      };
    } catch (e) {
      print('❌ Error processing SwasthaSetu response: $e');
      return _getFallbackResponse();
    }
  }

  /// Health check for your deployed models
  static Future<bool> checkModelHealth() async {
    try {
      print('🔄 Checking SwasthaSetu AI health...');
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(_connectionTimeout);

      if (response.statusCode == 200) {
        final healthData = jsonDecode(response.body);
        print('✅ SwasthaSetu AI Health: ${healthData['status']}');
        print('✅ Models Loaded: ${healthData['models_loaded']}');
        return healthData['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('⚠️ SwasthaSetu AI health check failed: $e');
      return false;
    }
  }

  /// Get model information from your deployed API
  static Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: {'Accept': 'application/json'},
      ).timeout(_connectionTimeout);

      if (response.statusCode == 200) {
        final info = jsonDecode(response.body);
        return {
          'model_name': info['message'] ?? 'SwasthaSetu Medical AI',
          'version': info['version'] ?? '1.0',
          'status': info['status'] ?? 'online',
          'models': info['models'] ?? ['pneumonia', 'tuberculosis', 'malaria'],
          'platform': 'Render',
          'api_url': _baseUrl,
        };
      }
    } catch (e) {
      print('⚠️ Could not fetch SwasthaSetu model info: $e');
    }

    return {
      'model_name': 'SwasthaSetu Medical AI',
      'version': '1.0.0',
      'status': 'deployed',
      'models': ['Pneumonia Detection', 'TB Detection', 'Malaria Detection'],
      'platform': 'Render',
      'api_url': _baseUrl,
    };
  }

  /// Test connection to your deployed models
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🧪 Testing SwasthaSetu AI connection...');
      
      final isHealthy = await checkModelHealth();
      final modelInfo = await getModelInfo();
      
      return {
        'success': true,
        'health_status': isHealthy ? 'healthy' : 'unhealthy',
        'model_info': modelInfo,
        'connection_time': DateTime.now().toIso8601String(),
        'api_url': _baseUrl,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'api_url': _baseUrl,
      };
    }
  }

  /// Network error response
  static Map<String, dynamic> _getNetworkErrorResponse() {
    return {
      'success': false,
      'diagnosis': 'NETWORK ERROR',
      'confidence': 'Low',
      'hasDisease': false,
      'aiAnalysis': {'Error': 100.0},
      'error': 'Could not connect to SwasthaSetu AI. Check internet connection.',
      'modelSource': 'Network Error',
    };
  }

  /// Parse error response
  static Map<String, dynamic> _getParseErrorResponse() {
    return {
      'success': false,
      'diagnosis': 'RESPONSE ERROR',
      'confidence': 'Low',
      'hasDisease': false,
      'aiAnalysis': {'Error': 100.0},
      'error': 'Invalid response from SwasthaSetu AI.',
      'modelSource': 'Parse Error',
    };
  }

  /// Fallback response when models are unavailable
  static Map<String, dynamic> _getFallbackResponse() {
    return {
      'success': false,
      'diagnosis': 'ANALYSIS UNAVAILABLE',
      'confidence': 'Medium',
      'hasDisease': false,
      'aiAnalysis': {
        'Pneumonia': 25.0,
        'Tuberculosis': 25.0,
        'Malaria': 25.0,
        'Normal': 25.0,
      },
      'error': 'SwasthaSetu AI models temporarily unavailable',
      'modelSource': 'Fallback Response',
    };
  }

  /// Format diagnosis for display
  static String formatDiagnosis(String prediction) {
    switch (prediction.toUpperCase()) {
      case 'PNEUMONIA':
      case 'PNEUMONIA DETECTED':
        return 'PNEUMONIA DETECTED';
      case 'TUBERCULOSIS':
      case 'TUBERCULOSIS DETECTED':
      case 'TB':
      case 'TB DETECTED':
        return 'TB DETECTED';
      case 'MALARIA':
      case 'MALARIA DETECTED':
        return 'MALARIA DETECTED';
      case 'NORMAL':
        return 'NORMAL';
      default:
        return 'ANALYSIS COMPLETE';
    }
  }

  /// Get confidence level description
  static String getConfidenceLevel(double confidence) {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }

  /// Get analysis color based on diagnosis
  static String getAnalysisColor(String diagnosis) {
    switch (diagnosis.toLowerCase()) {
      case 'pneumonia':
      case 'pneumonia detected':
        return 'red';
      case 'tuberculosis':
      case 'tb detected':
      case 'tb':
        return 'orange';
      case 'malaria':
      case 'malaria detected':
        return 'purple';
      case 'normal':
        return 'green';
      default:
        return 'blue';
    }
  }

  /// Dispose resources (if needed)
  static void dispose() {
    // Clean up any resources if needed
    print('🧹 MLService resources disposed');
  }
}
