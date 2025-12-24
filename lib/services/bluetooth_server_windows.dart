import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/foundation.dart';
import 'bluetooth_constants.dart';

/// Windows Bluetooth RFCOMM server implementation using FFI
class BluetoothServerWindows {
  static const String serviceName = 'Drawing Pen Remote';
  static const String serviceUuid = '00001101-0000-1000-8000-00805F9B34FB';

  bool _isRunning = false;
  Isolate? _serverIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isRunning => _isRunning;

  /// Start the Bluetooth RFCOMM server
  Future<bool> startServer() async {
    if (_isRunning) {
      return false;
    }

    try {
      _receivePort = ReceivePort();

      // Listen to messages from the isolate
      _receivePort!.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          _isRunning = true;
        } else if (message is Map<String, dynamic>) {
          _eventController.add(message);
        }
      });

      // Start server in separate isolate
      _serverIsolate = await Isolate.spawn(
        _bluetoothServerIsolate,
        _receivePort!.sendPort,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop the Bluetooth server
  void stopServer() {
    if (!_isRunning) return;

    _sendPort?.send('STOP');
    _serverIsolate?.kill(priority: Isolate.immediate);
    _serverIsolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    _isRunning = false;
  }

  /// Send message to connected clients
  void sendMessage(String message) {
    if (!_isRunning) return;
    _sendPort?.send({'type': 'MESSAGE', 'data': message});
  }

  /// Disconnect all clients
  void disconnectClients() {
    if (!_isRunning) return;
    _sendPort?.send({'type': 'DISCONNECT'});
  }

  void dispose() {
    stopServer();
    _eventController.close();
  }

  /// Bluetooth server isolate function
  static void _bluetoothServerIsolate(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    int serverSocket = INVALID_SOCKET;
    final List<int> clientSockets = [];
    bool shouldStop = false;

    try {
      // Initialize Winsock
      final wsaData = calloc<WSADATA>();
      final result = WSAStartup(MAKEWORD(2, 2), wsaData);
      calloc.free(wsaData);

      if (result != 0) {
        mainSendPort.send({
          'type': 'error',
          'error': 'Failed to initialize Winsock: $result',
        });
        return;
      }

      // Create Bluetooth RFCOMM socket
      serverSocket = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
      if (serverSocket == INVALID_SOCKET) {
        mainSendPort.send({
          'type': 'error',
          'error': 'Failed to create socket: ${WSAGetLastError()}',
        });
        WSACleanup();
        return;
      }

      // Bind to any available Bluetooth adapter
      final bindAddr = calloc<SOCKADDR_BTH>();
      bindAddr.ref.addressFamily = AF_BTH;
      bindAddr.ref.btAddr = 0; // BDADDR_ANY
      bindAddr.ref.port = BT_PORT_ANY;

      if (bind(serverSocket, bindAddr.cast(), sizeOf<SOCKADDR_BTH>()) ==
          SOCKET_ERROR) {
        final error = WSAGetLastError();
        mainSendPort.send({
          'type': 'error',
          'error': 'Failed to bind socket: $error',
        });
        calloc.free(bindAddr);
        closesocket(serverSocket);
        WSACleanup();
        return;
      }

      // Get the assigned port
      final addrLen = calloc<Int32>();
      addrLen.value = sizeOf<SOCKADDR_BTH>();

      if (getsockname(serverSocket, bindAddr.cast(), addrLen) == SOCKET_ERROR) {
        mainSendPort.send({
          'type': 'error',
          'error': 'Failed to get socket name: ${WSAGetLastError()}',
        });
        calloc.free(addrLen);
        calloc.free(bindAddr);
        closesocket(serverSocket);
        WSACleanup();
        return;
      }

      calloc.free(addrLen);

      // Listen for connections
      if (listen(serverSocket, SOMAXCONN) == SOCKET_ERROR) {
        mainSendPort.send({
          'type': 'error',
          'error': 'Failed to listen: ${WSAGetLastError()}',
        });
        calloc.free(bindAddr);
        closesocket(serverSocket);
        WSACleanup();
        return;
      }

      calloc.free(bindAddr);

      // Main server loop
      receivePort.listen((message) {
        if (message == 'STOP') {
          shouldStop = true;
        } else if (message is Map && message['type'] == 'MESSAGE') {
          // Send message to all clients
          final msg = message['data'] as String;
          final msgBytes = msg.codeUnits;
          final buffer = calloc<Uint8>(msgBytes.length);

          for (int i = 0; i < msgBytes.length; i++) {
            buffer[i] = msgBytes[i];
          }

          for (final clientSocket in clientSockets) {
            send(clientSocket, buffer.cast(), msgBytes.length, 0);
          }

          calloc.free(buffer);
        } else if (message is Map && message['type'] == 'DISCONNECT') {
          // Disconnect all clients
          for (final clientSocket in clientSockets) {
            closesocket(clientSocket);
          }
          clientSockets.clear();
        }
      });

      // Accept connections loop (simplified - should use select() for proper implementation)
      while (!shouldStop) {
        final clientAddr = calloc<SOCKADDR_BTH>();
        final addrLen = calloc<Int32>();
        addrLen.value = sizeOf<SOCKADDR_BTH>();

        // Note: This is blocking. In production, use select() or IOCP
        final clientSocket = accept(serverSocket, clientAddr.cast(), addrLen);

        if (clientSocket != INVALID_SOCKET && !shouldStop) {
          clientSockets.add(clientSocket);

          mainSendPort.send({
            'type': 'clientConnected',
            'clientAddress': 'Unknown', // Would need to format btAddr
            'clientName': 'Unknown',
          });

          // Handle client in separate "thread" (simplified)
          // In production, spawn another isolate or use async I/O
        }

        calloc.free(addrLen);
        calloc.free(clientAddr);

        // Break if should stop
        if (shouldStop) break;
      }
    } catch (e) {
      mainSendPort.send({'type': 'error', 'error': 'Server error: $e'});
    } finally {
      // Cleanup
      for (final clientSocket in clientSockets) {
        closesocket(clientSocket);
      }
      if (serverSocket != INVALID_SOCKET) {
        closesocket(serverSocket);
      }
      WSACleanup();
    }
  }
}
