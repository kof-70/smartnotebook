import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const String _keyStorageKey = 'app_encryption_key';
  static const String _ivStorageKey = 'app_encryption_iv';
  
  final FlutterSecureStorage _secureStorage;
  late final Encrypter _encrypter;
  late final IV _iv;
  
  EncryptionService({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  Future<void> initialize() async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    
    _encrypter = Encrypter(AES(key));
    _iv = iv;
  }

  Future<Key> _getOrCreateKey() async {
    String? keyString = await _secureStorage.read(key: _keyStorageKey);
    
    if (keyString == null) {
      // Generate new 256-bit key
      final keyBytes = List<int>.generate(32, (i) => Random.secure().nextInt(256));
      keyString = base64Encode(keyBytes);
      await _secureStorage.write(key: _keyStorageKey, value: keyString);
    }
    
    return Key.fromBase64(keyString);
  }

  Future<IV> _getOrCreateIV() async {
    String? ivString = await _secureStorage.read(key: _ivStorageKey);
    
    if (ivString == null) {
      // Generate new 128-bit IV
      final ivBytes = List<int>.generate(16, (i) => Random.secure().nextInt(256));
      ivString = base64Encode(ivBytes);
      await _secureStorage.write(key: _ivStorageKey, value: ivString);
    }
    
    return IV.fromBase64(ivString);
  }

  String encryptText(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptText(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  Uint8List encryptBytes(Uint8List plainBytes) {
    final encrypted = _encrypter.encryptBytes(plainBytes, iv: _iv);
    return encrypted.bytes;
  }

  Uint8List decryptBytes(Uint8List encryptedBytes) {
    final encrypted = Encrypted(encryptedBytes);
    return Uint8List.fromList(_encrypter.decryptBytes(encrypted, iv: _iv));
  }

  Future<void> encryptFile(String inputPath, String outputPath) async {
    final inputFile = File(inputPath);
    final outputFile = File(outputPath);
    
    final plainBytes = await inputFile.readAsBytes();
    final encryptedBytes = encryptBytes(plainBytes);
    
    await outputFile.writeAsBytes(encryptedBytes);
  }

  Future<void> decryptFile(String inputPath, String outputPath) async {
    final inputFile = File(inputPath);
    final outputFile = File(outputPath);
    
    final encryptedBytes = await inputFile.readAsBytes();
    final plainBytes = decryptBytes(encryptedBytes);
    
    await outputFile.writeAsBytes(plainBytes);
  }

  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String generateSalt() {
    final saltBytes = List<int>.generate(32, (i) => Random.secure().nextInt(256));
    return base64Encode(saltBytes);
  }

  Future<void> rotateKeys() async {
    // Generate new keys
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _ivStorageKey);
    
    // Re-initialize with new keys
    await initialize();
  }
}