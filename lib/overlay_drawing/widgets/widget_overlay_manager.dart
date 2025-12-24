import 'package:flutter/material.dart';
import 'draggable_widget_wrapper.dart';
import 'tools/calculator_widget.dart';
import 'tools/dice_widget.dart';
import 'tools/periodic_table_widget.dart';
import 'tools/map_widget.dart';
import 'tools/dictionary_widget.dart';
import 'tools/piano_widget.dart';
import 'tools/unit_converter_widget.dart';
import 'tools/solar_system_widget.dart';
import 'tools/anatomy_widget.dart';
import 'tools/coding_blocks_widget.dart';

class ActiveWidgetModel {
  final String id;
  final String type;
  Offset position;
  final String title;
  Size? size;

  ActiveWidgetModel({
    required this.id,
    required this.type,
    required this.position,
    required this.title,
    this.size,
  });
}

class WidgetOverlayManager extends StatefulWidget {
  final Widget? child; // The content below (PDF)

  const WidgetOverlayManager({super.key, this.child});

  static WidgetOverlayManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<WidgetOverlayManagerState>();
  }

  @override
  State<WidgetOverlayManager> createState() => WidgetOverlayManagerState();
}

class WidgetOverlayManagerState extends State<WidgetOverlayManager> {
  final List<ActiveWidgetModel> _activeWidgets = [];

  void addWidget(String type) {
    setState(() {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final offset = Offset(
        100.0 + (_activeWidgets.length * 20),
        100.0 + (_activeWidgets.length * 20),
      );

      String title = 'Araç';
      Size? initialSize;

      if (type == 'calculator') {
        title = 'Hesap Makinesi';
        initialSize = const Size(350, 500);
      }
      if (type == 'dice') {
        title = 'Zar / Kura';
        initialSize = const Size(400, 550);
      }
      if (type == 'periodic_table') {
        title = 'Periyodik Tablo';
        initialSize = const Size(900, 600);
      }
      if (type == 'map') {
        title = 'Harita';
        initialSize = const Size(800, 500);
      }
      if (type == 'dictionary') {
        title = 'Sözlük & Çeviri';
        initialSize = const Size(350, 450);
      }
      if (type == 'piano') {
        title = 'Piyano';
        initialSize = const Size(500, 220);
      }
      if (type == 'unit_converter') {
        title = 'Birim Çevirici';
        initialSize = const Size(400, 350);
      }
      if (type == 'solar_system') {
        title = 'Güneş Sistemi';
        initialSize = const Size(800, 800);
      }
      if (type == 'anatomy') {
        title = 'İnsan Vücudu Atlası';
        initialSize = const Size(600, 500);
      }
      if (type == 'coding_blocks') {
        title = 'Kodlama Atölyesi';
        initialSize = const Size(400, 550);
      }

      _activeWidgets.add(
        ActiveWidgetModel(
          id: id,
          type: type,
          position: offset,
          title: title,
          size: initialSize,
        ),
      );
    });
  }

  void removeWidget(String id) {
    setState(() {
      _activeWidgets.removeWhere((w) => w.id == id);
    });
  }

  Widget _buildWidgetContent(String type) {
    switch (type) {
      case 'calculator':
        return const CalculatorWidget();
      case 'dice':
        return const DiceWidget();
      case 'periodic_table':
        return const PeriodicTableWidget();
      case 'map':
        return const MapWidget();
      case 'dictionary':
        return const DictionaryWidget();
      case 'piano':
        return const PianoWidget();
      case 'unit_converter':
        return const UnitConverterWidget();
      case 'solar_system':
        return const SolarSystemWidget();
      case 'anatomy':
        return const AnatomyWidget();
      case 'coding_blocks':
        return const CodingBlocksWidget();
      default:
        return const SizedBox(
          width: 100,
          height: 100,
          child: Center(child: Text('?')),
        );
    }
  }

  Color _getHeaderColor(String type) {
    switch (type) {
      case 'calculator':
        return Colors.orange;
      case 'dice':
        return Colors.purple;
      case 'periodic_table':
        return Colors.green;
      case 'map':
        return Colors.blue;
      case 'dictionary':
        return Colors.indigo;
      case 'piano':
        return Colors.pink;
      case 'unit_converter':
        return Colors.teal;
      case 'solar_system':
        return Colors.deepPurple;
      case 'anatomy':
        return Colors.blueGrey;
      case 'coding_blocks':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) Positioned.fill(child: widget.child!),

        ..._activeWidgets.map((model) {
          return Positioned(
            left: model.position.dx,
            top: model.position.dy,
            child: DraggableWidgetWrapper(
              key: ValueKey(model.id),
              title: model.title,
              headerColor: _getHeaderColor(model.type),
              width: model.size?.width,
              height: model.size?.height,
              onClose: () => removeWidget(model.id),
              onDragUpdate: (details) {
                setState(() {
                  model.position += details.delta;
                });
              },
              onResize: (details) {
                setState(() {
                  // Ensure minimum size
                  double newWidth =
                      (model.size?.width ?? 300) + details.delta.dx;
                  double newHeight =
                      (model.size?.height ?? 300) + details.delta.dy;
                  if (newWidth < 250) newWidth = 250;
                  if (newHeight < 200) newHeight = 200;
                  model.size = Size(newWidth, newHeight);
                });
              },
              child: _buildWidgetContent(model.type),
            ),
          );
        }),
      ],
    );
  }
}
