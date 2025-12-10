import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Simple TCP/IP server for remote control (alternative to Bluetooth)
/// This avoids C++ header conflicts by using pure Dart
class BluetoothServerDart {
  static const int defaultPort = 8888;

  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  bool _isRunning = false;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isRunning => _isRunning;

  /// Start the TCP server
  Future<bool> startServer({int port = defaultPort}) async {
    if (_isRunning) {
      debugPrint('❌ Server already running');
      return false;
    }

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;

      // Get local IP address
      final interfaces = await NetworkInterface.list();
      String? localIp;
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }

      debugPrint('✅ Server started on ${localIp ?? 'unknown'}:$port');

      _eventController.add({
        'type': 'serverStarted',
        'ip': localIp ?? 'unknown',
        'port': port,
      });

      // Listen for client connections
      _serverSocket!.listen(
        _handleClient,
        onError: (error) {
          debugPrint('❌ Server error: $error');
          _eventController.add({
            'type': 'error',
            'error': error.toString(),
          });
        },
        onDone: () {
          debugPrint('🛑 Server stopped');
          _isRunning = false;
        },
      );

      return true;
    } catch (e) {
      debugPrint('❌ Failed to start server: $e');
      _eventController.add({
        'type': 'error',
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Handle incoming client connection
  void _handleClient(Socket client) {
    _clients.add(client);

    final clientAddress = '${client.remoteAddress.address}:${client.remotePort}';
    debugPrint('📱 Client connected: $clientAddress');

    _eventController.add({
      'type': 'clientConnected',
      'clientAddress': clientAddress,
      'clientName': 'Remote Device',
    });

    // Listen to client messages
    client.listen(
      (data) {
        try {
          final message = utf8.decode(data).trim();
          debugPrint('📨 Received: $message from $clientAddress');

          _eventController.add({
            'type': 'messageReceived',
            'clientAddress': clientAddress,
            'message': message,
          });
        } catch (e) {
          debugPrint('❌ Error decoding message: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Client error: $error');
        _removeClient(client);
      },
      onDone: () {
        debugPrint('👋 Client disconnected: $clientAddress');
        _removeClient(client);

        _eventController.add({
          'type': 'clientDisconnected',
          'clientAddress': clientAddress,
        });
      },
    );
  }

  /// Remove client from list
  void _removeClient(Socket client) {
    _clients.remove(client);
    try {
      client.close();
    } catch (_) {}
  }

  /// Send message to all connected clients
  void sendMessage(String message) {
    if (!_isRunning) return;

    final data = utf8.encode(message);
    for (final client in _clients) {
      try {
        client.add(data);
        debugPrint('📤 Sent: $message');
      } catch (e) {
        debugPrint('❌ Failed to send to client: $e');
        _removeClient(client);
      }
    }
  }

  /// Disconnect all clients
  void disconnectClients() {
    for (final client in [..._clients]) {
      _removeClient(client);
    }
    _clients.clear();
    debugPrint('👋 All clients disconnected');
  }

  /// Stop the server
  Future<void> stopServer() async {
    if (!_isRunning) return;

    disconnectClients();

    await _serverSocket?.close();
    _serverSocket = null;
    _isRunning = false;

    debugPrint('🛑 Server stopped');
  }

  /// Check if Bluetooth is available (always true for TCP)
  bool isBluetoothAvailable() => true;

  /// Check if Bluetooth is enabled (always true for TCP)
  bool isBluetoothEnabled() => true;

  void dispose() {
    stopServer();
    _eventController.close();
  }
}
