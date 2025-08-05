import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YoutubeService {
  static Future<List<Map<String, String>>> searchEducationalVideos(
    String languageCode,
  ) async {
    final String _apiKey = dotenv.env['YOUTUBE_API_KEY']!;
    final Map<String, String> turkishLanguageNames = {
      'en': 'İngilizce',
      'de': 'Almanca',
      'es': 'İspanyolca',
      'fr': 'Fransızca',
      'it': 'İtalyanca',
      'ja': 'Japonca',
      'zh': 'Çince',
      'ko': 'Korece',
      'ru': 'Rusça',
    };
    final String targetLanguageName = turkishLanguageNames[languageCode] ?? '';
    String query = '$targetLanguageName dersleri Türkçe';
    if (targetLanguageName.isEmpty) {
      return [];
    }

    final Uri uri = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet'
      '&q=$query'
      '&type=video'
      '&maxResults=25'
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'];

        return items.map((item) {
          final snippet = item['snippet'];
          final videoId = item['id']['videoId'];
          return {
            'title': snippet['title'].toString(),
            'thumbnailUrl': snippet['thumbnails']['high']['url'].toString(),
            'videoId': videoId.toString(),
          };
        }).toList();
      } else {
        throw Exception(
          'API hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Video çekme hatası: $e');
    }
  }
}
