// lib/services/language_manager.dart
import 'package:flutter/material.dart';

class LanguageManager {
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  final ValueNotifier<String> languageCodeNotifier = ValueNotifier<String>(
    'en',
  );

  void setLanguageCode(String newLanguageCode) {
    languageCodeNotifier.value = newLanguageCode;
  }
}
