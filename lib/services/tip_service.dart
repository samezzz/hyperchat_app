import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

class TipService {
  late final GenerativeModel _model;

  TipService() {
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
  }

  Future<String> getDailyTip() async {
    try {
      final prompt = '''
Generate a single, concise, and practical tip for managing hypertension or improving heart health. 
The tip should be:
- Easy to understand and implement
- Based on medical best practices
- No more than 2-3 sentences
- Focus on lifestyle, diet, exercise, or stress management
- Include a brief explanation of why it's beneficial

Format the response as just the tip, without any additional text or formatting.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate tip at this time.';
    } catch (e) {
      print('Tip Generation Error: $e');
      return 'Unable to generate tip at this time. Please try again later.';
    }
  }
} 