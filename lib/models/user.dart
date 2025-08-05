// lib/models/user.dart
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User extends HiveObject {
  @HiveField(0)
  String email;
  @HiveField(1)
  String password;
  @HiveField(2)
  List<String> targetLanguages;

  User({
    required this.email,
    required this.password,
    this.targetLanguages = const [],
  });
}
