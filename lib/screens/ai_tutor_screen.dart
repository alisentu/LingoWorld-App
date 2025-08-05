// lib/screens/ai_tutor_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lingoworld/constants/app_colors.dart';

class AiTutorScreen extends StatefulWidget {
  final String targetLanguage;

  const AiTutorScreen({super.key, required this.targetLanguage});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: dotenv.env['CHAT_BOT_KEY']!,
    );

    // AI Promt Örneği
    _chat = _model.startChat(
      history: [
        Content.text("""
        Sen bir dil öğretmenisin ve ${widget.targetLanguage} dilini öğrenen bir öğrenciye yardım ediyorsun.
        Öğrenciye her zaman ${widget.targetLanguage} dilinde cevap ver.
        Aşağıdaki kuralları dikkate alarak cevap ver:
        
        1. Öğrenci ${widget.targetLanguage} dilinde bir cümle gönderdiğinde, gramerini düzelt, daha doğal bir alternatif sun ve Türkçe çevirisini ekle.
        2. Öğrenci Türkçe bir ifadeyle anlamadığını belirtirse (örneğin "türkçesi ne?", "anlamadım" gibi), son ${widget.targetLanguage} yanıtını Türkçe olarak tekrar açıkla.
        3. Yanıtını kısa ve motive edici tut.
        4. Yeni bir sohbet konusu başlatmak için günlük konuşma dilinde bir soru sor. Eğer öğrenci anlamsız veya yanlış bir cevap verirse, onu düzelt ve Türkçe'sini de vererek yeni bir soruyla devam et.
        
        Örnekler:
        Öğrenci: I goed to the park.
        Sen: That's a great try! A more natural way to say that is, "I went to the park." (Parka gittim.) What did you do at the park?
        
        Öğrenci: türkçesi ne?
        Sen: "I went to the park" ifadesi "Parka gittim" anlamına gelir. What did you do at the park?
      """),
      ],
    );

    _messages.add({
      'sender': 'AI',
      'text':
          '${widget.targetLanguage} öğrenmenize yardımcı olmak için buradayım. Başlayalım!',
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Mesaj gönderme fonksiyonu
  void _sendMessage() async {
    final userMessage = _textController.text;
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': userMessage});
      _textController.clear();
      _isLoading = true;
    });

    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      final aiResponse = response.text;

      setState(() {
        _isLoading = false;
        if (aiResponse != null) {
          _messages.add({'sender': 'AI', 'text': aiResponse});
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'sender': 'AI',
          'text': 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin. Hata: $e',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.targetLanguage} Öğretmeni',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isUser
                              ? AppColors.tertiary.withAlpha(
                                (0.8 * 255).round(),
                              )
                              : AppColors.secondary.withAlpha(
                                (0.8 * 255).round(),
                              ),
                      borderRadius:
                          isUser
                              ? const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              )
                              : const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                    ),
                    child: Text(
                      message['text']!,
                      style: GoogleFonts.montserrat(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Bir cümle yazın...',
                  hintStyle: GoogleFonts.montserrat(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(19, 140, 128, 128),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
