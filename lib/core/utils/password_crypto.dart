import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;

import '../constants/app_constants.dart';

class PasswordCrypto {
  PasswordCrypto._();

  static String encryptPassword(String plain) {
    final key = encrypt.Key.fromUtf8(AppConstants.encryptionKey);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    return base64.encode([...iv.bytes, ...encrypted.bytes]);
  }

  static String decryptPassword(String encryptedBase64) {
    final key = encrypt.Key.fromUtf8(AppConstants.encryptionKey);
    final raw = base64.decode(encryptedBase64);
    final iv = encrypt.IV(raw.sublist(0, 16));
    final cipherText = encrypt.Encrypted(raw.sublist(16));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt(cipherText, iv: iv);
  }
}
