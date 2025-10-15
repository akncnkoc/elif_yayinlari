import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dropbox_oauth.dart';
import 'dart:io';

class DropboxAuthPage extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const DropboxAuthPage({super.key, required this.onAuthSuccess});

  @override
  State<DropboxAuthPage> createState() => _DropboxAuthPageState();
}

class _DropboxAuthPageState extends State<DropboxAuthPage> {
  final DropboxOAuth _oauth = DropboxOAuth();
  final TextEditingController _authCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  HttpServer? _localServer;

  @override
  void dispose() {
    _authCodeController.dispose();
    _localServer?.close();
    super.dispose();
  }

  Future<void> _startAuthFlow() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Start local server to capture redirect
      await _startLocalServer();

      // Get authorization URL
      final authUrl = _oauth.getAuthorizationUrl();

      // Open browser
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch browser');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start authentication: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _startLocalServer() async {
    try {
      _localServer = await HttpServer.bind('localhost', 8080);
      print('Local server started on port 8080');

      _localServer!.listen((HttpRequest request) async {
        final uri = request.uri;
        print('Received request: ${uri.path}');

        if (uri.path == '/auth') {
          final code = uri.queryParameters['code'];
          final error = uri.queryParameters['error'];

          // Send response to browser
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write('''
              <!DOCTYPE html>
              <html>
              <head>
                <title>Dropbox Authentication</title>
                <style>
                  body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  }
                  .container {
                    background: white;
                    padding: 40px;
                    border-radius: 12px;
                    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
                    text-align: center;
                    max-width: 400px;
                  }
                  h1 {
                    color: #333;
                    margin-bottom: 20px;
                  }
                  p {
                    color: #666;
                    font-size: 16px;
                  }
                  .success {
                    color: #10b981;
                    font-size: 48px;
                    margin-bottom: 20px;
                  }
                  .error {
                    color: #ef4444;
                    font-size: 48px;
                    margin-bottom: 20px;
                  }
                </style>
              </head>
              <body>
                <div class="container">
                  ${error != null ? '''
                    <div class="error">✗</div>
                    <h1>Authentication Failed</h1>
                    <p>Error: $error</p>
                  ''' : '''
                    <div class="success">✓</div>
                    <h1>Authentication Successful!</h1>
                    <p>You can now close this window and return to the application.</p>
                  '''}
                </div>
              </body>
              </html>
            ''');
          await request.response.close();

          // Handle the response
          if (error != null) {
            setState(() {
              _errorMessage = 'Authentication failed: $error';
              _isLoading = false;
            });
          } else if (code != null) {
            await _handleAuthCode(code);
          }

          // Close the server
          await _localServer?.close();
          _localServer = null;
        }
      });
    } catch (e) {
      print('Error starting local server: $e');
      rethrow;
    }
  }

  Future<void> _handleAuthCode(String authCode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _oauth.exchangeCodeForToken(authCode);

      if (success) {
        if (mounted) {
          widget.onAuthSuccess();
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to exchange authorization code for tokens';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during authentication: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _manualAuthCodeEntry() async {
    final authCode = _authCodeController.text.trim();
    if (authCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the authorization code';
      });
      return;
    }

    await _handleAuthCode(authCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE8EAF0), width: 1.5),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropbox Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0061FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.cloud,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Connect to Dropbox',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D29),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    const Text(
                      'Authorize this application to access your Dropbox files',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Authorize button
                    if (!_isLoading)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _startAuthFlow,
                          icon: const Icon(Icons.login),
                          label: const Text('Authorize with Dropbox'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF0061FF),
                          ),
                        ),
                      ),

                    if (_isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Waiting for authorization...',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Divider
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Manual code entry
                    const Text(
                      'Enter authorization code manually',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D29),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _authCodeController,
                      decoration: const InputDecoration(
                        hintText: 'Paste authorization code here',
                        prefixIcon: Icon(Icons.key),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _manualAuthCodeEntry,
                        child: const Text('Submit Code'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your credentials are securely stored locally and never shared with third parties.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
