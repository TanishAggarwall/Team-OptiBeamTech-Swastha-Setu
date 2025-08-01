import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/ml_service.dart';
import '../services/pdf_service.dart';
import '../theme.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = false;
  bool _modelHealthy = true;
  Map<String, dynamic>? _modelInfo;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkModelHealth();
    _loadModelInfo();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut)
    );
  }

  Future<void> _checkModelHealth() async {
    final isHealthy = await MLService.checkModelHealth();
    setState(() {
      _modelHealthy = isHealthy;
    });
  }

  Future<void> _loadModelInfo() async {
    final info = await MLService.getModelInfo();
    setState(() {
      _modelInfo = info;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _analysisResult = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    _fadeController.reset();
    _scaleController.reset();

    try {
      final result = await MLService.predictDisease(
        imageFile: _selectedImage!,
        analysisType: 'medical_imaging',
      );

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      if (result['success'] == true) {
        _fadeController.forward();
        _scaleController.forward();
        _showNotification('SwasthaSetu AI analysis completed: ${result['diagnosis']}');
      } else {
        _showErrorNotification('Analysis failed: ${result['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorNotification('Error during analysis: $e');
    }
  }

  Future<void> _generatePDFReport() async {
    if (_analysisResult == null) {
      _showNotification('No analysis result available for PDF generation');
      return;
    }

    final patientDetails = await _showPatientDetailsDialog();
    if (patientDetails == null) return;

    try {
      _showNotification('Generating professional PDF report...');

      final reportId = 'SWASTHA-${DateTime.now().millisecondsSinceEpoch}';
      
      final pdfBytes = await PDFService.generateDiagnosticReport(
        patientDetails: patientDetails,
        analysisResult: _analysisResult!,
        reportId: reportId,
      );

      final fileName = 'SwasthaSetu_Report_${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf';
      
      await PDFService.viewPDF(pdfBytes, 'SwasthaSetu Diagnostic Report');
      
      final filePath = await PDFService.savePDFToDevice(pdfBytes, fileName);
      _showNotification('PDF report saved successfully at: $filePath');

    } catch (e) {
      _showErrorNotification('Failed to generate PDF: $e');
    }
  }

  // ✅ FIXED: Patient Details Dialog with overflow fixes
  Future<Map<String, dynamic>?> _showPatientDetailsDialog() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final weightController = TextEditingController();
    final bloodGroupController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded( // ✅ FIX: Wrap title in Expanded
              child: Text(
                'Patient Details for PDF Report',
                maxLines: 2, // ✅ FIX: Limit lines
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox( // ✅ FIX: Constrain dialog width
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView( // ✅ FIX: Make scrollable
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '👤 Patient Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    contentPadding: EdgeInsets.symmetric( // ✅ FIX: Reduce padding
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14), // ✅ FIX: Reduce spacing
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(
                    labelText: '🎂 Age *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: '⚖️ Weight (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: bloodGroupController,
                  decoration: const InputDecoration(
                    labelText: '🩸 Blood Group (e.g., A+, B-, O+)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bloodtype),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10), // ✅ FIX: Reduce spacing
                Container(
                  padding: const EdgeInsets.all(10), // ✅ FIX: Reduce padding
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.primaryBlue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '* Required fields for professional report',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                          ),
                          maxLines: 2, // ✅ FIX: Allow text wrapping
                        ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (nameController.text.isEmpty || ageController.text.isEmpty) {
                _showNotification('Please fill all required fields (Name and Age)');
                return;
              }
              
              Navigator.pop(context, {
                'name': nameController.text,
                'age': ageController.text,
                'weight': weightController.text.isEmpty ? 'Not specified' : weightController.text,
                'bloodGroup': bloodGroupController.text.isEmpty ? 'Not specified' : bloodGroupController.text,
              });
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded( // ✅ FIX: Wrap in Expanded
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SwasthaSetu AI Detection',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1, // ✅ FIX: Limit lines
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _modelHealthy ? 'Live AI Models Online' : 'Models Offline',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _modelHealthy ? AppTheme.healthGreen : AppTheme.errorRed,
                    ),
                    maxLines: 1, // ✅ FIX: Limit lines
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        toolbarHeight: 70, // ✅ FIX: Reduce from 72 to 70
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showModelInfo,
            tooltip: 'Model Information',
          ),
        ],
      ),
      body: SafeArea( // ✅ FIX: Wrap body in SafeArea
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModelStatusCard(),
              const SizedBox(height: 20),
              _buildImageSelectionCard(),
              if (_selectedImage != null) ...[
                const SizedBox(height: 20),
                _buildSelectedImageCard(),
              ],
              if (_isAnalyzing) ...[
                const SizedBox(height: 20),
                _buildAnalysisProgress(),
              ],
              if (_analysisResult != null && !_isAnalyzing) ...[
                const SizedBox(height: 20),
                _buildAnalysisResultCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelStatusCard() {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _modelHealthy ? AppTheme.healthGreen : AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _modelHealthy ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SwasthaSetu AI Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1, // ✅ FIX: Limit lines
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _modelHealthy ? 'Connected to Live Models' : 'Connection Issues',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _modelHealthy ? AppTheme.healthGreen : AppTheme.errorRed,
                      ),
                      maxLines: 1, // ✅ FIX: Limit lines
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_modelInfo != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API: ${_modelInfo!['model_name'] ?? 'SwasthaSetu AI'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Version: ${_modelInfo!['version'] ?? '1.0'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Models: Pneumonia, TB, Malaria Detection',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Platform: ${_modelInfo!['platform'] ?? 'Render'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSelectionCard() {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Medical Image',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload chest X-ray or blood smear for AI disease detection',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2, // ✅ FIX: Limit lines
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImageCard() {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Medical Image',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeImage,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.psychology),
              label: Text(_isAnalyzing ? 'Analyzing with SwasthaSetu AI...' : 'Analyze with SwasthaSetu AI'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisProgress() {
    return MedicalCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: SpinKitRipple(
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SwasthaSetu AI Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Processing with trained Pneumonia, TB, and Malaria detection models',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 3, // ✅ FIX: Limit lines
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            backgroundColor: AppTheme.backgroundGray,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Analysis Result Card with overflow fixes
  Widget _buildAnalysisResultCard() {
    if (_analysisResult == null) return const SizedBox.shrink();

    final bool isSuccess = _analysisResult!['success'] == true;
    final bool hasDisease = _analysisResult!['hasDisease'] ?? false;
    final String diagnosis = _analysisResult!['diagnosis'] ?? 'Unknown';
    final String confidence = _analysisResult!['confidence'] ?? 'Low';
    final Map<String, double> aiAnalysis = 
        Map<String, double>.from(_analysisResult!['aiAnalysis'] ?? {});

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: MedicalCard(
          child: SingleChildScrollView( // ✅ FIX: Make scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasDisease ? AppTheme.errorRed : AppTheme.healthGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasDisease ? Icons.warning_rounded : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded( // ✅ FIX: Wrap in Expanded
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SwasthaSetu AI Analysis',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1, // ✅ FIX: Limit lines
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Confidence: $confidence',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1, // ✅ FIX: Limit lines
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Main Diagnosis
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints( // ✅ FIX: Add constraints
                    maxHeight: 120,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: hasDisease 
                        ? AppTheme.errorRed.withOpacity(0.1)
                        : AppTheme.healthGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasDisease ? AppTheme.errorRed : AppTheme.healthGreen,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // ✅ FIX: Center content
                    children: [
                      Flexible( // ✅ FIX: Make text flexible
                        child: Text(
                          diagnosis,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: hasDisease ? AppTheme.errorRed : AppTheme.healthGreen,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2, // ✅ FIX: Limit lines
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Analyzed by your trained AI models',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                        maxLines: 2, // ✅ FIX: Limit lines
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                if (aiAnalysis.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'AI Model Predictions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...aiAnalysis.entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2, // ✅ FIX: Give more space to text
                            child: Text(
                              entry.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 80 * (entry.value / 100),
                                  decoration: BoxDecoration(
                                    color: _getScoreColor(entry.key),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox( // ✅ FIX: Use SizedBox instead of Container
                            width: 60,
                            child: Text(
                              '${entry.value.toStringAsFixed(1)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.refresh),
                        label: const Text('New Analysis'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generatePDFReport,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Generate Report'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Medical Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        color: AppTheme.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medical Disclaimer',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.warningOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This AI analysis is for screening purposes only. Please consult a qualified healthcare professional for proper diagnosis and treatment.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                height: 1.4,
                              ),
                              maxLines: 4, // ✅ FIX: Limit lines
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(String disease) {
    switch (disease.toLowerCase()) {
      case 'pneumonia':
        return AppTheme.errorRed;
      case 'tuberculosis':
        return AppTheme.warningOrange;
      case 'malaria':
        return Colors.purple;
      case 'normal':
        return AppTheme.healthGreen;
      default:
        return AppTheme.primaryBlue;
    }
  }

  void _showModelInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            const Expanded( // ✅ FIX: Wrap in Expanded
              child: Text(
                'SwasthaSetu AI Models',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView( // ✅ FIX: Make scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your deployed AI models analyze medical images for:',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _buildInfoItem('🫁', 'Pneumonia Detection'),
              _buildInfoItem('🦠', 'Tuberculosis (TB) Detection'),
              _buildInfoItem('🩸', 'Malaria Detection'),
              _buildInfoItem('✅', 'Normal condition'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Powered by your trained EfficientNet and ResNet models deployed on Render',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3, // ✅ FIX: Limit lines
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded( // ✅ FIX: Wrap in Expanded
            child: Text(
              text, 
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotification(String message) {
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

  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ✅ MedicalCard Widget
class MedicalCard extends StatelessWidget {
  final Widget child;

  const MedicalCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}
