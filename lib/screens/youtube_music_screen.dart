// lib/screens/youtube_music_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingoworld/services/language_manager.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YoutubeMusicScreen extends StatelessWidget {
  const YoutubeMusicScreen({super.key});

  Future<List<Map<String, String>>> _searchMusic(
    String query, {
    int maxResults = 5,
  }) async {
    final String _apiKey = dotenv.env['YOUTUBE_API_KEY']!;
    final Uri uri = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet'
      '&q=$query'
      '&type=video'
      '&videoCategoryId=10'
      '&maxResults=$maxResults'
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
      throw Exception('Müzik çekme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Müzik Keşfet', style: GoogleFonts.montserrat()),
        backgroundColor: const Color.fromARGB(255, 101, 98, 98),
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: LanguageManager().languageCodeNotifier,
        builder: (context, languageCode, child) {
          final Map<String, String> languageMap = {
            'en': 'English',
            'de': 'German',
            'fr': 'French',
            'es': 'Spanish',
            'it': 'Italian',
            'ja': 'Japanese',
            'zh': 'Chinese',
            'ko': 'Korean',
            'ru': 'Russian',
          };

          final String languageName = languageMap[languageCode] ?? 'music';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Öğretici Müzikler',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A90E2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMusicList(
                    _searchMusic('learn $languageName songs for beginners'),
                    'Öğretici müzik bulunamadı.',
                    context,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Popüler Müzikler',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A90E2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMusicList(
                    _searchMusic('popular music in $languageName'),
                    'Popüler müzik bulunamadı.',
                    context,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMusicList(
    Future<List<Map<String, String>>> future,
    String noDataMessage,
    BuildContext context,
  ) {
    return FutureBuilder<List<Map<String, String>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Müzik yüklenirken bir hata oluştu: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: Colors.red),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              noDataMessage,
              style: GoogleFonts.montserrat(fontSize: 18),
            ),
          );
        } else {
          final videos = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: ListTile(
                  leading: Image.network(video['thumbnailUrl']!),
                  title: Text(
                    video['title']!,
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                VideoPlayerScreen(videoId: video['videoId']!),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}

// Video oynatıcı ekranı
class VideoPlayerScreen extends StatelessWidget {
  final String videoId;
  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Oynatıcı', style: GoogleFonts.montserrat()),
      ),
      body: Center(
        child: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.blueAccent,
        ),
      ),
    );
  }
}
