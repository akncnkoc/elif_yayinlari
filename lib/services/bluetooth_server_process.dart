import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Manages the standalone Bluetooth server process
class BluetoothServerProcess {
  Process? _process;
  bool _isRunning = false;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  bool get isRunning => _isRunning;

  /// Start the Bluetooth server process
  Future<bool> startServer() async {
    if (_isRunning) {
      return false;
    }

    try {
      // Find the bluetooth_server_standalone.exe
      final exePath = _getBluetoothServerPath();

      if (!File(exePath).existsSync()) {
        _eventController.add({
          'type': 'error',
          'error':
              'Bluetooth server not found. Please rebuild the application.',
        });
        return false;
      }

      // Start the process
      _process = await Process.start(
        exePath,
        [],
        mode: ProcessStartMode.normal,
      );

      _isRunning = true;

      // Listen to stdout
      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            _handleServerOutput(line);
          });

      // Listen to stderr
      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {});

      // Listen to process exit
      _process!.exitCode.then((exitCode) {
        _isRunning = false;
        _eventController.add({'type': 'serverStopped'});
      });

      return true;
    } catch (e) {
      _eventController.add({'type': 'error', 'error': e.toString()});
      return false;
    }
  }

  /// Stop the Bluetooth server
  void stopServer() {
    if (!_isRunning || _process == null) return;

    try {
      // Send STOP command
      _process!.stdin.writeln('STOP');
      _process!.stdin.close();

      // Wait a bit, then kill if still running
      Future.delayed(const Duration(seconds: 2), () {
        if (_process != null) {
          _process!.kill();
        }
      });
    } catch (e) {}

    _isRunning = false;
  }

  /// Send message to connected clients
  void sendMessage(String message) {
    if (!_isRunning || _process == null) return;

    try {
      _process!.stdin.writeln('SEND:$message');
    } catch (e) {}
  }

  /// Check if Bluetooth is available
  bool isBluetoothAvailable() {
    return File(_getBluetoothServerPath()).existsSync();
  }

  /// Check if Bluetooth is enabled
  bool isBluetoothEnabled() {
    // This would need actual Windows API check, for now just return true
    return true;
  }

  void dispose() {
    stopServer();
    _eventController.close();
  }

  /// Get the path to the Bluetooth server executable
  String _getBluetoothServerPath() {
    if (Platform.isWindows) {
      // Try Debug first, then Release
      final debugPath =
          '${Directory.current.path}\\build\\windows\\x64\\runner\\Debug\\bluetooth_server_standalone.exe';
      final releasePath =
          '${Directory.current.path}\\build\\windows\\x64\\runner\\Release\\bluetooth_server_standalone.exe';

      if (File(debugPath).existsSync()) {
        return debugPath;
      } else if (File(releasePath).existsSync()) {
        return releasePath;
      }

      // Try in the same directory as the main exe
      return '${Directory.current.path}\\bluetooth_server_standalone.exe';
    }

    return '';
  }

  /// Handle output from the Bluetooth server
  void _handleServerOutput(String line) {
    if (line.startsWith('SERVER_STARTED:')) {
      _eventController.add({
        'type': 'serverStarted',
        'info': line.substring(15),
      });
    } else if (line.startsWith('CLIENT_CONNECTED:')) {
      final clientId = line.substring(17);
      _eventController.add({
        'type': 'clientConnected',
        'clientAddress': clientId,
        'clientName': 'Remote Device',
      });
    } else if (line.startsWith('CLIENT_DISCONNECTED:')) {
      final clientId = line.substring(20);
      _eventController.add({
        'type': 'clientDisconnected',
        'clientAddress': clientId,
      });
    } else if (line.startsWith('MESSAGE_RECEIVED:')) {
      final message = line.substring(17);
      _eventController.add({'type': 'messageReceived', 'message': message});
    } else if (line.startsWith('ERROR:')) {
      final error = line.substring(6);
      _eventController.add({'type': 'error', 'error': error});
    } else if (line == 'READY') {}
  }
}
