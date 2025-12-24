import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:permission_handler/permission_handler.dart';
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
  State<BluetoothConnectionPage> createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  final FlutterBlueClassic _bluetooth =
      FlutterBlueClassic(usesFineLocation: true);
  BluetoothConnection? _connection;
  bool _isScanning = false;
  List<BluetoothDevice> _devices = [];
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothState() async {
    final isSupported = await _bluetooth.isSupported;
    if (isSupported != true) {
      _showError('Bluetooth desteklenmiyor');
      return;
    }

    final isEnabled = await _bluetooth.isEnabled;
    if (isEnabled != true) {
      _showError('Lütfen Bluetooth\'u açın');
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    // Android 12+ için Bluetooth izinleri
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      _showError('Bluetooth izinleri gerekli. Lütfen ayarlardan izin verin.');
      return false;
    }

    return true;
  }

  Future<void> _startDiscovery() async {
    if (_isScanning) return;

    // İzinleri kontrol et
    if (!await _requestBluetoothPermissions()) {
      return;
    }

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      // Önce eşlenmiş cihazları al
      final bondedDevices = await _bluetooth.bondedDevices;
      if (bondedDevices != null) {
        setState(() {
          _devices = bondedDevices;
        });
      }

      // Yeni cihaz taraması başlat
      _bluetooth.startScan();

      _scanSubscription = _bluetooth.scanResults.listen((device) {
        if (!_devices.any((d) => d.address == device.address)) {
          setState(() {
            _devices.add(device);
          });
        }
      });

      // 10 saniye sonra taramayı durdur
      await Future.delayed(const Duration(seconds: 10));
      _bluetooth.stopScan();
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Bağlanıyor...'),
            ],
          ),
        ),
      );

      _connection = await _bluetooth.connect(device.address);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (_connection == null) {
        _showError('Bağlantı başarısız');
        return;
      }

      // Remote control sayfasına geç
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RemoteControlPage(
            device: device,
            connection: _connection!,
          ),
        ),
      ).then((_) {
        _connection?.dispose();
        _connection = null;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () async {
              final isEnabled = await _bluetooth.isEnabled;
              if (isEnabled == false) {
                _bluetooth.turnOn();
              }
            },
          ),
        ],
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
                const SizedBox(height: 8),
                const Text(
                  '"Drawing Pen Remote" veya bilgisayar adını arayın',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startDiscovery,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isScanning ? 'Aranıyor...' : 'Cihaz Ara'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _devices.isEmpty
                ? const Center(
                    child:
                        Text('Cihaz bulunamadı.\n"Cihaz Ara" butonuna basın.'),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.name ?? 'Bilinmeyen Cihaz'),
                        subtitle: Text(device.address),
                        trailing: device.bondState == BluetoothBondState.bonded
                            ? const Chip(
                                label: Text('Eşlenmiş',
                                    style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.green,
                              )
                            : null,
                        onTap: () => _connectToDevice(device),
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
  final BluetoothConnection connection;

  const RemoteControlPage({
    super.key,
    required this.device,
    required this.connection,
  });

  @override
  State<RemoteControlPage> createState() => _RemoteControlPageState();
}

class _RemoteControlPageState extends State<RemoteControlPage> {
  bool _isConnected = true;
  bool _isDragging = false;
  bool _isDrawingMode = false; // false = hareket modu, true = çizim modu
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for connection state
    _connectionSubscription = widget.connection.input?.listen(
      (_) {},
      onDone: () {
        if (mounted) {
          setState(() => _isConnected = false);
          _showError('Bağlantı kesildi');
          Navigator.pop(context);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isConnected = false);
          _showError('Bağlantı hatası: $error');
        }
      },
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _sendEvent(Map<String, dynamic> event) {
    if (!_isConnected) return;

    try {
      final json = jsonEncode(event);
      final message = '$json\n';
      widget.connection.writeString(message);
    } catch (e) {
      _showError('Gönderme hatası: $e');
    }
  }

  void _handlePanStart(DragStartDetails details) {
    // Çizim modunda mouse tuşunu bas
    if (_isDrawingMode) {
      setState(() {
        _isDragging = true;
      });
      _sendEvent({
        'type': 'mousedown',
        'button': 0, // Left button
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Her iki modda da mouse'u hareket ettir
    const double sensitivity = 2.0; // Increase for faster movement

    _sendEvent({
      'type': 'mousedelta',
      'deltaX': details.delta.dx * sensitivity,
      'deltaY': details.delta.dy * sensitivity,
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    // Çizim modunda mouse tuşunu bırak
    if (_isDrawingMode && _isDragging) {
      setState(() {
        _isDragging = false;
      });
      _sendEvent({
        'type': 'mouseup',
        'button': 0,
      });
    }
  }

  void _handleTap() {
    // Send mouse click (quick tap without drag)
    _sendEvent({
      'type': 'mousedown',
      'button': 0, // Left button
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      _sendEvent({
        'type': 'mouseup',
        'button': 0,
      });
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
        title: Text('Bağlı: ${widget.device.name ?? "Bilinmeyen"}'),
        centerTitle: true,
        backgroundColor: _isConnected ? null : Colors.red,
      ),
      body: Column(
        children: [
          // Connection status
          if (!_isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              child: const Text(
                'Bağlantı kesildi',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Touchpad area
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Mod göstergesi ve toggle butonu
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isDrawingMode ? Icons.edit : Icons.mouse,
                            color: _isDrawingMode ? Colors.green : Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isDrawingMode ? 'Çizim Modu' : 'Hareket Modu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  _isDrawingMode ? Colors.green : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _isConnected
                            ? () {
                                setState(() {
                                  _isDrawingMode = !_isDrawingMode;
                                });
                              }
                            : null,
                        icon: Icon(_isDrawingMode ? Icons.mouse : Icons.edit),
                        label: Text(_isDrawingMode ? 'Hareket' : 'Çizim'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isDrawingMode ? Colors.blue : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                // Touchpad
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDrawingMode ? Colors.green : Colors.blue,
                        width: 2,
                      ),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: _handlePanStart,
                      onPanUpdate: _handlePanUpdate,
                      onPanEnd: _handlePanEnd,
                      onTap: _handleTap,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isDrawingMode ? Icons.edit : Icons.touch_app,
                              size: 48,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isDrawingMode ? 'Çizim Modu' : 'Hareket Modu',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isDrawingMode
                                  ? 'Basılı tutarak çizin'
                                  : 'Parmağınızı sürükleyin',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                        _buildButton('Temizle', 'C', Icons.delete_outline,
                            () => _sendKeyPress('c')),
                        _buildButton('Geri Al', 'Z', Icons.undo,
                            () => _sendKeyPress('z')),
                        _buildButton('Silgi', 'E', Icons.edit_off,
                            () => _sendKeyPress('e')),
                        _buildButton('Kapat', 'Q', Icons.close,
                            () => _sendKeyPress('q')),
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

  Widget _buildButton(
      String label, String key, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isConnected ? onPressed : null,
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
