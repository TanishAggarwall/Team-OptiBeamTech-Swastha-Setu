import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _systemPrompt = '';
  late AnimationController _animationController;

  // 🔑 SARVAM AI API KEY
  static const String _sarvamApiKey = 'sk_0w9o2b0g_2fTVeWowgXFUOcX7VDZHLdbn';
  static const String _sarvamBaseUrl = 'https://api.sarvam.ai/v1';

  // Professional quick medical queries (Hindi/English mix for Indian users)
  final List<QuickQuery> _quickQueries = [
    QuickQuery('🫁', 'Pneumonia के लक्षण?', 'What are the main symptoms of pneumonia?'),
    QuickQuery('🦠', 'TB कैसे फैलता है?', 'How is tuberculosis transmitted?'),
    QuickQuery('😷', 'COVID बचाव?', 'How to prevent COVID-19 infection?'),
    QuickQuery('🔬', 'X-ray पढ़ना?', 'How to read chest X-ray basics?'),
    QuickQuery('🩺', 'डॉक्टर कब दिखाएं?', 'When should I see a doctor for persistent cough?'),
    QuickQuery('💊', 'Pneumonia प्रकार?', 'Difference between viral and bacterial pneumonia?'),
    QuickQuery('⏰', 'TB इलाज समय?', 'How long does TB treatment take?'),
    QuickQuery('🤧', 'COVID vs सर्दी?', 'COVID-19 symptoms vs common cold?'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _setSystemPrompt();
    _testSarvamConnection();
    _addWelcomeMessage();
  }

  void _setSystemPrompt() {
    _systemPrompt = '''
You are Dr. SwasthaSetu, a professional AI medical assistant specialized in Indian healthcare, particularly:
- Tuberculosis (TB) - भारत में TB
- Pneumonia - निमोनिया
- Malaria - मलेरिया
- Chest X-ray analysis - छाती का X-ray
- General respiratory health - सांस संबंधी स्वास्थ्य

Professional Guidelines for Indian Context:
1. Provide culturally appropriate medical information for Indian patients
2. Consider Indian healthcare system, AYUSH, and government health schemes
3. Always remind users to consult healthcare professionals (सरकारी अस्पताल, PHC, CHC)
4. Explain medical terms in both Hindi and English when helpful
5. Be empathetic, supportive, and professional
6. Include information about government health programs when relevant (DOTS, Ayushman Bharat)
7. Keep responses concise but comprehensive (2-3 paragraphs max)
8. Include Indian statistics or regional health facts when helpful

Remember: You assist with medical information but cannot replace professional medical advice. Always emphasize consulting qualified healthcare providers including government hospitals and primary health centers.
''';
  }

  Future<void> _testSarvamConnection() async {
    try {
      print('🔄 Testing Sarvam AI connection...');
      final response = await _callSarvamAPI('Hello, respond with "Dr. SwasthaSetu is ready to assist!"');
      if (response['success']) {
        print('✅ Sarvam AI working! Response: ${response['response']}');
      } else {
        print('⚠️ Sarvam AI test failed: ${response['error']}');
      }
    } catch (e) {
      print('❌ Sarvam AI connection error: $e');
    }
  }

  Future<Map<String, dynamic>> _callSarvamAPI(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_sarvamBaseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_sarvamApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'sarvam-m',
          'messages': [
            {
              'role': 'system',
              'content': _systemPrompt,
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'max_tokens': 600,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'response': data['choices'][0]['message']['content'],
        };
      } else {
        throw Exception('Sarvam API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'response': 'I apologize, but I\'m having trouble processing your request right now. Please try again or consult with a healthcare professional.',
      };
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: '''🙏 **नमस्ते! I'm Dr. SwasthaSetu, your AI Medical Assistant**

मैं भारतीय स्वास्थ्य देखभाल में विशेषज्ञ हूं और आपकी मदद कर सकता हूं:

🫁 **श्वसन रोग** - TB, Pneumonia, COVID-19  
🔬 **छाती का X-ray** - रिपोर्ट समझना  
💊 **उपचार मार्गदर्शन** - दवाएं और थेरेपी  
🏥 **कब दिखाना है** - तत्काल लक्षण और सलाह  
🇮🇳 **सरकारी योजनाएं** - DOTS, Ayushman Bharat, PHC सेवाएं  

**Quick Start:** नीचे कोई भी प्रश्न दबाएं या मुझसे सीधे पूछें!

⚠️ **महत्वपूर्ण:** यह जानकारी शिक्षा के लिए है। निदान और इलाज के लिए हमेशा योग्य डॉक्टर या सरकारी अस्पताल से सलाह लें।''',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String contextualMessage = '''
Patient question: $message

Please respond as Dr. SwasthaSetu following the professional guidelines for Indian healthcare context. Provide helpful, culturally appropriate medical information while emphasizing the need for professional medical consultation through government hospitals, PHCs, or private healthcare providers.
''';

      final result = await _callSarvamAPI(contextualMessage);
      
      setState(() {
        _messages.add(ChatMessage(
          text: result['response'] ?? 'I apologize, but I could not process your request at this time. Please try rephrasing your question or consult with a healthcare professional.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '''❌ **कनेक्शन समस्या / Connection Issue**
          
मुझे अभी तकनीकी कठिनाई हो रही है। यह हो सकता है:
- Network connectivity issues
- API service temporary unavailability

**तत्काल चिकित्सा चिंता के लिए:**
- अपने डॉक्टर से संपर्क करें
- Emergency के लिए 108 डायल करें
- नजदीकी PHC/CHC/सरकारी अस्पताल जाएं

मैं जल्द ही वापस ऑनलाइन आऊंगा। धन्यवाद।''',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      
      print('❌ Sarvam AI error in _sendMessage: $e');
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
              child: const Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded( // ✅ FIX: Wrap Column in Expanded
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. SwasthaSetu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1, // ✅ FIX: Limit lines
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Sarvam AI Powered Assistant',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
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
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.healthGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.healthGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sarvam AI',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.healthGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: SafeArea( // ✅ FIX: Wrap body in SafeArea
        child: Column(
          children: [
            _buildQuickQueries(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingMessage();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Quick Queries with overflow protection
  Widget _buildQuickQueries() {
    return Container(
      height: 95, // ✅ FIX: Reduce from 100 to 95
      padding: const EdgeInsets.symmetric(vertical: 10), // ✅ FIX: Reduce padding
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'त्वरित चिकित्सा प्रश्न / Quick Medical Questions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
              ),
              maxLines: 1, // ✅ FIX: Limit lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6), // ✅ FIX: Reduce spacing
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickQueries.length,
              itemBuilder: (context, index) {
                final query = _quickQueries[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 16 : 8,
                    right: index == _quickQueries.length - 1 ? 16 : 0,
                  ),
                  child: _buildQuickQueryChip(query),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQueryChip(QuickQuery query) {
    return GestureDetector(
      onTap: () {
        if (!_isLoading) {
          _sendMessage(query.fullText);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              query.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              query.shortText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
              maxLines: 1, // ✅ FIX: Limit lines
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible( // ✅ FIX: Use Flexible instead of Expanded for better overflow handling
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryBlue
                    : AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser 
                      ? const Radius.circular(20) 
                      : const Radius.circular(4),
                  bottomRight: message.isUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(20),
                ),
                boxShadow: message.isUser ? null : AppTheme.cardShadow,
                border: message.isUser ? null : Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : AppTheme.textDark,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: message.isUser
                            ? Colors.white.withOpacity(0.7)
                            : AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: message.isUser
                              ? Colors.white.withOpacity(0.7)
                              : AppTheme.textLight,
                        ),
                      ),
                      if (!message.isUser) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: AppTheme.healthGreen,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Sarvam AI',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.healthGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.medicalTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Flexible( // ✅ FIX: Use Flexible instead of Container
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: const Radius.circular(4),
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitThreeBounce(
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Flexible( // ✅ FIX: Wrap text in Flexible
                    child: Text(
                      'Dr. SwasthaSetu विश्लेषण कर रहा है...',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2, // ✅ FIX: Limit lines
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Dr. SwasthaSetu से अपने स्वास्थ्य के बारे में पूछें...',
                    hintStyle: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.medical_information_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  enabled: !_isLoading,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: _isLoading 
                    ? LinearGradient(colors: [Colors.grey, Colors.grey])
                    : AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: _isLoading ? null : [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                iconSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Info Dialog with overflow protection
  void _showInfoDialog() {
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
              child: const Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded( // ✅ FIX: Wrap title in Expanded
              child: Text(
                'About Dr. SwasthaSetu',
                maxLines: 1,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🤖 Sarvam AI Powered Medical Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2, // ✅ FIX: Limit lines
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _buildInfoFeature('भारतीय स्वास्थ्य', 'Indian healthcare system expertise'),
                _buildInfoFeature('बहुभाषी सहायता', 'Hindi/English medical consultation'),
                _buildInfoFeature('सरकारी योजनाएं', 'DOTS, Ayushman Bharat guidance'),
                _buildInfoFeature('24/7 उपलब्ध', 'Round-the-clock health support'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warningOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medical_information,
                            color: AppTheme.warningOrange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded( // ✅ FIX: Wrap text in Expanded
                            child: Text(
                              'चिकित्सा अस्वीकरण / Medical Disclaimer',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.warningOrange,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'केवल जानकारी के लिए। निदान और इलाज के लिए हमेशा डॉक्टर से सलाह लें। For informational purposes only. Always consult healthcare professionals.',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('समझ गया / Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1, // ✅ FIX: Limit lines
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2, // ✅ FIX: Limit lines
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'अभी';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class QuickQuery {
  final String emoji;
  final String shortText;
  final String fullText;

  QuickQuery(this.emoji, this.shortText, this.fullText);
}
