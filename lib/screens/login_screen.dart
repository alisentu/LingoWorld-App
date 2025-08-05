// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingoworld/models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  late Box<User> _userBox;
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _userBox = Hive.box<User>('userBox');
    _settingsBox = Hive.box('settingsBox');
    _loadRememberMe(); // Kayıtlı e-posta ve şifreyi yükle
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadRememberMe() {
    setState(() {
      _rememberMe =
          _settingsBox.get('rememberMeFlag', defaultValue: false) as bool;

      if (_rememberMe) {
        final rememberedEmail = _settingsBox.get('rememberedEmail');
        if (rememberedEmail != null && rememberedEmail is String) {
          final rememberedUser = _userBox.get(rememberedEmail);
          if (rememberedUser != null) {
            _emailController.text = rememberedUser.email;
            _passwordController.text = rememberedUser.password;
          }
        }
      }
    });
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('Giriş Yapılmaya Çalışılıyor: Email=$email, Password=***');

      if (_userBox.containsKey(email)) {
        final storedUser = _userBox.get(email);

        if (storedUser != null && storedUser.password == password) {
          print('Giriş Başarılı!');

          if (_rememberMe) {
            await _settingsBox.put('rememberMeFlag', true);
            await _settingsBox.put('rememberedEmail', email);
            print('Beni Hatırla aktif edildi.');
          } else {
            await _settingsBox.delete('rememberMeFlag');
            await _settingsBox.delete('rememberedEmail');
            print('Beni Hatırla pasif edildi.');
          }

          if (!mounted) return;
          // Başarılı girişten sonra dil seçim ekranına yönlendir.
          // Dil seçim ekranı, dil seçili değilse dil seçtirecek, seçiliyse /home'a gidecek.
          Navigator.pushReplacementNamed(context, '/select_language');
        } else {
          print('Giriş Başarısız: Şifre Hatalı.');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("E-posta veya şifre hatalı."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('Giriş Başarısız: Kullanıcı Bulunamadı.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bu e-posta ile kayıtlı bir kullanıcı bulunamadı."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('Giriş Başarısız: Form Doğrulaması Başarısız.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: size.height * 0.3,
                  width: double.infinity,
                  child: SvgPicture.asset(
                    'assets/svgs/wave.svg',
                    fit: BoxFit.fill,
                    colorFilter: const ColorFilter.mode(
                      Color.fromARGB(255, 255, 255, 255),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Positioned(
                  top: size.height * 0.15,
                  child: Text(
                    'Giriş Yap',
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 74, 74, 74),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Lütfen geçerli bir e-posta adresi girin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi girin.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                            ),
                            const Text('Beni Hatırla'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Şifremi unuttum özelliği yakında...',
                                ),
                              ),
                            );
                          },
                          child: const Text('Şifremi Unuttum'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(255, 74, 74, 74),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Giriş',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Henüz Hesabınız Yok Mu?'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text('Hesap Oluştur'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
