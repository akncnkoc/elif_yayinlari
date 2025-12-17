import 'dart:convert';

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis_auth/auth_io.dart' as auth_io;

class GoogleDriveAuth {
  static final GoogleDriveAuth _instance = GoogleDriveAuth._internal();
  factory GoogleDriveAuth() => _instance;
  GoogleDriveAuth._internal();

  auth.AutoRefreshingAuthClient? _authClient;
  bool _isInitialized = false;

  // Initialize service account authentication
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('GoogleDriveAuth already initialized');
      return;
    }

    try {
      debugPrint('🔐 Initializing Google Drive service account auth...');
      debugPrint('🕒 System Time: ${DateTime.now()}');
      debugPrint('🕒 System Time (UTC): ${DateTime.now().toUtc()}');

      // Key and IV for decryption (Must match encryption script)
      final keyString = 'TechAtlasSecureKey2025!StartNow.'; // 32 chars
      final ivString = 'TechAtlasInitVec'; // 16 chars

      final key = encrypt.Key.fromUtf8(keyString);
      final iv = encrypt.IV(Uint8List.fromList(utf8.encode(ivString)));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      // Read encrypted service account credentials
      String credentialsJson;

      try {
        debugPrint(
          '🔐 Loading encrypted credentials from assets/service_account.enc...',
        );
        // Always load from assets for the encrypted file
        final ByteData encryptedData = await rootBundle.load(
          'assets/service_account.enc',
        );
        final Uint8List encryptedBytes = encryptedData.buffer.asUint8List();

        final encrypted = encrypt.Encrypted(encryptedBytes);
        credentialsJson = encrypter.decrypt(encrypted, iv: iv);

        debugPrint('✅ Credentials decrypted successfully');
      } catch (e) {
        debugPrint('❌ Failed to load/decrypt credentials: $e');
        rethrow;
      }

      final Map<String, dynamic> jsonMap = json.decode(credentialsJson);

      // Fix for common Private Key formatting issues
      // Fix for common Private Key formatting issues
      if (jsonMap.containsKey('private_key')) {
        String key = jsonMap['private_key'] as String;

        debugPrint('🔑 Private key found. Length: ${key.length}');
        debugPrint(
          '🔑 Key starts with: ${key.substring(0, math.min(30, key.length))}...',
        );

        // 1. Handle double escaped newlines (literal \n)
        if (key.contains(r'\n')) {
          debugPrint('🔧 Fixing double escaped newlines (literal \\n)...');
          key = key.replaceAll(r'\n', '\n');
        }

        // 2. Remove carriage returns
        if (key.contains('\r')) {
          debugPrint('🔧 Removing carriage returns...');
          key = key.replaceAll('\r', '');
        }

        // 3. Ensure correct PEM headers/footers
        if (!key.startsWith('-----BEGIN PRIVATE KEY-----')) {
          debugPrint(
            '⚠️ Warning: Private key does not start with standard PEM header',
          );
        }

        // 4. Sometimes keys are one long line without any newlines.
        // We should try to insert newlines if they are missing after header/before footer
        if (!key.contains('\n') &&
            key.contains('-----BEGIN PRIVATE KEY-----')) {
          debugPrint('🔧 Key appears to be one line. Attempting to format...');
          key = key.replaceAll(
            '-----BEGIN PRIVATE KEY-----',
            '-----BEGIN PRIVATE KEY-----\n',
          );
          key = key.replaceAll(
            '-----END PRIVATE KEY-----',
            '\n-----END PRIVATE KEY-----',
          );
        }

        jsonMap['private_key'] = key;
      }

      final credentials = auth.ServiceAccountCredentials.fromJson(jsonMap);

      debugPrint('✅ Service account email: ${credentials.email}');

      // Create authenticated client with Drive API scopes
      final scopes = [
        drive.DriveApi.driveScope,
        drive.DriveApi.driveFileScope,
        drive.DriveApi.driveReadonlyScope,
      ];

      _authClient = await auth_io.clientViaServiceAccount(credentials, scopes);
      _isInitialized = true;

      debugPrint('✅ Google DriveAuth initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Google Drive Auth: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // Check if authenticated
  bool get isAuthenticated => _authClient != null && _isInitialized;

  // Get authenticated HTTP client
  auth.AuthClient? getAuthClient() {
    if (!isAuthenticated) {
      debugPrint('⚠️ Not authenticated. Call initialize() first.');
      return null;
    }
    return _authClient;
  }

  // Get Drive API instance
  drive.DriveApi? getDriveApi() {
    final client = getAuthClient();
    if (client == null) {
      debugPrint('⚠️ Cannot create DriveApi: not authenticated');
      return null;
    }
    return drive.DriveApi(client);
  }

  // Close the auth client
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _isInitialized = false;
    debugPrint('🔒 Google Drive Auth disposed');
  }
}
