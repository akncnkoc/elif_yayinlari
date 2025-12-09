import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const RemoteControlApp());
}

class RemoteControlApp extends StatelessWidget {
  const RemoteControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drawing Pen Remote',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const BluetoothConnectionPage(),
    );
  }
}

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({super.key});

  @override
  State<BluetoothConnectionPage> createState() => _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  Future<void> _checkBluetoothState() async {
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      _showError('Bluetooth bu cihazda desteklenmiyor');
      return;
    }

    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      _showError('Lütfen Bluetooth\'u açın');
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _scanResults = results
              .where((r) => r.device.platformName.isNotEmpty)
              .toList();
        });
      });

      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      _showError('Tarama hatası: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));

      final services = await device.discoverServices();

      // Serial Port Profile UUID veya benzeri bir service ara
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }

      if (_writeCharacteristic == null) {
        throw Exception('Yazılabilir characteristic bulunamadı');
      }

      setState(() {
        _connectedDevice = device;
      });

      // Remote control sayfasına geç
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RemoteControlPage(
              device: device,
              characteristic: _writeCharacteristic!,
            ),
          ),
        ).then((_) {
          device.disconnect();
          setState(() {
            _connectedDevice = null;
            _writeCharacteristic = null;
          });
        });
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Pen Remote'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Bilgisayarınızdaki Drawing Pen uygulamasına bağlanın',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isScanning ? 'Aranıyor...' : 'Cihaz Ara'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _scanResults.isEmpty
                ? const Center(
                    child: Text('Cihaz bulunamadı.\n"Cihaz Ara" butonuna basın.'),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(result.device.platformName),
                        subtitle: Text(result.device.remoteId.toString()),
                        trailing: Text('${result.rssi} dBm'),
                        onTap: () => _connectToDevice(result.device),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class RemoteControlPage extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const RemoteControlPage({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<RemoteControlPage> createState() => _RemoteControlPageState();
}

class _RemoteControlPageState extends State<RemoteControlPage> {
  Future<void> _sendEvent(Map<String, dynamic> event) async {
    try {
      final json = jsonEncode(event);
      final bytes = utf8.encode(json);
      await widget.characteristic.write(bytes, withoutResponse: true);
    } catch (e) {
      debugPrint('Send error: $e');
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Relative mouse movement
    _sendEvent({
      'type': 'mousedelta',
      'deltaX': details.delta.dx,
      'deltaY': details.delta.dy,
    });
  }

  void _handleTapDown(TapDownDetails details) {
    _sendEvent({
      'type': 'mousedown',
      'button': 0, // Left button
    });
  }

  void _handleTapUp(TapUpDetails details) {
    _sendEvent({
      'type': 'mouseup',
      'button': 0,
    });
  }

  void _sendKeyPress(String key) {
    _sendEvent({
      'type': 'keydown',
      'key': key,
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _sendEvent({
        'type': 'keyup',
        'key': key,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bağlı: ${widget.device.platformName}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Touchpad area
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: GestureDetector(
                onPanUpdate: _handlePanUpdate,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 48, color: Colors.white54),
                      SizedBox(height: 8),
                      Text(
                        'Touchpad',
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Parmağınızı sürükleyin',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Control buttons
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Kısayollar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildButton('Temizle', 'C', Icons.delete_outline, () => _sendKeyPress('c')),
                        _buildButton('Geri Al', 'Z', Icons.undo, () => _sendKeyPress('z')),
                        _buildButton('Silgi', 'E', Icons.edit_off, () => _sendKeyPress('e')),
                        _buildButton('Kapat', 'Q', Icons.close, () => _sendKeyPress('q')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, String key, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          Text(
            '($key)',
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
