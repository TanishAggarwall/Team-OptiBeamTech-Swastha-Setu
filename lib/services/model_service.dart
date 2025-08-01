import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ModelService {
  bool _modelsLoaded = false;
   final String _serverUrl = 'http://192.168.1.14:5000';

  Future<void> loadModel() async {
    try {
      print('🔄 Connecting to YOUR trained models server...');
      
      final response = await http.get(Uri.parse('$_serverUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        _modelsLoaded = true;
        print('✅ Connected to YOUR REAL TRAINED MODELS!');
        print('🎉 TB, Pneumonia, COVID models ready for inference!');
      } else {
        throw Exception('Server not responding');
      }
    } catch (e) {
      print('❌ Could not connect to your models server: $e');
      print('💡 Make sure to run: python medical_ai_server.py');
      _modelsLoaded = false;
    }
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!_modelsLoaded) {
      return {
        'hasDisease': false,
        'detectedDisease': 'Normal',
        'confidence': 'Low',
        'message': 'Your trained models not connected'
      };
    }

    try {
      print('🔬 Analyzing with YOUR REAL TRAINED MODELS...');
      
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Send to your trained models
      final response = await http.post(
        Uri.parse('$_serverUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result.containsKey('error')) {
          throw Exception(result['error']);
        }
        
        final detectedDisease = result['result'] as String;
        final confidence = result['confidence'] as double;
        final scores = result['scores'] as Map<String, dynamic>;
        
        print('🎯 YOUR TRAINED MODEL RESULT: $detectedDisease');
        print('📊 Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
        print('📋 Scores - TB: ${(scores['TB']*100).toStringAsFixed(1)}%, Pneumonia: ${(scores['Pneumonia']*100).toStringAsFixed(1)}%, COVID: ${(scores['COVID']*100).toStringAsFixed(1)}%');
        
        return {
          'hasDisease': detectedDisease != 'NORMAL',
          'detectedDisease': detectedDisease,
          'confidence': confidence > 0.7 ? 'High' : (confidence > 0.5 ? 'Medium' : 'Low'),
          'message': 'Analysis by YOUR trained AI models - Real inference results'
        };
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Error with your trained models: $e');
      return {
        'hasDisease': false,
        'detectedDisease': 'Error',
        'confidence': 'Low',
        'message': 'Error connecting to your trained models'
      };
    }
  }

  void dispose() {
    _modelsLoaded = false;
    print('🧹 Disconnected from your trained models');
  }
}
