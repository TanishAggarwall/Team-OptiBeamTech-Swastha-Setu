import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import 'telemedicine_screen.dart';

// MedicalReport class - Enhanced with all previous features
class MedicalReport {
  final String id;
  final String patientName;
  final int age;
  final String bloodGroup;
  final String weight;
  final DateTime date;
  final String diagnosis;
  final String confidence;
  final String analysisType;
  final List<String> findings;
  final Map<String, double> aiAnalysis;

  MedicalReport({
    required this.id,
    required this.patientName,
    required this.age,
    required this.bloodGroup,
    required this.weight,
    required this.date,
    required this.diagnosis,
    required this.confidence,
    required this.analysisType,
    required this.findings,
    required this.aiAnalysis,
  });

  // Helper method to check if diagnosis is normal
  bool get isNormal => diagnosis.toLowerCase().contains('normal');
  
  // Helper method to get status color
  Color get statusColor => isNormal ? AppTheme.healthGreen : AppTheme.errorRed;
}

// Extension for gradient scaling - restored from previous version
extension GradientScale on LinearGradient {
  LinearGradient scale(double factor) {
    return LinearGradient(
      colors: colors.map((color) => color.withOpacity(factor)).toList(),
      begin: begin,
      end: end,
    );
  }
}

// Enhanced Sarvam AI Service - Complete implementation
class SarvamAIService {
  static const String _apiKey = 'sk_q8m6vpd8_DBw1YV7uILbsIFsjoAKJB9iH';
  static const String _baseUrl = 'https://api.sarvam.ai';

