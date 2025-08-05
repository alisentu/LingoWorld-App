// lib/services/quiz_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lingoworld/models/question.dart';

class QuizService {
  late final GenerativeModel _model;
  static final QuizService _instance = QuizService._internal();

  factory QuizService() {
    return _instance;
  }

  QuizService._internal() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );
  }

  Future<List<Question>> fetchQuizQuestions(
    String language,
    String level,
  ) async {
    final prompt = """
    Create 10 varied language quiz questions for a learner of $language at the $level level.
    
    The questions must be asked in Turkish.
    The answer options and correct answers for multiple choice questions must be in Turkish.
    For fill-in-the-blank and translation questions, the answer should be in the $language language.

    The question types should be a mix of multiple choice, true/false, fill in the blank, and translation.
    The questions should cover vocabulary, sentence structure, and grammar.

    The response must be in a valid JSON array format, where each object has these fields:
    - type (string, one of 'multipleChoice', 'trueFalse', 'fillInTheBlank', 'translation')
    - text (string, the question text in Turkish)
    - options (array of strings, only for multipleChoice and trueFalse, options in Turkish)
    - correctAnswer (string, the correct answer, which could be in Turkish or the target language based on the question type)
    - level (string, the level of the question, e.g., 'A1')
    
    Example JSON for a multiple choice question:
    {
      "type": "multipleChoice",
      "text": "Aşağıdaki kelimelerden hangisi 'book' kelimesinin doğru Türkçe karşılığıdır?",
      "options": ["Kalem", "Kitap", "Silgi"],
      "correctAnswer": "Kitap",
      "level": "A1"
    }

    Example JSON for a fill-in-the-blank question:
    {
      "type": "fillInTheBlank",
      "text": "Fill in the blank with the correct verb: 'She ___ happy.'",
      "correctAnswer": "is",
      "level": "A1"
    }
    
    Example JSON for a translation question:
    {
        "type": "translation",
        "text": "Aşağıdaki Türkçe cümleyi $language diline çevirin: 'Ben okula giderim.'",
        "correctAnswer": "I go to school.",
        "level": "A1"
    }

    Please provide only the JSON array, without any additional text or formatting.
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final String? jsonString = response.text;

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final cleanedJsonString =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> jsonList = json.decode(cleanedJsonString);
      return jsonList.map((json) {
        return Question(
          type: QuestionType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
          ),
          text: json['text'],
          options:
              json['options'] != null
                  ? List<String>.from(json['options'])
                  : null,
          correctAnswer: json['correctAnswer'],
          level: json['level'],
        );
      }).toList();
    } catch (e) {
      print('AI\'dan soru alınırken hata oluştu: $e');
      return [];
    }
  }
}
