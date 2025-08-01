import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PDFService {
  // Professional medical colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF2E5C8A);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF4A90B8);
  static const PdfColor redColor = PdfColor.fromInt(0xFFD32F2F);
  static const PdfColor greenColor = PdfColor.fromInt(0xFF388E3C);
  static const PdfColor orangeColor = PdfColor.fromInt(0xFFFF9800);

  /// Generate professional medical diagnostic PDF report
  static Future<Uint8List> generateDiagnosticReport({
    required Map<String, dynamic> patientDetails,
    required Map<String, dynamic> analysisResult,
    required String reportId,
  }) async {
    final pdf = pw.Document();

    // Load fonts for multilingual support
    final helveticaFont = await PdfGoogleFonts.nunitoSansRegular();
    final helveticaBold = await PdfGoogleFonts.nunitoSansBold();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header Section
            _buildHeader(helveticaBold, helveticaFont, reportId),
            pw.SizedBox(height: 20),

            // Technical Report Section (English)
            _buildTechnicalReport(helveticaBold, helveticaFont, patientDetails, analysisResult),
            pw.SizedBox(height: 30),

            // Patient-Friendly Section (Multilingual)
            _buildPatientFriendlyReport(helveticaBold, helveticaFont, patientDetails, analysisResult),
            pw.SizedBox(height: 20),

            // Medical Advice Section (Multilingual)
            _buildMedicalAdvice(helveticaBold, helveticaFont, analysisResult),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Build professional header
  static pw.Widget _buildHeader(pw.Font boldFont, pw.Font regularFont, String reportId) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SwasthaSetu AI Diagnostic Report',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Technical Report (For Doctor\'s Review)',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Report ID: $reportId',
                style: pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.white),
              ),
              pw.Text(
                'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build technical report section
  static pw.Widget _buildTechnicalReport(
    pw.Font boldFont, 
    pw.Font regularFont, 
    Map<String, dynamic> patientDetails, 
    Map<String, dynamic> analysisResult
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Patient Details
        pw.Text(
          'Patient Details:',
          style: pw.TextStyle(font: boldFont, fontSize: 16, color: primaryColor),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Patient Name: ${patientDetails['name']}', style: pw.TextStyle(font: regularFont, fontSize: 12)),
              pw.Text('Age: ${patientDetails['age']} yrs', style: pw.TextStyle(font: regularFont, fontSize: 12)),
              pw.Text('Weight: ${patientDetails['weight']} kg', style: pw.TextStyle(font: regularFont, fontSize: 12)),
              pw.Text('Blood Group: ${patientDetails['bloodGroup']}', style: pw.TextStyle(font: regularFont, fontSize: 12)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // AI Diagnostic Analysis
        pw.Text(
          'AI Diagnostic Analysis (Based on Chest X-Ray Image):',
          style: pw.TextStyle(font: boldFont, fontSize: 16, color: primaryColor),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'This analysis was performed by the SwasthaSetu AI engine.',
          style: pw.TextStyle(font: regularFont, fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 15),

        // Results Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Condition Analyzed', style: pw.TextStyle(font: boldFont, fontSize: 11)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Confidence Score', style: pw.TextStyle(font: boldFont, fontSize: 11)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Indication', style: pw.TextStyle(font: boldFont, fontSize: 11)),
                ),
              ],
            ),
            // Data rows
            ...((analysisResult['predictions'] as Map<String, double>).entries.map((entry) {
              final priority = entry.value > 70 ? 'High Priority' : entry.value > 40 ? 'Medium Priority' : 'Low Priority';
              final color = entry.value > 70 ? redColor : entry.value > 40 ? orangeColor : greenColor;
              
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(entry.key, style: pw.TextStyle(font: regularFont, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${entry.value.toStringAsFixed(1)}%', style: pw.TextStyle(font: boldFont, fontSize: 10, color: color)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(priority, style: pw.TextStyle(font: regularFont, fontSize: 10, color: color)),
                  ),
                ],
              );
            }).toList()),
          ],
        ),

        pw.SizedBox(height: 20),

        // Preliminary Finding
        pw.Text(
          'Preliminary Finding:',
          style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: primaryColor, width: 1),
          ),
          child: pw.Text(
            _generatePreliminaryFinding(analysisResult),
            style: pw.TextStyle(font: regularFont, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }

  /// Build patient-friendly multilingual report
  static pw.Widget _buildPatientFriendlyReport(
    pw.Font boldFont,
    pw.Font regularFont,
    Map<String, dynamic> patientDetails,
    Map<String, dynamic> analysisResult,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: secondaryColor,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Text(
            'Patient-Friendly Report (आपके लिए रिपोर्ट)',
            style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.white),
          ),
        ),
        pw.SizedBox(height: 15),

        // Hindi Section
        _buildLanguageSection(
          'स्वास्थ्य सेतु - आपकी स्वास्थ्य रिपोर्ट',
          _generateHindiReport(patientDetails, analysisResult),
          boldFont,
          regularFont,
        ),

        // Telugu Section
        _buildLanguageSection(
          'స్వాస్త్య సేతు - మీ ఆరోగ్య నివేదిక',
          _generateTeluguReport(patientDetails, analysisResult),
          boldFont,
          regularFont,
        ),

        // Tamil Section
        _buildLanguageSection(
          'ஸ்வஸ்த சேது - உங்கள் ஆரோக்கிய அறிக்கை',
          _generateTamilReport(patientDetails, analysisResult),
          boldFont,
          regularFont,
        ),

        // Bengali Section
        _buildLanguageSection(
          'স্বাস্থ্য সেতু - আপনার স্বাস্থ্য রিপোর্ট',
          _generateBengaliReport(patientDetails, analysisResult),
          boldFont,
          regularFont,
        ),
      ],
    );
  }

  /// Build language section
  static pw.Widget _buildLanguageSection(
    String title,
    String content,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            content,
            style: pw.TextStyle(font: regularFont, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Build medical advice section
  static pw.Widget _buildMedicalAdvice(
    pw.Font boldFont,
    pw.Font regularFont,
    Map<String, dynamic> analysisResult,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: orangeColor, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'डॉक्टर की सलाह (Doctor\'s Advice):',
            style: pw.TextStyle(font: boldFont, fontSize: 16, color: orangeColor),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            _generateMedicalAdvice(analysisResult),
            style: pw.TextStyle(font: regularFont, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  /// Generate preliminary finding text
  static String _generatePreliminaryFinding(Map<String, dynamic> analysisResult) {
    final predictions = analysisResult['predictions'] as Map<String, double>;
    final maxEntry = predictions.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    if (maxEntry.key == 'Normal') {
      return 'The AI model analysis indicates normal chest X-ray patterns with no significant abnormalities detected. The confidence score of ${maxEntry.value.toStringAsFixed(1)}% suggests healthy lung condition.';
    } else {
      return 'The AI model has detected patterns in the provided medical image that are highly consistent with ${maxEntry.key}. The confidence score of ${maxEntry.value.toStringAsFixed(1)}% indicates a strong probability. Further clinical correlation and confirmatory tests are advised.';
    }
  }

  /// Generate Hindi report
  static String _generateHindiReport(Map<String, dynamic> patientDetails, Map<String, dynamic> analysisResult) {
    final predictions = analysisResult['predictions'] as Map<String, double>;
    final maxEntry = predictions.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    String report = 'नाम: ${patientDetails['name']}\n';
    report += 'उम्र: ${patientDetails['age']} साल\n';
    report += 'वजन: ${patientDetails['weight']} किलो\n';
    report += 'ब्लड ग्रुप: ${patientDetails['bloodGroup']}\n\n';
    report += 'जांच का नतीजा (AI Analysis Result):\n\n';
    report += 'हमारी AI जांच में आपके एक्स-रे की फोटो को analyze करने पर ${maxEntry.key} होने की ${maxEntry.value.toStringAsFixed(1)}% संभावना पाई गई है।\n\n';
    
    for (final entry in predictions.entries) {
      report += '${entry.key}: ${entry.value.toStringAsFixed(1)}%\n';
    }
    
    report += '\nयह मशीन द्वारा की गई एक प्रारंभिक जांच है जो डॉक्टरों की मदद के लिए बनाई गई है।';
    return report;
  }

  /// Generate Telugu report
  static String _generateTeluguReport(Map<String, dynamic> patientDetails, Map<String, dynamic> analysisResult) {
    final predictions = analysisResult['predictions'] as Map<String, double>;
    final maxEntry = predictions.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    String report = 'పేరు: ${patientDetails['name']}\n';
    report += 'వయస్సు: ${patientDetails['age']} సంవత్సరాలు\n';
    report += 'బరువు: ${patientDetails['weight']} కిలోలు\n';
    report += 'రక్త వర్గం: ${patientDetails['bloodGroup']}\n\n';
    report += 'పరీక్ష ఫలితాలు (AI Analysis Result):\n\n';
    report += 'మా AI పరీక్షలో మీ X-రే చిత్రాన్ని విశ్లేషించిన తర్వాత ${maxEntry.key} ఉండే అవకాశం ${maxEntry.value.toStringAsFixed(1)}% కనుగొనబడింది।\n\n';
    
    for (final entry in predictions.entries) {
      report += '${entry.key}: ${entry.value.toStringAsFixed(1)}%\n';
    }
    
    report += '\nఇది డాక్టర్లకు సహాయం చేయడానికి రూపొందించిన యంత్ర ప్రాథమిక పరీక్ష.';
    return report;
  }

  /// Generate Tamil report
  static String _generateTamilReport(Map<String, dynamic> patientDetails, Map<String, dynamic> analysisResult) {
    final predictions = analysisResult['predictions'] as Map<String, double>;
    final maxEntry = predictions.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    String report = 'பெயர்: ${patientDetails['name']}\n';
    report += 'வயது: ${patientDetails['age']} ஆண்டுகள்\n';
    report += 'எடை: ${patientDetails['weight']} கிலோ\n';
    report += 'இரத்த வகை: ${patientDetails['bloodGroup']}\n\n';
    report += 'பரிசோதனை முடிவுகள் (AI Analysis Result):\n\n';
    report += 'எங்கள் AI பரிசோதனையில் உங்கள் X-ரே படத்தை பகுப்பாய்வு செய்த பின்னர் ${maxEntry.key} இருக்கும் சாத்தியம் ${maxEntry.value.toStringAsFixed(1)}% கண்டறியப்பட்டது।\n\n';
    
    for (final entry in predictions.entries) {
      report += '${entry.key}: ${entry.value.toStringAsFixed(1)}%\n';
    }
    
    report += '\nஇது மருத்துவர்களுக்கு உதவ வடிவமைக்கப்பட்ட இயந்திர ஆரம்ப பரிசோதனை.';
    return report;
  }

  /// Generate Bengali report
  static String _generateBengaliReport(Map<String, dynamic> patientDetails, Map<String, dynamic> analysisResult) {
    final predictions = analysisResult['predictions'] as Map<String, double>;
    final maxEntry = predictions.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    String report = 'নাম: ${patientDetails['name']}\n';
    report += 'বয়স: ${patientDetails['age']} বছর\n';
    report += 'ওজন: ${patientDetails['weight']} কেজি\n';
    report += 'রক্তের গ্রুপ: ${patientDetails['bloodGroup']}\n\n';
    report += 'পরীক্ষার ফলাফল (AI Analysis Result):\n\n';
    report += 'আমাদের AI পরীক্ষায় আপনার X-রে ছবি বিশ্লেষণ করার পর ${maxEntry.key} হওয়ার সম্ভাবনা ${maxEntry.value.toStringAsFixed(1)}% পাওয়া গেছে।\n\n';
    
    for (final entry in predictions.entries) {
      report += '${entry.key}: ${entry.value.toStringAsFixed(1)}%\n';
    }
    
    report += '\nএটি ডাক্তারদের সাহায্যের জন্য তৈরি একটি যন্ত্রিক প্রাথমিক পরীক্ষা।';
    return report;
  }

  /// Generate medical advice
  static String _generateMedicalAdvice(Map<String, dynamic> analysisResult) {
    final predictions = analysisResult['predictions'] as Map<String, double>;
    final maxEntry = predictions.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    if (maxEntry.key == 'Normal') {
      return '''नमस्ते,
      
रिपोर्ट के अनुसार, आपकी जांच में कोई गंभीर समस्या नहीं मिली है। यह एक अच्छी बात है।

कृपया निम्नलिखित सुझावों का पालन करें:
1. नियमित स्वास्थ्य जांच कराते रहें
2. स्वस्थ जीवनशैली बनाए रखें
3. धूम्रपान और शराब से बचें
4. नियमित व्यायाम करें और संतुलित आहार लें

यदि कोई लक्षण दिखे तो तुरंत डॉक्टर से मिलें।''';
    } else {
      String diseaseName = maxEntry.key == 'Pneumonia' ? 'निमोनिया' : 
                          maxEntry.key == 'Tuberculosis' ? 'टीबी' :
                          maxEntry.key == 'Malaria' ? 'मलेरिया' : maxEntry.key;
      
      return '''नमस्ते,

रिपोर्ट के अनुसार, आपको $diseaseName की संभावना है। आपको चिंता करने की कोई जरूरत नहीं है। सही समय पर इलाज शुरू करने से यह पूरी तरह ठीक हो सकता है।

कृपया तुरंत यह कदम उठाएं:
1. तुरंत डॉक्टर से मिलें: अपनी पूरी जांच करवाएं और डॉक्टर की सलाह का पालन करें
2. दवाइयां समय पर लें: डॉक्टर जो भी दवाइयां दें, उन्हें बिना भूले समय पर लें
3. पूरा आराम करें: शरीर को ठीक होने के लिए समय दें
4. खूब पानी पिएं: तरल पदार्थ पीने से आपको जल्दी ठीक होने में मदद मिलेगी
5. संपर्क में रहें: डॉक्टर के साथ नियमित संपर्क बनाए रखें

याद रखें: यह एक प्रारंभिक जांच है। पूरी जांच के लिए अपने डॉक्टर से मिलें।''';
    }
  }

  /// Save PDF to device and return file path
  static Future<String> savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Share or view PDF
  static Future<void> viewPDF(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: title,
    );
  }
}
