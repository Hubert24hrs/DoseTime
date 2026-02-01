import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure encrypted storage of sensitive data
class SecureStorageService {
  static const _keyStorageKey = '_encryption_key';
  static const _ivStorageKey = '_encryption_iv';
  
  final FlutterSecureStorage _secureStorage;
  encrypt.Key? _encryptionKey;
  encrypt.IV? _iv;

  SecureStorageService({FlutterSecureStorage? storage})
      : _secureStorage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  /// Initialize encryption keys
  Future<void> initialize() async {
    // Try to load existing key
    String? keyBase64 = await _secureStorage.read(key: _keyStorageKey);
    String? ivBase64 = await _secureStorage.read(key: _ivStorageKey);

    if (keyBase64 == null || ivBase64 == null) {
      // Generate new key and IV
      _encryptionKey = encrypt.Key.fromSecureRandom(32); // AES-256
      _iv = encrypt.IV.fromSecureRandom(16);

      // Store them
      await _secureStorage.write(key: _keyStorageKey, value: _encryptionKey!.base64);
      await _secureStorage.write(key: _ivStorageKey, value: _iv!.base64);
    } else {
      _encryptionKey = encrypt.Key.fromBase64(keyBase64);
      _iv = encrypt.IV.fromBase64(ivBase64);
    }
  }

  /// Encrypt sensitive string data
  String encryptString(String plainText) {
    if (_encryptionKey == null || _iv == null) {
      throw StateError('SecureStorageService not initialized');
    }
    
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt sensitive string data
  String decryptString(String encryptedText) {
    if (_encryptionKey == null || _iv == null) {
      throw StateError('SecureStorageService not initialized');
    }
    
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }

  /// Store a secure key-value pair
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Read a secure value
  Future<String?> read(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete a secure value
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Delete all secure storage (for account deletion)
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }

  /// Check if sensitive data encryption is available
  bool get isInitialized => _encryptionKey != null && _iv != null;
}

// Provider
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
