import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Native Bluetooth Server Service
/// Windows, Linux, macOS platformlarında Bluetooth RFCOMM server çalıştırır
class BluetoothServerService {
  static const MethodChannel _channel = MethodChannel('com.elif.bluetooth_server');
  static const EventChannel _eventChannel = EventChannel('com.elif.bluetooth_server/events');

  Stream<BluetoothEvent>? _eventStream;
  bool _isServerRunning = false;

  /// Server çalışıyor mu?
  bool get isRunning => _isServerRunning;

  /// Bluetooth Server'ı başlat
  ///
  /// [serviceName]: Bluetooth servis adı (telefonda görünecek)
  /// [serviceUuid]: Bluetooth servis UUID'si
  Future<bool> startServer({
    String serviceName = 'Drawing Pen Remote',
    String serviceUuid = '00001101-0000-1000-8000-00805F9B34FB', // Standard Serial Port Profile UUID
  }) async {
    try {
      final result = await _channel.invokeMethod('startServer', {
        'serviceName': serviceName,
        'serviceUuid': serviceUuid,
      });

      _isServerRunning = result == true;
      return _isServerRunning;
    } on PlatformException catch (e) {
      debugPrint('Bluetooth Server başlatılamadı: ${e.message}');
      return false;
    }
  }

  /// Bluetooth Server'ı durdur
  Future<void> stopServer() async {
    try {
      await _channel.invokeMethod('stopServer');
      _isServerRunning = false;
    } on PlatformException catch (e) {
      debugPrint('Bluetooth Server durdurulamadı: ${e.message}');
    }
  }

  /// Bluetooth event stream'ini dinle
  Stream<BluetoothEvent> get eventStream {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      return BluetoothEvent.fromMap(Map<String, dynamic>.from(event));
    });
    return _eventStream!;
  }

  /// Client'a mesaj gönder
  Future<bool> sendMessage(String message) async {
    try {
      final result = await _channel.invokeMethod('sendMessage', {
        'message': message,
      });
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Mesaj gönderilemedi: ${e.message}');
      return false;
    }
  }

  /// Bağlı client'ları kes
  Future<void> disconnectClients() async {
    try {
      await _channel.invokeMethod('disconnectClients');
    } on PlatformException catch (e) {
      debugPrint('Client bağlantısı kesilemedi: ${e.message}');
    }
  }

  /// Bluetooth adapter durumunu kontrol et
  Future<bool> isBluetoothAvailable() async {
    try {
      final result = await _channel.invokeMethod('isBluetoothAvailable');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Bluetooth durumu kontrol edilemedi: ${e.message}');
      return false;
    }
  }

  /// Bluetooth adapter açık mı?
  Future<bool> isBluetoothEnabled() async {
    try {
      final result = await _channel.invokeMethod('isBluetoothEnabled');
      return result == true;
    } on PlatformException catch (e) {
      debugPrint('Bluetooth durumu kontrol edilemedi: ${e.message}');
      return false;
    }
  }
}

/// Bluetooth Event türleri
enum BluetoothEventType {
  clientConnected,
  clientDisconnected,
  messageReceived,
  error,
}

/// Bluetooth Event model
class BluetoothEvent {
  final BluetoothEventType type;
  final String? clientAddress;
  final String? clientName;
  final String? message;
  final String? error;

  BluetoothEvent({
    required this.type,
    this.clientAddress,
    this.clientName,
    this.message,
    this.error,
  });

  factory BluetoothEvent.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String;
    final type = BluetoothEventType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => BluetoothEventType.error,
    );

    return BluetoothEvent(
      type: type,
      clientAddress: map['clientAddress'] as String?,
      clientName: map['clientName'] as String?,
      message: map['message'] as String?,
      error: map['error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'clientAddress': clientAddress,
      'clientName': clientName,
      'message': message,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'BluetoothEvent(type: $type, client: $clientName, message: $message)';
  }
}

/// Mouse/Keyboard event parser
class RemoteInputEvent {
  final RemoteInputType type;
  final double? x;
  final double? y;
  final double? deltaX;
  final double? deltaY;
  final int? button; // 0: left, 1: right, 2: middle
  final String? key;
  final bool? isPressed;

  RemoteInputEvent({
    required this.type,
    this.x,
    this.y,
    this.deltaX,
    this.deltaY,
    this.button,
    this.key,
    this.isPressed,
  });

  /// JSON string'den event oluştur
  /// Format: {"type":"mousemove","x":100.5,"y":200.3}
  factory RemoteInputEvent.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final type = RemoteInputType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => RemoteInputType.unknown,
    );

    return RemoteInputEvent(
      type: type,
      x: json['x'] as double?,
      y: json['y'] as double?,
      deltaX: json['deltaX'] as double?,
      deltaY: json['deltaY'] as double?,
      button: json['button'] as int?,
      key: json['key'] as String?,
      isPressed: json['isPressed'] as bool?,
    );
  }

  @override
  String toString() {
    return 'RemoteInputEvent(type: $type, x: $x, y: $y, deltaX: $deltaX, deltaY: $deltaY)';
  }
}

/// Remote input türleri
enum RemoteInputType {
  mousemove,      // x, y (absolute pozisyon)
  mousedelta,     // deltaX, deltaY (relative hareket)
  mousedown,      // button
  mouseup,        // button
  mouseclick,     // button
  keydown,        // key
  keyup,          // key
  scroll,         // deltaX, deltaY
  unknown,
}
