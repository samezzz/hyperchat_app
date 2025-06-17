import 'package:flutter/material.dart';
import 'dart:convert';
import '../../common/colo_extension.dart';
import '../../services/gemini_service.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  bool _isTyping = false;
  bool _isLoadingQuestions = true;

  List<Map<String, dynamic>> _suggestedQuestions = [];

  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'message': 'Hello! I\'m HyperBot, your hypertension support AI. How can I help you today?',
      'timestamp': '10:30 AM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      final prompt = '''
Generate 4 relevant questions about hypertension and blood pressure management. 
For each question:
1. Include an appropriate emoji
2. Keep the question concise and clear
3. Make it specific to hypertension/BP management
4. Format as JSON array with 'icon' and 'text' fields

Example format:
[
  {"icon": "🍎", "text": "What foods lower BP?"},
  {"icon": "🚨", "text": "What's a hypertensive crisis?"}
]

Return only the JSON array, nothing else. Do not include any markdown formatting or code blocks.
''';

      final response = await _geminiService.getResponse(prompt);
      
      // Clean the response by removing markdown code blocks and any extra whitespace
      String cleanResponse = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      // Parse the response as JSON
      final List<dynamic> questions = json.decode(cleanResponse);
      
      if (mounted) {
        setState(() {
          _suggestedQuestions = questions.cast<Map<String, dynamic>>();
          _isLoadingQuestions = false;
        });
      }
    } catch (e) {
      print('Error generating questions: $e');
      // Fallback to default questions if generation fails
      if (mounted) {
        setState(() {
          _suggestedQuestions = [
            {
              'icon': '🍎',
              'text': 'What foods lower BP?',
            },
            {
              'icon': '🚨',
              'text': "What's a hypertensive crisis?",
            },
            {
              'icon': '📊',
              'text': 'Explain my last reading',
            },
            {
              'icon': '💊',
              'text': 'Can I mix meds with coffee?',
            },
          ];
          _isLoadingQuestions = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add({
        'isBot': false,
        'message': userMessage,
        'timestamp': DateTime.now().toString().substring(11, 16),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Get response from Gemini
    final response = await _geminiService.getResponse(userMessage);
    
    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'isBot': true,
          'message': response,
          'timestamp': DateTime.now().toString().substring(11, 16),
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);
    
    return Scaffold(
      backgroundColor: TColor.bgColor,
      appBar: AppBar(
        backgroundColor: TColor.bgColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TColor.primaryColor1,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  '🤖',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HyperBot',
                  style: TextStyle(
                    color: TColor.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: TColor.subTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Suggested Questions Carousel
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Stack(
              children: [
                if (_isLoadingQuestions)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _suggestedQuestions.length,
                    itemBuilder: (context, index) {
                      final question = _suggestedQuestions[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            _messageController.text = question['text'];
                            _sendMessage();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? TColor.darkSurface : TColor.white,
                            foregroundColor: TColor.textColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: TColor.subTextColor.withAlpha(77),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                question['icon'],
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                question['text'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                Positioned(
                  right: 10,
                  top: 0,
                  child: IconButton(
                    onPressed: _generateQuestions,
                    icon: Icon(
                      Icons.refresh,
                      color: TColor.primaryColor1,
                    ),
                    tooltip: 'Refresh questions',
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            decoration: BoxDecoration(
              color: TColor.bgColor,
              boxShadow: [
                BoxShadow(
                  color: TColor.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: TColor.subTextColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? TColor.darkSurface : TColor.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: TColor.primaryColor1,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(
                      Icons.send,
                      color: TColor.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isBot = message['isBot'] as bool;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TColor.primaryColor1,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  '🤖',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isBot
                    ? (isDarkMode ? TColor.darkSurface : TColor.white)
                    : TColor.primaryColor1,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'],
                    style: TextStyle(
                      color: isBot ? TColor.textColor : TColor.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['timestamp'],
                    style: TextStyle(
                      color: isBot ? TColor.subTextColor : TColor.white.withAlpha(179),
                      fontSize: 12,
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

  Widget _buildTypingIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TColor.primaryColor1,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '🤖',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? TColor.darkSurface : TColor.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: TColor.subTextColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
} 