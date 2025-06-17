import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    // Initialize the model with your API key
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: ApiConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    _chat = _model.startChat(
      history: [
        Content.text('You are HyperBot, a helpful AI assistant focused on hypertension and blood pressure management. Provide clear, brief, accurate, and supportive responses to user questions about health, blood pressure, and related topics. Use simple language and avoid using complex words because your audience is not very technical.'),
      ],
    );
  }

  Future<String> getResponse(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return _formatResponse(response.text ?? 'Sorry, I could not generate a response.');
    } catch (e) {
      print('Gemini API Error: $e'); // For debugging
      return 'I apologize, but I\'m having trouble connecting right now. Please try again in a moment.';
    }
  }

  String _formatResponse(String text) {
    // Remove markdown-style formatting
    text = text.replaceAll('**', '');
    
    // Ensure proper spacing after bullet points
    text = text.replaceAll('* ', '• ');
    
    // Add proper line breaks
    text = text.replaceAll('. ', '.\n');
    
    // Clean up any double line breaks
    text = text.replaceAll('\n\n', '\n');
    
    // Ensure proper spacing after colons
    text = text.replaceAll(':', ': ');
    
    // Trim any extra whitespace
    text = text.trim();
    
    return text;
  }

  void resetChat() {
    _chat = _model.startChat(
      history: [
        Content.text('You are HyperBot, a helpful AI assistant focused on hypertension and blood pressure management. Provide clear, accurate, and supportive responses to user questions about health, blood pressure, and related topics.'),
      ],
    );
  }
} 