import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt_lib;

/// Generates ZEGO Token04 tokens for client-side authentication.
///
/// Token04 uses a binary packed format:
/// ```
/// "04" + base64([8B expire][2B IV_len][16B IV][2B cipher_len][NB ciphertext])
/// ```
///
/// The AES key is the ServerSecret as raw UTF-8 bytes (32 bytes → AES-256-CBC).
/// The plaintext is a JSON string with app_id, user_id, nonce, timestamps.
///
/// Reference: https://github.com/ZEGOCLOUD/zego_server_assistant
class ZegoTokenGenerator {
  /// Generate a ZEGO Token04 for authentication.
  ///
  /// [appID] — Your ZEGOCLOUD App ID.
  /// [userID] — The user ID to authenticate.
  /// [serverSecret] — Your ZEGOCLOUD Server Secret (32 characters).
  /// [effectiveTimeInSeconds] — Token validity duration (default: 3600 = 1 hour).
  /// [payload] — Optional payload string (default: empty).
  ///
  /// Returns a Token04 string starting with "04" prefix.
  static String generateToken04({
    required int appID,
    required String userID,
    required String serverSecret,
    int effectiveTimeInSeconds = 3600,
    String payload = '',
  }) {
    final random = Random.secure();
    final nonce = random.nextInt(2147483647);
    final createTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expire = createTime + effectiveTimeInSeconds;

    // Build token info payload (JSON plaintext for encryption)
    final tokenInfo = jsonEncode({
      'app_id': appID,
      'user_id': userID,
      'nonce': nonce,
      'ctime': createTime,
      'expire': expire,
      'payload': payload,
    });

    // Generate random 16-byte IV for AES-CBC
    final ivBytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      ivBytes[i] = random.nextInt(256);
    }

    // ServerSecret as raw UTF-8 bytes: 32 chars → 32 bytes → AES-256
    final key = encrypt_lib.Key.fromUtf8(serverSecret);
    final iv = encrypt_lib.IV(ivBytes);

    // AES-256-CBC encrypt with PKCS7 padding (default)
    final encrypter = encrypt_lib.Encrypter(
      encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
    );
    final encrypted = encrypter.encryptBytes(
      utf8.encode(tokenInfo),
      iv: iv,
    );
    final cipherBytes = Uint8List.fromList(encrypted.bytes);

    // Binary pack the token buffer:
    // [8B expire_time][2B iv_len][16B iv][2B cipher_len][NB ciphertext]
    final bufferLen = 8 + 2 + 16 + 2 + cipherBytes.length;
    final byteData = ByteData(bufferLen);
    final uint8View = byteData.buffer.asUint8List();
    var offset = 0;

    // Expire time as big-endian Int64 (high 32 bits = 0, low 32 bits = expire)
    byteData.setUint32(offset, 0, Endian.big);
    offset += 4;
    byteData.setUint32(offset, expire, Endian.big);
    offset += 4;

    // IV length as big-endian Uint16
    byteData.setUint16(offset, ivBytes.length, Endian.big);
    offset += 2;

    // IV bytes
    uint8View.setAll(offset, ivBytes);
    offset += ivBytes.length;

    // Ciphertext length as big-endian Uint16
    byteData.setUint16(offset, cipherBytes.length, Endian.big);
    offset += 2;

    // Ciphertext bytes
    uint8View.setAll(offset, cipherBytes);

    // Final token: "04" version prefix + base64 encoded binary buffer
    return '04${base64Encode(uint8View)}';
  }
}