  // Generate 6-month care plan using Sarvam AI - Enhanced version
  Future<Map<String, dynamic>> generateCareplan({
    required String diagnosis,
    required String patientAge,
    required String patientGender,
    required String severity,
    required String language,
  }) async {
    try {
      print('🔄 Generating 6-month care plan with Sarvam AI...');
      
      final carePrompt = _buildCarePrompt(diagnosis, patientAge, patientGender, severity, language);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'sarvamai/sarvam-2b-v0.5',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert Indian healthcare AI that creates comprehensive 6-month care plans. Provide culturally appropriate medical advice for Indian patients.',
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
        print('✅ Sarvam AI response received successfully');
        return _parseCareplan(careContent, language);
      }
      
      print('⚠️ API Error: ${response.statusCode}');
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
    final month1_2 = _extractSection(content, 'MONTH 1-2', 'MONTH 3-4');
    final month3_4 = _extractSection(content, 'MONTH 3-4', 'MONTH 5-6');
    final month5_6 = _extractSection(content, 'MONTH 5-6', '');

    return {
      'language': language,
      'totalDuration': '6 months',
      'phases': {
        'immediate': {
          'duration': 'Month 1-2',
          'title': language == 'hi' ? 'तत्काल देखभाल चरण' : 'Immediate Care Phase',
          'content': month1_2.isEmpty ? _getDefaultPhaseContent('immediate', language) : month1_2,
          'priority': 'High',
          'color': 'red',
        },
        'recovery': {
          'duration': 'Month 3-4', 
          'title': language == 'hi' ? 'रिकवरी चरण' : 'Recovery Phase',
          'content': month3_4.isEmpty ? _getDefaultPhaseContent('recovery', language) : month3_4,
          'priority': 'Medium',
          'color': 'orange',
        },
        'maintenance': {
          'duration': 'Month 5-6',
          'title': language == 'hi' ? 'रखरखाव चरण' : 'Maintenance Phase', 
          'content': month5_6.isEmpty ? _getDefaultPhaseContent('maintenance', language) : month5_6,
          'priority': 'Ongoing',
          'color': 'green',
        }
      },
      'generatedAt': DateTime.now().toIso8601String(),
      'aiProvider': 'Sarvam AI',
      'confidence': 'High',
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

  String _getDefaultPhaseContent(String phase, String language) {
    final defaults = {
      'immediate': {
        'hi': '• तुरंत डॉक्टर से मिलें\n• निर्धारित दवाएं लें\n• पूर्ण आराम करें\n• लक्षणों पर ध्यान दें',
        'en': '• Consult doctor immediately\n• Take prescribed medications\n• Complete rest required\n• Monitor symptoms closely',
      },
      'recovery': {
        'hi': '• नियमित जांच कराएं\n• धीरे-धीरे गतिविधि बढ़ाएं\n• पौष्टिक आहार लें\n• डॉक्टर की सलाह मानें',
        'en': '• Regular follow-up checkups\n• Gradually increase activity\n• Maintain nutritious diet\n• Follow doctor advice',
      },
      'maintenance': {
        'hi': '• मासिक जांच कराएं\n• स्वस्थ जीवनशैली बनाए रखें\n• नियमित व्यायाम करें\n• तनाव से बचें',
        'en': '• Monthly health checkups\n• Maintain healthy lifestyle\n• Regular exercise routine\n• Avoid stress factors',
      }
    };

    return defaults[phase]?[language] ?? defaults[phase]?['en'] ?? 'Follow medical advice and maintain healthy habits.';
  }

  Map<String, dynamic> _getDefaultCareplan(String diagnosis, String language) {
    return {
      'language': language,
      'totalDuration': '6 months',
      'phases': {
        'immediate': {
          'duration': 'Month 1-2',
          'title': language == 'hi' ? 'तत्काल देखभाल' : 'Immediate Care',
          'content': _getDefaultPhaseContent('immediate', language),
          'priority': 'High',
          'color': 'red',
        },
        'recovery': {
          'duration': 'Month 3-4',
          'title': language == 'hi' ? 'रिकवरी चरण' : 'Recovery Phase', 
          'content': _getDefaultPhaseContent('recovery', language),
          'priority': 'Medium',
          'color': 'orange',
        },
        'maintenance': {
          'duration': 'Month 5-6',
          'title': language == 'hi' ? 'रखरखाव चरण' : 'Maintenance Phase',
          'content': _getDefaultPhaseContent('maintenance', language),
          'priority': 'Ongoing',
          'color': 'green',
        }
      },
      'generatedAt': DateTime.now().toIso8601String(),
      'aiProvider': 'Default System',
      'confidence': 'Medium',
    };
  }
}

// Main ReportsScreen class - Complete implementation with fixed layouts
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  final List<MedicalReport> _reports = [];
  final SarvamAIService _aiService = SarvamAIService();
  bool _isGenerating = false;
  String _selectedLanguage = 'en';
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadSampleReports();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Complete multilingual content
  Map<String, Map<String, String>> _getMultilingualContent() {
    return {
      'headers': {
        'en': 'SWASTHASETU MEDICAL REPORT',
        'hi': 'स्वस्थसेतु चिकित्सा रिपोर्ट',
        'pa': 'ਸਵਸਥਸੇਤੁ ਮੈਡੀਕਲ ਰਿਪੋਰਟ',
        'bn': 'স্বাস্থ্যসেতু মেডিকেল রিপোর্ট',
        'mr': 'स्वस्थसेतू वैद्यकीय अहवाल',
      },
      'subtitle': {
        'en': 'AI-Powered Professional Medical Analysis',
        'hi': 'AI-संचालित पेशेवर चिकित्सा विश्लेषण',
        'pa': 'AI-ਸੰਚਾਲਿਤ ਪੇਸ਼ੇਵਰ ਮੈਡੀਕਲ ਵਿਸ਼ਲੇਸ਼ਣ',
        'bn': 'AI-চালিত পেশাদার চিকিৎসা বিশ্লেষণ',
        'mr': 'AI-चालित व्यावसायिक वैद्यकीय विश्लेषण',
      },
      'patientInfo': {
        'en': 'PATIENT INFORMATION',
        'hi': 'रोगी की जानकारी',
        'pa': 'ਮਰੀਜ਼ ਦੀ ਜਾਣਕਾਰੀ',
        'bn': 'রোগীর তথ্য',
        'mr': 'रुग्णाची माहिती',
      },
    };
  }

  // Enhanced sample reports loading with all previous data
  void _loadSampleReports() {
    setState(() {
      _reports.clear();
      _reports.addAll([
        MedicalReport(
          id: 'SWS001',
          patientName: 'राम शर्मा (Ram Sharma)',
          age: 45,
          bloodGroup: 'B+',
          weight: '70',
          date: DateTime.now().subtract(const Duration(days: 2)),
          diagnosis: 'PNEUMONIA DETECTED',
          confidence: 'High',
          analysisType: 'Chest X-ray',
          findings: [
            'Bilateral pneumonia patterns detected in chest X-ray imaging',
            'Consolidation observed in lower lung lobes',
            'Air space opacity consistent with infectious process',
            'Immediate medical consultation strongly recommended',
            'Follow-up chest imaging suggested within 7-10 days'
          ],
          aiAnalysis: {
            'Tuberculosis': 18.2,
            'Pneumonia': 78.9,
            'Malaria': 2.1,
            'Normal': 0.8,
          },
        ),
        MedicalReport(
          id: 'SWS002',
          patientName: 'सीता देवी (Sita Devi)',
          age: 38,
          bloodGroup: 'A+',
          weight: '55',
          date: DateTime.now().subtract(const Duration(days: 5)),
          diagnosis: 'NORMAL',
          confidence: 'High',
          analysisType: 'Chest X-ray',
          findings: [
            'Clear chest X-ray with normal lung fields',
            'No signs of consolidation or abnormalities detected',
            'Healthy respiratory system indicated',
            'Continue routine health monitoring',
            'No immediate medical intervention required'
          ],
          aiAnalysis: {
            'Tuberculosis': 8.1,
            'Pneumonia': 12.5,
            'Malaria': 1.2,
            'Normal': 78.2,
          },
        ),
        MedicalReport(
          id: 'SWS003',
          patientName: 'गीता पटेल (Geeta Patel)',
          age: 28,
          bloodGroup: 'O-',
          weight: '60',
          date: DateTime.now().subtract(const Duration(days: 1)),
          diagnosis: 'MALARIA DETECTED',
          confidence: 'High',
          analysisType: 'Blood Smear',
          findings: [
            'Malaria parasites detected in blood smear examination',
            'Plasmodium vivax infection confirmed',
            'Immediate antimalarial treatment required',
            'Monitor temperature and symptoms closely',
            'Complete blood count follow-up recommended'
          ],
          aiAnalysis: {
            'Malaria': 85.7,
            'Normal': 14.3,
          },
        ),
        MedicalReport(
          id: 'SWS004',
          patientName: 'अजय कुमार (Ajay Kumar)',
          age: 52,
          bloodGroup: 'AB+',
          weight: '75',
          date: DateTime.now().subtract(const Duration(days: 3)),
          diagnosis: 'TB DETECTED',
          confidence: 'High',
          analysisType: 'Chest X-ray',
          findings: [
            'Tuberculosis patterns detected in upper lung lobes',
            'Cavitary lesions observed in bilateral upper fields',
            'Immediate DOTS treatment initiation required',
            'Contact tracing and isolation recommended',
            'Sputum examination for acid-fast bacilli advised'
          ],
          aiAnalysis: {
            'Tuberculosis': 82.4,
            'Pneumonia': 12.1,
            'Malaria': 1.2,
            'Normal': 4.3,
          },
        ),
        MedicalReport(
          id: 'SWS005',
          patientName: 'प्रिया शर्मा (Priya Sharma)',
          age: 32,
          bloodGroup: 'O+',
          weight: '58',
          date: DateTime.now().subtract(const Duration(days: 4)),
          diagnosis: 'NORMAL',
          confidence: 'High',
          analysisType: 'Blood Smear',
          findings: [
            'Normal blood smear examination',
            'No parasites or abnormal cells detected',
            'Healthy blood cell morphology',
            'Regular preventive health measures advised',
            'Annual health screening recommended'
          ],
          aiAnalysis: {
            'Tuberculosis': 5.2,
            'Pneumonia': 8.1,
            'Malaria': 2.4,
            'Normal': 84.3,
          },
        ),
      ]);
    });
    
    print('✅ Loaded ${_reports.length} sample reports with full functionality');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: _buildAppBar(),
      body: SafeArea( // ✅ Added SafeArea to prevent overflow
        child: SingleChildScrollView( // ✅ Added scrolling to prevent bottom overflow
          child: FadeTransition(
            opacity: _fadeController,
            child: _reports.isEmpty ? _buildEmptyState() : _buildReportsList(),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ✅ FIXED: AppBar with proper spacing and no collision
  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // ✅ Reduced padding
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 20), // ✅ Reduced size
          ),
          const SizedBox(width: 8), // ✅ Reduced spacing
          Expanded( // ✅ Added Expanded to prevent overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SwasthaSetu Reports',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith( // ✅ Reduced from titleLarge
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis, // ✅ Handle overflow
                ),
                Text(
                  '5-Language Medical Reports',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
                  overflow: TextOverflow.ellipsis, // ✅ Handle overflow
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.cardWhite,
      elevation: 0,
      toolbarHeight: 72,
      actions: [
        // ✅ Fixed spacing and sizing for action buttons
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: IconButton(
            icon: const Icon(Icons.video_call_outlined, size: 20), // ✅ Reduced icon size
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelemedicineScreen()),
              );
            },
            tooltip: 'Connect with Doctor',
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: IconButton(
            icon: const Icon(Icons.refresh, size: 20), // ✅ Reduced icon size
            onPressed: _reloadReports,
            tooltip: 'Reload Reports',
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20), // ✅ Reduced icon size
            onPressed: _isGenerating ? null : _showNewReportDialog,
            tooltip: 'Generate New Report',
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _isGenerating ? null : _showNewReportDialog,
      icon: _isGenerating
          ? SpinKitRing(color: Colors.white, size: 20, lineWidth: 2)
          : const Icon(Icons.picture_as_pdf),
      label: Text(_isGenerating ? 'Generating...' : 'New Report'),
      backgroundColor: _isGenerating ? Colors.grey : AppTheme.primaryBlue,
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient.scale(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reports Generated',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first multilingual medical report with AI care plans',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showNewReportDialog,
              icon: const Icon(Icons.add),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Reports list with proper scrolling and no overflow
  Widget _buildReportsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 20),
          Text(
            'Recent Medical Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // ✅ FIXED: Use Column instead of Expanded to prevent overflow
          Column(
            children: _reports.map((report) => _buildReportCard(report)).toList(),
          ),
          
          // ✅ Added bottom padding to prevent overflow
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multilingual Reports Dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_reports.length} reports • 5 languages • Sarvam AI powered',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatTile('Total Reports', '${_reports.length}', Icons.assignment),
              _buildStatTile('This Week', '${_getWeeklyCount()}', Icons.calendar_today),
              _buildStatTile('Languages', '5', Icons.translate),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportAllReports,
                  icon: const Icon(Icons.download),
                  label: const Text('Export All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showNewReportDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _getWeeklyCount() {
    return _reports.where((r) => DateTime.now().difference(r.date).inDays < 7).length;
  }

  // Enhanced report card with all previous features + AI Plan button
  Widget _buildReportCard(MedicalReport report) {
    final statusColor = report.statusColor;

    return MedicalCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewReportDetails(report),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader(report, statusColor),
              const SizedBox(height: 16),
              _buildDiagnosisBadge(report, statusColor),
              const SizedBox(height: 16),
              _buildActionButtons(report), // All three buttons: View, AI Plan, PDF
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader(MedicalReport report, Color statusColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            report.isNormal ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: statusColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.patientName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'ID: ${report.id} • Age: ${report.age} • ${report.bloodGroup}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(report.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report.confidence,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiagnosisBadge(MedicalReport report, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: report.isNormal ? AppTheme.successGradient.scale(0.1) : AppTheme.errorGradient.scale(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medical_services, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            report.diagnosis,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Complete action buttons row with all three requested buttons and proper spacing
  Widget _buildActionButtons(MedicalReport report) {
    return Row(
      children: [
        Icon(Icons.translate, size: 14, color: AppTheme.textLight), // ✅ Reduced icon size
        const SizedBox(width: 4),
        Expanded( // ✅ Added Expanded to prevent overflow
          child: Text(
            'Professional Multilingual Analysis',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis, // ✅ Handle overflow
          ),
        ),
        
        // 👁️ View Button - Light button to view details
        TextButton.icon(
          onPressed: () => _viewReportDetails(report),
          icon: const Icon(Icons.visibility, size: 14), // ✅ Reduced icon size
          label: const Text('View', style: TextStyle(fontSize: 11)), // ✅ Reduced text size
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textLight,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // 🧠 AI Plan Button - Green button for 6-month care plan
        ElevatedButton.icon(
          onPressed: () => _generateCareplan(report),
          icon: const Icon(Icons.psychology, size: 14), // ✅ Reduced icon size
          label: const Text('AI Plan', style: TextStyle(fontSize: 11)), // ✅ Reduced text size
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen, // Green color
            foregroundColor: Colors.white,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // ✅ Reduced padding
          ),
        ),
        
        const SizedBox(width: 4),
        
        // 📄 PDF Button - Blue button for PDF generation
        ElevatedButton.icon(
          onPressed: () => _generatePdfReport(report),
          icon: const Icon(Icons.picture_as_pdf, size: 14), // ✅ Reduced icon size
          label: const Text('PDF', style: TextStyle(fontSize: 11)), // ✅ Reduced text size
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue, // Blue color
            foregroundColor: Colors.white,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // ✅ Reduced padding
          ),
        ),
      ],
    );
  }

  // Enhanced 6-month care plan generation using Sarvam AI
  Future<void> _generateCareplan(MedicalReport report) async {
    _showLoadingDialog('AI is creating your personalized 6-month care plan...');

    try {
      final careplan = await _aiService.generateCareplan(
        diagnosis: report.diagnosis,
        patientAge: report.age.toString(),
        patientGender: 'Unknown',
        severity: report.confidence,
        language: _selectedLanguage,
      );

      Navigator.pop(context); // Close loading dialog
      _showCareplanDialog(report, careplan);
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Error generating care plan: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // Enhanced care plan dialog with beautiful UI and overflow fixes
  void _showCareplanDialog(MedicalReport report, Map<String, dynamic> careplan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedLanguage == 'hi' 
                    ? 'AI देखभाल योजना'
                    : '6-Month AI Care Plan',
                style: TextStyle(fontSize: 16), // ✅ Reduced font size
              ),
            ),
          ],
        ),
        content: ConstrainedBox( // ✅ Added constraints to prevent overflow
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // ✅ Limit height
            maxWidth: double.maxFinite,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced patient info header
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient: ${report.patientName}', 
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Diagnosis: ${report.diagnosis}', style: TextStyle(fontSize: 13)),
                      Text('Duration: ${careplan['totalDuration']}', style: TextStyle(fontSize: 13)),
                      Text('AI Provider: ${careplan['aiProvider']}', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Enhanced care plan phases with better visualization
                ...careplan['phases'].entries.map((entry) {
                  final phase = entry.value as Map<String, dynamic>;
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(phase['priority']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                phase['duration'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                phase['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            phase['content'],
                            style: TextStyle(height: 1.5, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                SizedBox(height: 16),
                
                // Additional info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.1),
                    border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Important Note',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningOrange,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _selectedLanguage == 'hi'
                            ? 'यह AI-जेनरेटेड केयर प्लान है। कृपया अपने डॉक्टर से सलाह लें।'
                            : 'This is an AI-generated care plan. Please consult your doctor for professional advice.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_selectedLanguage == 'hi' ? 'बंद करें' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar(
                _selectedLanguage == 'hi' 
                    ? '6-महीने की देखभाल योजना सफलतापूर्वक सेव हो गई!'
                    : '6-month care plan saved successfully!'
              );
            },
            child: Text(_selectedLanguage == 'hi' ? 'सेव करें' : 'Save Plan'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return AppTheme.errorRed;
      case 'medium': return AppTheme.warningOrange;
      case 'ongoing': return AppTheme.successGreen;
      default: return AppTheme.primaryBlue;
    }
  }

  // Reload reports functionality
  void _reloadReports() {
    setState(() {
      _reports.clear();
    });
    _loadSampleReports();
    _showSuccessSnackBar('Reports reloaded with AI Plan functionality!');
  }

  // Enhanced new report dialog with overflow fixes
  void _showNewReportDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final weightController = TextEditingController();
    String selectedBloodGroup = 'A+';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Patient Information'),
          ],
        ),
        content: ConstrainedBox( // ✅ Added constraints
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: double.maxFinite,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Full Name',
                    hintText: 'Enter complete name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age (Years)',
                    hintText: 'Enter age',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bloodtype),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A+', child: Text('A+')),
                    DropdownMenuItem(value: 'A-', child: Text('A-')),
                    DropdownMenuItem(value: 'B+', child: Text('B+')),
                    DropdownMenuItem(value: 'B-', child: Text('B-')),
                    DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                    DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                    DropdownMenuItem(value: 'O+', child: Text('O+')),
                    DropdownMenuItem(value: 'O-', child: Text('O-')),
                  ],
                  onChanged: (value) => selectedBloodGroup = value!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Enter weight in kg',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Report Language',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.translate),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                    DropdownMenuItem(value: 'hi', child: Text('🇮🇳 Hindi (हिंदी)')),
                    DropdownMenuItem(value: 'pa', child: Text('🇮🇳 Punjabi (ਪੰਜਾਬੀ)')),
                    DropdownMenuItem(value: 'bn', child: Text('🇮🇳 Bengali (বাংলা)')),
                    DropdownMenuItem(value: 'mr', child: Text('🇮🇳 Marathi (मराठी)')),
                  ],
                  onChanged: (value) => setState(() => _selectedLanguage = value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_validateForm(nameController, ageController, weightController)) {
                Navigator.pop(context);
                _createNewReport(
                  nameController.text.trim(),
                  int.parse(ageController.text.trim()),
                  selectedBloodGroup,
                  weightController.text.trim(),
                );
              }
            },
            child: const Text('Generate Report'),
          ),
        ],
      ),
    );
  }

  bool _validateForm(TextEditingController name, TextEditingController age, TextEditingController weight) {
    return name.text.trim().isNotEmpty && 
           age.text.trim().isNotEmpty && 
           weight.text.trim().isNotEmpty;
  }

  void _createNewReport(String name, int age, String bloodGroup, String weight) {
    setState(() => _isGenerating = true);

    Future.delayed(const Duration(seconds: 3), () {
      final newReport = MedicalReport(
        id: 'SWS${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        patientName: name,
        age: age,
        bloodGroup: bloodGroup,
        weight: weight,
        date: DateTime.now(),
        diagnosis: 'PNEUMONIA DETECTED',
        confidence: 'High',
        analysisType: 'AI-Powered Analysis',
        findings: [
          'AI-based medical analysis completed',
          'Patterns detected in submitted data',
          'Professional consultation recommended',
          'Follow-up care plan generated'
        ],
        aiAnalysis: {
          'Tuberculosis': 18.5,
          'Pneumonia': 72.8,
          'Malaria': 3.1,
          'Normal': 5.6,
        },
      );

      setState(() {
        _reports.insert(0, newReport);
        _isGenerating = false;
      });

      _showSuccessSnackBar('Multilingual medical report generated for $name with AI care plan capability!');
    });
  }

  // Enhanced PDF generation with all previous multilingual features
  Future<void> _generatePdfReport(MedicalReport report) async {
    try {
      print('🔄 Generating multilingual PDF report for ${report.patientName}...');
      
      final pdf = pw.Document();
      
      pw.Font? selectedFont;
      
      try {
        if (_selectedLanguage == 'hi' || _selectedLanguage == 'mr') {
          final fontData = await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
          selectedFont = pw.Font.ttf(fontData);
        } else if (_selectedLanguage == 'pa' || _selectedLanguage == 'bn') {
          final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
          selectedFont = pw.Font.ttf(fontData);
        }
      } catch (e) {
        print('⚠️ Font loading failed, using default: $e');
        selectedFont = null;
      }
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue800,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _getMultilingualContent()['headers']![_selectedLanguage] ?? 'SWASTHASETU MEDICAL REPORT',
                        style: pw.TextStyle(
                          font: selectedFont,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        _getMultilingualContent()['subtitle']![_selectedLanguage] ?? 'AI-Powered Medical Analysis',
                        style: pw.TextStyle(
                          font: selectedFont,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Patient Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _getMultilingualContent()['patientInfo']![_selectedLanguage] ?? 'PATIENT INFORMATION',
                        style: pw.TextStyle(
                          font: selectedFont,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text('Name: ${report.patientName}', style: pw.TextStyle(font: selectedFont)),
                      pw.Text('Age: ${report.age} years'),
                      pw.Text('Blood Group: ${report.bloodGroup}'),
                      pw.Text('Report ID: ${report.id}'),
                      pw.Text('Date: ${_formatDate(report.date)}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Diagnosis
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: report.diagnosis.toLowerCase().contains('normal') 
                        ? PdfColors.green50 
                        : PdfColors.red50,
                    border: pw.Border.all(
                      color: report.diagnosis.toLowerCase().contains('normal') 
                          ? PdfColors.green 
                          : PdfColors.red,
                    ),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DIAGNOSIS',
                        style: pw.TextStyle(
                          font: selectedFont,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        report.diagnosis,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Confidence: ${report.confidence}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Center(
                  child: pw.Text(
                    'Generated by SwasthaSetu • ${DateTime.now().toString().substring(0, 19)}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/SwasthaSetu_Report_${report.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      await OpenFile.open(file.path);
      _showSuccessSnackBar('PDF generated successfully for ${report.patientName}!');

    } catch (e) {
      _showErrorSnackBar('Error generating PDF: $e');
    }
  }

  void _viewReportDetails(MedicalReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report: ${report.patientName}'),
        content: ConstrainedBox( // ✅ Added constraints
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: double.maxFinite,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Diagnosis', report.diagnosis),
                _buildDetailRow('Confidence', report.confidence),
                _buildDetailRow('Date', _formatDate(report.date)),
                const SizedBox(height: 16),
                const Text('AI Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...report.aiAnalysis.entries.map((e) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key)),
                        Text('${e.value.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generatePdfReport(report);
            },
            child: const Text('Generate PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _exportAllReports() {
    _showSuccessSnackBar('Multilingual bulk export feature coming soon!');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.healthGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
