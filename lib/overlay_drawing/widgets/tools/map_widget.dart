import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  final List<LatLng> _pins = [];
  String _mapType = 'osm'; // 'osm' or 'satellite'

  void _addPin(TapPosition tapPosition, LatLng point) {
    setState(() {
      _pins.add(point);
    });
  }

  void _removePin(LatLng point) {
    setState(() {
      _pins.remove(point);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine Tile URL
    String tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    if (_mapType == 'satellite') {
      // Esri World Imagery
      tileUrl =
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 2),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.map_rounded, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Harita',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                _MapTypeButton(
                  label: 'Sokak',
                  isSelected: _mapType == 'osm',
                  onTap: () => setState(() => _mapType = 'osm'),
                ),
                const SizedBox(width: 8),
                _MapTypeButton(
                  label: 'Uydu',
                  isSelected: _mapType == 'satellite',
                  onTap: () => setState(() => _mapType = 'satellite'),
                ),
                const Spacer(),
                const Text(
                  'Uzun basarak veya tıklayarak pin ekle',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Map Content
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(39.9334, 32.8597), // Ankara
                initialZoom: 6.0,
                onTap: _addPin,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.techatlas.app',
                ),
                MarkerLayer(
                  markers: _pins
                      .map(
                        (point) => Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showPinDetails(point),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Attribution (Optional but good practice)
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPinDetails(LatLng point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum İşaretlendi'),
        content: Text(
          'Koordinatlar:\nEnlem: ${point.latitude.toStringAsFixed(4)}\nBoylam: ${point.longitude.toStringAsFixed(4)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _removePin(point);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

class _MapTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
