// lib/services/gemini_explain_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiExplainService {
  late final GenerativeModel _model;
  static final GeminiExplainService _instance =
      GeminiExplainService._internal();

  factory GeminiExplainService() {
    return _instance;
  }

  GeminiExplainService._internal() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );
  }

  Future<String> getExplanation({
    required String language,
    required String level,
    required String question,
    required String correctAnswer,
    required String userAnswer,
  }) async {
    final prompt = """
    The user is learning $language at the $level level.
    They answered a question incorrectly.
    The question was: "$question"
    The user's answer was: "$userAnswer"
    The correct answer was: "$correctAnswer"

    Provide a concise and helpful explanation in Turkish (maximum 50 words) about why the correct answer is what it is.
    Focus on the relevant grammar rule, vocabulary, or sentence structure.
    Do not mention the user's wrong answer directly, just explain the correct one.
    Start with "Doğru cevap '$correctAnswer' olmalıydı çünkü...".
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Açıklama bulunamadı.';
    } catch (e) {
      print('Açıklama alınırken hata oluştu: $e');
      return 'Açıklama alınırken bir hata oluştu.';
    }
  }
}
