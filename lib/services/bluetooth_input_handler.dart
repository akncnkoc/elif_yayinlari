import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'bluetooth_server_service.dart';

/// Bluetooth üzerinden gelen mouse/keyboard eventlerini işler
class BluetoothInputHandler {
  final BluetoothServerService _bluetoothService = BluetoothServerService();
  StreamSubscription<BluetoothEvent>? _eventSubscription;

  // Callbacks
  Function(Offset position)? onMouseMove;
  Function(Offset delta)? onMouseDelta;
  Function(int button)? onMouseDown;
  Function(int button)? onMouseUp;
  Function(int button)? onMouseClick;
  Function(String key)? onKeyDown;
  Function(String key)? onKeyUp;
  Function(Offset delta)? onScroll;
  Function(String clientAddress)? onClientConnected;
  Function(String clientAddress)? onClientDisconnected;

  bool get isRunning => _bluetoothService.isRunning;

  /// Bluetooth server'ı başlat ve eventleri dinlemeye başla
  Future<bool> start({
    String serviceName = 'Drawing Pen Remote',
    String serviceUuid = '00001101-0000-1000-8000-00805F9B34FB',
  }) async {
    // Önce Bluetooth mevcut mu kontrol et
    final isAvailable = await _bluetoothService.isBluetoothAvailable();
    if (!isAvailable) {
      return false;
    }

    final isEnabled = await _bluetoothService.isBluetoothEnabled();
    if (!isEnabled) {
      return false;
    }

    // Server'ı başlat
    final started = await _bluetoothService.startServer(
      serviceName: serviceName,
      serviceUuid: serviceUuid,
    );

    if (!started) {
      return false;
    }

    // Event stream'ini dinle
    _eventSubscription = _bluetoothService.eventStream.listen(
      _handleBluetoothEvent,
    );

    return true;
  }

  /// Bluetooth server'ı durdur
  Future<void> stop() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _bluetoothService.stopServer();
  }

  /// Bluetooth event'lerini işle
  void _handleBluetoothEvent(BluetoothEvent event) {
    switch (event.type) {
      case BluetoothEventType.clientConnected:
        onClientConnected?.call(event.clientAddress ?? '');
        break;

      case BluetoothEventType.clientDisconnected:
        onClientDisconnected?.call(event.clientAddress ?? '');
        break;

      case BluetoothEventType.messageReceived:
        _handleInputMessage(event.message ?? '');
        break;

      case BluetoothEventType.error:
        break;
    }
  }

  /// Gelen mesajı parse edip input event'ini işle
  void _handleInputMessage(String message) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      final event = RemoteInputEvent.fromJson(json);

      switch (event.type) {
        case RemoteInputType.mousemove:
          if (event.x != null && event.y != null) {
            onMouseMove?.call(Offset(event.x!, event.y!));
          }
          break;

        case RemoteInputType.mousedelta:
          if (event.deltaX != null && event.deltaY != null) {
            onMouseDelta?.call(Offset(event.deltaX!, event.deltaY!));
          }
          break;

        case RemoteInputType.mousedown:
          if (event.button != null) {
            onMouseDown?.call(event.button!);
          }
          break;

        case RemoteInputType.mouseup:
          if (event.button != null) {
            onMouseUp?.call(event.button!);
          }
          break;

        case RemoteInputType.mouseclick:
          if (event.button != null) {
            onMouseClick?.call(event.button!);
          }
          break;

        case RemoteInputType.keydown:
          if (event.key != null) {
            onKeyDown?.call(event.key!);
          }
          break;

        case RemoteInputType.keyup:
          if (event.key != null) {
            onKeyUp?.call(event.key!);
          }
          break;

        case RemoteInputType.scroll:
          if (event.deltaX != null && event.deltaY != null) {
            onScroll?.call(Offset(event.deltaX!, event.deltaY!));
          }
          break;

        case RemoteInputType.unknown:
          break;
      }
    } catch (e) {}
  }

  /// Client'lara mesaj gönder (opsiyonel - feedback için kullanılabilir)
  Future<bool> sendFeedback(String message) async {
    return await _bluetoothService.sendMessage(message);
  }

  /// Tüm client'ları kes
  Future<void> disconnectAll() async {
    await _bluetoothService.disconnectClients();
  }
}

/// Bluetooth bağlantı durumu widget'ı
class BluetoothStatusIndicator extends StatefulWidget {
  final BluetoothInputHandler handler;

  const BluetoothStatusIndicator({super.key, required this.handler});

  @override
  State<BluetoothStatusIndicator> createState() =>
      _BluetoothStatusIndicatorState();
}

class _BluetoothStatusIndicatorState extends State<BluetoothStatusIndicator> {
  int _connectedClients = 0;

  @override
  void initState() {
    super.initState();
    widget.handler.onClientConnected = (_) {
      setState(() => _connectedClients++);
    };
    widget.handler.onClientDisconnected = (_) {
      setState(() => _connectedClients--);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.handler.isRunning) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _connectedClients > 0
            ? Colors.green.shade400
            : Colors.orange.shade400,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _connectedClients > 0 ? Icons.bluetooth_connected : Icons.bluetooth,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _connectedClients > 0 ? '$_connectedClients bağlı' : 'Bekliyor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
