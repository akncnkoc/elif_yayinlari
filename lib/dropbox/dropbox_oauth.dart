import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class DropboxOAuth {
  // Bu degerleri sen dolduracaksin
  static const String appKey = '61zfse0g4aquc80';
  static const String appSecret = '59wi0x2blevp6i3';

  // Secure storage keys
  static const String _accessTokenKey =
      'sl.u.AGCLmxo0I4yZ0Udgr1RdP-9eYGpG0lZdtDgRE36tgr5ndGxvUvS1adqXWSy-4bwwMp0x7dM8rX4hIm421-ooY_UU6UMU3zK-RhDFo24ppTJJihNsdKMnCvvl0U7_I0PsUmZtXOB9e54ePOQcqRzHXpxt0mgxbhd9g5zECdOmDOn9KiiVrWoNdOTSbjhtDln479ahN3g_Hy-1CLpFec-VoBdXrziNQ4avXHsLoPIXScsOEptl5Wm4Gb_bUZ8GPss4IcRRWuiYfL2yUzMVHMzcOTsGaJQOdLZgLhuZ90deCScA6QS2UJi7oT-l02BAOQe3MdTyf5EITfrl1DDfw1l7cHRKDPlXgMBgxMysOf8Ly_nZM7tyxv-20Hx00A4APNq1ht9ixhMHeeY6N9MJX8q48W9sgAmuFWfHufovBC8U38vSm-5O7UTdnLAWtdn-ePeZOs8-1IwUqPtaVmOBlgYoMwjECMgJB-FtmbuG62ogQK6_ARWZ9vooby805bhnng3AnDM7GvKulke539t2NPCp5iuaBnh8UhE4xC5krZy12pnU-Y7C7v-iYop7nOGzJrZ9ta6vAaaPQJU3wNw2cRbe0ZHnSgY3x7oqrIMCttshPHp4YpofOBMwdRfAa5P3r6HLUpiw5UTfI05qFtCXdkXPwL6KARjStMORqww2CQQFoxSEuIXrXR2_-3eczorgQuEO8_r3vF4UVCxP2SRRU6Ms8hSK2SGEL8RWd0L3EFzzkSOhQqeN5HMxeO8nMzk366wVj5fAgWMqspuy8p-84Kqm9zaNoHZurgIrpN9r6q7_PI5RaVDEI5pAEXFiGRGvM89IqEzNQCYJIljkbsvV_MFDpo_W-n-RUwB9AqrwcQ08YryJZJWzxZbqT7iWecfVZ00pA5IKJsfwVmWDjNrNUuUf5Lz-hOlWoQDHt2Xy_4kRPLpiIMa7Ko2yCSgaNpBvFZogf76Jz9JIa3CEMzdAimEBlZS_HXE45SqkrxactOi7eSIawd2bzo02SWssjusxw2FZQHLHArEJ0P9WdRGBob_KYB6kx97rmflG3J2Xs9rB-YFKRQApG5YR4qzXlxHB9g_QXulCEwpnbXCOjUd5PirzDoTnojLpw4PX9gUqMLqfyeV5tqgFmhM4l42go8-jcnuXX5Vhzm2nh2Q_R_PUYEMnzWdg4SStsEIzLsVDef8ZDkdhcijzll_3sP5s6G3Ed385VFxz09HaE_2JBfk3y2Q3bdNWWxaqdRfZKumtQ0amTlaePaSzHyJV7fSgUhP6OL_wpY7grtwuI8veHrmFgOJqgE5q9_1BNq3MHEJQ8jWUKzGIIanfT7rHLfgK5GEvcApN-rPVUC63f4kzo0qrMKO-rcdXL94FClvxgHkOwQnoq2a-shCeRrTpxs2J2TtbiTJ6pgSd6yidW1B83WdkqEZNUpjz7tnz2qqQ4JLRMQgCsF60Zg';
  static const String _refreshTokenKey =
      'xRnf1Q028YYAAAAAAAAAATTnujJqoUK8MUrvBgVe0fLbjVyVpq4bq7inmLjPdZka';
  static const String _tokenExpiryKey = '2025-10-15 18:45:27.935';

  // Token durumu
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // Singleton pattern
  static final DropboxOAuth _instance = DropboxOAuth._internal();
  factory DropboxOAuth() => _instance;
  DropboxOAuth._internal();

  // Initialization
  Future<void> initialize() async {
    await _loadTokensFromStorage();
  }

  // Load tokens from secure storage
  Future<void> _loadTokensFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);

      final expiryTimestamp = prefs.getInt(_tokenExpiryKey);
      if (expiryTimestamp != null) {
        _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      }

      debugPrint('Tokens loaded from storage');
      debugPrint('Access token exists: ${_accessToken != null}');
      debugPrint('Refresh token exists: ${_refreshToken != null}');
      debugPrint('Access token: $_accessToken');
      debugPrint('Refresh token: $_refreshToken');
      debugPrint('Token expiry: $_tokenExpiry');
    } catch (e) {
      debugPrint('Error loading tokens: $e');
    }
  }

  // Save tokens to secure storage
  Future<void> _saveTokensToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_accessToken != null) {
        await prefs.setString(_accessTokenKey, _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString(_refreshTokenKey, _refreshToken!);
      }
      if (_tokenExpiry != null) {
        await prefs.setInt(
          _tokenExpiryKey,
          _tokenExpiry!.millisecondsSinceEpoch,
        );
      }

      debugPrint('Tokens saved to storage');
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  // Check if token is expired or about to expire (5 minute buffer)
  bool _isTokenExpired() {
    if (_tokenExpiry == null) return true;
    final now = DateTime.now();
    final buffer = const Duration(minutes: 5);
    return now.isAfter(_tokenExpiry!.subtract(buffer));
  }

  // Get authorization URL for OAuth2 flow
  // Bu URL'i browser'da acmak icin kullanilacak
  String getAuthorizationUrl({String? state}) {
    final redirectUri = Uri.encodeComponent('http://localhost:8080/auth');
    final stateParam = "1760528698555";

    return 'https://www.dropbox.com/oauth2/authorize?'
        'client_id=$appKey&'
        'response_type=code&'
        'token_access_type=offline&' // Bu offline access icin gerekli
        'redirect_uri=$redirectUri&'
        'state=$stateParam';
  }

  // Exchange authorization code for tokens
  // Browser'dan donen authorization code ile token alinir
  Future<bool> exchangeCodeForToken(String authCode) async {
    try {
      debugPrint('Exchanging authorization code for tokens...');

      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': authCode,
          'grant_type': 'authorization_code',
          'client_id': appKey,
          'client_secret': appSecret,
          'redirect_uri': 'http://localhost:8080/auth',
        },
      );

      debugPrint('Token exchange response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];

        // Calculate expiry time (expires_in is in seconds)
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

        await _saveTokensToStorage();

        debugPrint('Successfully obtained tokens');
        debugPrint('Access token: ${_accessToken?.substring(0, 10)}...');
        debugPrint('Refresh token exists: ${_refreshToken != null}');
        debugPrint('Expires at: $_tokenExpiry');

        return true;
      } else {
        debugPrint('Token exchange failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error exchanging code for token: $e');
      return false;
    }
  }

  // Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      debugPrint('No refresh token available');
      return false;
    }

    try {
      debugPrint('Refreshing access token...');

      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': appKey,
          'client_secret': appSecret,
        },
      );

      debugPrint('Token refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _accessToken = data['access_token'];

        // Calculate expiry time
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

        await _saveTokensToStorage();

        debugPrint('Successfully refreshed access token');
        debugPrint('New token expires at: $_tokenExpiry');

        return true;
      } else {
        debugPrint('Token refresh failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  // Get valid access token (refresh if needed)
  Future<String?> getValidAccessToken() async {
    // Check if we have a token
    if (_accessToken == null) {
      debugPrint('No access token available');
      return null;
    }

    // Check if token is expired or about to expire
    if (_isTokenExpired()) {
      debugPrint('Token expired or about to expire, refreshing...');
      final success = await refreshAccessToken();
      if (!success) {
        debugPrint('Failed to refresh token');
        return null;
      }
    }

    return _accessToken;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _refreshToken != null;
  }

  // Logout - clear all tokens
  Future<void> logout() async {
    try {
      // Revoke token on Dropbox
      if (_accessToken != null) {
        await http.post(
          Uri.parse('https://api.dropboxapi.com/2/auth/token/revoke'),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );
      }
    } catch (e) {
      debugPrint('Error revoking token: $e');
    }

    // Clear local storage
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);

    debugPrint('Logged out and cleared all tokens');
  }

  // For testing/migration: Set tokens directly
  Future<void> setTokensDirectly({
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = expiry ?? DateTime.now().add(const Duration(hours: 4));
    await _saveTokensToStorage();
  }
}
