// lib/services/gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  late GenerativeModel _model;
  late Box _settingsBox;
  late Box _wordsBox;

  GeminiService._internal() {
    _settingsBox = Hive.box('settingsBox');
    _wordsBox = Hive.box('wordsBox');

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception(
        'GEMINI_API_KEY bulunamadı. Lütfen .env dosyasını kontrol edin.',
      );
    }
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  // Kelime alma metodu
  Future<List<Map<String, String>>> getWords(String targetLanguage) async {
    print(
      '$targetLanguage için yeni kelimeler oluşturuluyor (Gemini API çağrısı)...',
    );

    // Prompt metni
    final prompt = """
    Target Language: $targetLanguage
    Source Language: Turkish

    Please provide 50 common words in the Target Language with their Turkish translations.
    For each word, also provide a simple example sentence in the Target Language AND its Turkish translation.
    Format the output as a JSON array of objects, where each object has four properties: "word", "meaning", "example", and "example_translation".
    The "word" field should be the target language word, the "meaning" field should be its Turkish translation, the "example" field should be a simple example sentence in the target language, and "example_translation" should be the Turkish translation of the example sentence.
    Do NOT include any other text or formatting outside the JSON array.

    Example for English:
    [
      {"word": "hello", "meaning": "merhaba", "example": "Hello, how are you?", "example_translation": "Merhaba, nasılsın?"},
      {"word": "world", "meaning": "dünya", "example": "The world is big.", "example_translation": "Dünya büyük."},
      {"word": "apple", "meaning": "elma", "example": "I like to eat apples.", "example_translation": "Elma yemeyi severim."}
    ]
    """;

    // Yeniden deneme için parametreler
    int maxRetries = 3; // Maksimum 3 kez yeniden dene
    Duration initialDelay = const Duration(
      seconds: 1,
    ); // Başlangıç gecikmesi 1 saniye

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);
        final text = response.text;

        if (text == null || text.isEmpty) {
          print(
            'Gemini\'den boş yanıt geldi (Deneme ${attempt + 1}/$maxRetries).',
          );
          if (attempt < maxRetries - 1) {
            // Son deneme değilse, bekleyip tekrar dene
            await Future.delayed(
              initialDelay * (attempt + 1),
            ); // Gecikmeyi artır
            continue; // Bir sonraki denemeye geç
          }
          return []; // Tüm denemeler başarısız oldu
        }

        String cleanedText = text.trim();
        if (cleanedText.startsWith('```json')) {
          cleanedText = cleanedText.substring(7);
        }
        if (cleanedText.endsWith('```')) {
          cleanedText = cleanedText.substring(0, cleanedText.length - 3);
        }
        cleanedText = cleanedText.trim();

        final List<dynamic> jsonList = jsonDecode(cleanedText);

        List<Map<String, String>> words = [];
        for (var item in jsonList) {
          if (item is Map<String, dynamic> &&
              item.containsKey('word') &&
              item.containsKey('meaning') &&
              item.containsKey('example') &&
              item.containsKey('example_translation')) {
            words.add({
              'word': item['word'].toString(),
              'meaning': item['meaning'].toString(),
              'example': item['example'].toString(),
              'example_translation': item['example_translation'].toString(),
            });
          }
        }
        print('Kelime başarıyla çekildi (Deneme ${attempt + 1}/$maxRetries).');
        return words; // Başarılı, kelimeleri döndür
      } on GenerativeAIException catch (e) {
        // Gemini API'sinden gelen hatalar
        print(
          'Kelime çekerken Gemini API hatası (Deneme ${attempt + 1}/$maxRetries): $e',
        );
        if (attempt < maxRetries - 1) {
          await Future.delayed(initialDelay * (attempt + 1));
          continue;
        }
        return [];
      } on SocketException catch (e) {
        // Ağ bağlantısı hataları
        print('Ağ bağlantısı hatası (Deneme ${attempt + 1}/$maxRetries): $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(initialDelay * (attempt + 1));
          continue;
        }
        return [];
      } catch (e) {
        // Diğer beklenmedik hatalar
        print('Beklenmedik hata (Deneme ${attempt + 1}/$maxRetries): $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(initialDelay * (attempt + 1));
          continue;
        }
        return [];
      }
    }
    return []; // Tüm denemeler başarısız olursa boş liste döndür
  }

  // Kelimeleri Hive'a kaydet ve hangi dile ait olduğunu da belirt
  Future<void> saveWords(
    List<Map<String, String>> words,
    String targetLanguage,
  ) async {
    await _wordsBox.clear();
    await _wordsBox.put('currentWords', words);
    await _settingsBox.put('lastFetchedLanguage', targetLanguage);
    print(
      'Kelime listesi Hive\'a kaydedildi. Toplam ${words.length} kelime. Dil: $targetLanguage',
    );
  }

  List<Map<String, String>> getSavedWords() {
    final List<dynamic>? saved = _wordsBox.get('currentWords');
    if (saved != null) {
      return saved.cast<Map<dynamic, dynamic>>().map((item) {
        return item.cast<String, String>();
      }).toList();
    }
    return [];
  }

  // En son hangi dilin kelimelerinin çekildiğini döndüren metot
  String? getLastFetchedLanguage() {
    return _settingsBox.get('lastFetchedLanguage');
  }
}
