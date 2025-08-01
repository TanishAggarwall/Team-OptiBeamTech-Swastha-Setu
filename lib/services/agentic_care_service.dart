import 'dart:convert';
import 'package:http/http.dart' as http;

class AgenticCareService {
  static const String _sarvamApiKey = 'sk_q8m6vpd8_DBw1YV7uILbsIFsjoAKJB9iH';
  static const String _sarvamBaseUrl = 'https://api.sarvam.ai';

  // Generate 6-month care plan using Sarvam AI
  Future<Map<String, dynamic>> generateCareplan({
    required String diagnosis,
    required String patientAge,
    required String patientGender,
    required String severity,
    required String language,
  }) async {
    try {
      final carePrompt = _buildCarePrompt(diagnosis, patientAge, patientGender, severity, language);
      
      final response = await http.post(
        Uri.parse('$_sarvamBaseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_sarvamApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'sarvamai/sarvam-2b-v0.5',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert Indian healthcare AI that creates comprehensive 6-month care plans. Provide culturally appropriate medical advice for Indian patients.'
            },
            {
              'role': 'user',
              'content': carePrompt,
            }
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final careContent = data['choices'][0]['message']['content'];
        return _parseCareplan(careContent, language);
      }
      
      return _getDefaultCareplan(diagnosis, language);
    } catch (e) {
      print('❌ Sarvam AI Error: $e');
      return _getDefaultCareplan(diagnosis, language);
    }
  }

  String _buildCarePrompt(String diagnosis, String age, String gender, String severity, String language) {
    final languageNames = {
      'hi': 'Hindi',
      'pa': 'Punjabi',
      'bn': 'Bengali', 
      'mr': 'Marathi',
      'en': 'English',
    };

    return '''
Patient Profile:
- Diagnosis: $diagnosis
- Age: $age years
- Gender: $gender
- Severity: $severity

Create a comprehensive 6-month care plan in ${languageNames[language]} language including:

MONTH 1-2 (Immediate Care):
- Medications and dosage
- Diet recommendations
- Lifestyle changes
- Warning signs to watch

MONTH 3-4 (Recovery Phase):
- Follow-up tests needed
- Physical activity guidelines
- Nutritional support
- Mental health support

MONTH 5-6 (Maintenance Phase):
- Long-term management
- Preventive measures
- Regular checkup schedule
- Family support guidelines

Include Indian cultural context, affordable treatment options, and local healthcare resources.
Response should be in simple ${languageNames[language]} language suitable for rural Indian patients.
''';
  }

  Map<String, dynamic> _parseCareplan(String content, String language) {
    // Parse the AI response into structured care plan
    final months = <String, Map<String, dynamic>>{};
    
    // Extract month-wise information
    final month1_2 = _extractSection(content, 'MONTH 1-2', 'MONTH 3-4');
    final month3_4 = _extractSection(content, 'MONTH 3-4', 'MONTH 5-6');
    final month5_6 = _extractSection(content, 'MONTH 5-6', '');

    return {
      'language': language,
      'totalDuration': '6 months',
      'phases': {
        'immediate': {
          'duration': 'Month 1-2',
          'title': language == 'hi' ? 'तत्काल देखभाल' : 'Immediate Care',
          'content': month1_2,
          'priority': 'High',
        },
        'recovery': {
          'duration': 'Month 3-4', 
          'title': language == 'hi' ? 'रिकवरी चरण' : 'Recovery Phase',
          'content': month3_4,
          'priority': 'Medium',
        },
        'maintenance': {
          'duration': 'Month 5-6',
          'title': language == 'hi' ? 'रखरखाव चरण' : 'Maintenance Phase', 
          'content': month5_6,
          'priority': 'Ongoing',
        }
      },
      'generatedAt': DateTime.now().toIso8601String(),
      'aiProvider': 'Sarvam AI',
    };
  }

  String _extractSection(String content, String startMarker, String endMarker) {
    final startIndex = content.indexOf(startMarker);
    if (startIndex == -1) return '';
    
    final contentAfterStart = content.substring(startIndex + startMarker.length);
    
    if (endMarker.isEmpty) {
      return contentAfterStart.trim();
    }
    
    final endIndex = contentAfterStart.indexOf(endMarker);
    if (endIndex == -1) {
      return contentAfterStart.trim();
    }
    
    return contentAfterStart.substring(0, endIndex).trim();
  }

  Map<String, dynamic> _getDefaultCareplan(String diagnosis, String language) {
    // Fallback care plan if AI fails
    final defaultPlans = {
      'PNEUMONIA DETECTED': {
        'hi': {
          'immediate': 'तुरंत डॉक्टर से मिलें। एंटीबायोटिक दवा लें। पूरा आराम करें।',
          'recovery': 'नियमित जांच कराएं। धीरे-धीरे गतिविधि बढ़ाएं।',
          'maintenance': 'वार्षिक जांच। स्वस्थ जीवनशैली बनाए रखें।',
        },
        'en': {
          'immediate': 'See doctor immediately. Take prescribed antibiotics. Complete rest.',
          'recovery': 'Regular follow-ups. Gradually increase activity.',
          'maintenance': 'Annual checkups. Maintain healthy lifestyle.',
        }
      },
      'TB DETECTED': {
        'hi': {
          'immediate': 'DOTS केंद्र से इलाज शुरू करें। नियमित दवा लें।',
          'recovery': 'लक्षणों पर नज़र रखें। पौष्टिक आहार लें।',
          'maintenance': 'नियमित जांच। संपर्क में आने वालों की जांच।',
        },
        'en': {
          'immediate': 'Start DOTS treatment. Take regular medication.',
          'recovery': 'Monitor symptoms. Nutritious diet.',
          'maintenance': 'Regular checkups. Screen contacts.',
        }
      }
    };

    final plan = defaultPlans[diagnosis]?[language] ?? defaultPlans[diagnosis]?['en'];
    
    return {
      'language': language,
      'totalDuration': '6 months',
      'phases': {
        'immediate': {
          'duration': 'Month 1-2',
          'title': 'Immediate Care',
          'content': plan?['immediate'] ?? 'Consult healthcare provider',
          'priority': 'High',
        },
        'recovery': {
          'duration': 'Month 3-4',
          'title': 'Recovery Phase', 
          'content': plan?['recovery'] ?? 'Follow medical advice',
          'priority': 'Medium',
        },
        'maintenance': {
          'duration': 'Month 5-6',
          'title': 'Maintenance Phase',
          'content': plan?['maintenance'] ?? 'Regular monitoring',
          'priority': 'Ongoing',
        }
      },
      'generatedAt': DateTime.now().toIso8601String(),
      'aiProvider': 'Default System',
    };
  }
}
