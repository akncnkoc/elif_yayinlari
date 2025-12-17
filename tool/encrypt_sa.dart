import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

// HARDCODED KEY & IV FOR DEMONSTRATION/OBFUSCATION
// Ideally these should be environment variables or fetched securely.
final keyString = 'TechAtlasSecureKey2025!StartNow.'; // 32 chars
final ivString = 'TechAtlasInitVec'; // 16 chars

void main() async {
  final file = File('service_account.json');
  if (!await file.exists()) {
    print('Error: service_account.json not found in root.');
    return;
  }

  final plainText = await file.readAsString();

  final key = Key.fromUtf8(keyString);
  final iv = IV(Uint8List.fromList(utf8.encode(ivString)));

  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

  final encrypted = encrypter.encrypt(plainText, iv: iv);

  final outFile = File('assets/service_account.enc');
  if (!await outFile.parent.exists()) {
    await outFile.parent.create(recursive: true);
  }

  await outFile.writeAsBytes(encrypted.bytes);

  print('✅ Encrypted service_account.json to assets/service_account.enc');
  print('Key: $keyString');
  print('IV: $ivString');
}
