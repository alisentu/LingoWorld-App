// lib/screens/youtube_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingoworld/services/youtube_service.dart';
import 'package:lingoworld/services/language_manager.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeScreen extends StatelessWidget {
  const YoutubeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Youtube Öğretici İçerikler',
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: const Color(0xFF4A4A4A),
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: LanguageManager().languageCodeNotifier,
        builder: (context, languageCode, child) {
          if (languageCode.isEmpty) {
            return Center(
              child: Text(
                'Lütfen önce bir hedef dil seçin.',
                style: GoogleFonts.montserrat(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }

          return FutureBuilder<List<Map<String, String>>>(
            future: YoutubeService.searchEducationalVideos(languageCode),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Video yüklenirken bir hata oluştu: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.red),
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'Bu dil için eğitici video bulunamadı.',
                    style: GoogleFonts.montserrat(fontSize: 18),
                  ),
                );
              } else {
                final videos = snapshot.data!;
                return ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    final isDarkMode =
                        Theme.of(context).brightness == Brightness.dark;

                    return Card(
                      color:
                          isDarkMode
                              ? const Color.fromARGB(255, 101, 98, 98)
                              : Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color:
                              isDarkMode
                                  ? const Color.fromARGB(255, 253, 253, 253)
                                  : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Image.network(video['thumbnailUrl']!),
                        title: Text(
                          video['title']!,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => VideoPlayerScreen(
                                    videoId: video['videoId']!,
                                  ),
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
        },
      ),
    );
  }
}

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
