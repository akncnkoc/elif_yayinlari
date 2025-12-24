import 'package:flutter/material.dart';
import '../../../widgets/keyboard_text_field.dart';

class UnitConverterWidget extends StatefulWidget {
  const UnitConverterWidget({super.key});

  @override
  State<UnitConverterWidget> createState() => _UnitConverterWidgetState();
}

class _UnitConverterWidgetState extends State<UnitConverterWidget> {
  final TextEditingController _inputController = TextEditingController();

  String _selectedCategory = 'Uzunluk';
  String _fromUnit = 'Metre';
  String _toUnit = 'Santimetre';
  double _result = 0.0;

  final Map<String, List<String>> _units = {
    'Uzunluk': ['Metre', 'Santimetre', 'Kilometre', 'Mil', 'İnç', 'Fit'],
    'Ağırlık': ['Kilogram', 'Gram', 'Miligram', 'Ton', 'Pound'],
    'Sıcaklık': ['Celsius', 'Fahrenheit', 'Kelvin'],
  };

  final Map<String, double> _lengthFactors = {
    // Base: Meter
    'Metre': 1.0,
    'Santimetre': 0.01,
    'Kilometre': 1000.0,
    'Mil': 1609.34,
    'İnç': 0.0254,
    'Fit': 0.3048,
  };

  final Map<String, double> _weightFactors = {
    // Base: Kilogram
    'Kilogram': 1.0,
    'Gram': 0.001,
    'Miligram': 0.000001,
    'Ton': 1000.0,
    'Pound': 0.453592,
  };

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_convert);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    if (_inputController.text.isEmpty) {
      setState(() => _result = 0.0);
      return;
    }

    double input =
        double.tryParse(_inputController.text.replaceAll(',', '.')) ?? 0.0;
    double output = 0.0;

    if (_selectedCategory == 'Uzunluk') {
      double inMeters = input * _lengthFactors[_fromUnit]!;
      output = inMeters / _lengthFactors[_toUnit]!;
    } else if (_selectedCategory == 'Ağırlık') {
      double inKg = input * _weightFactors[_fromUnit]!;
      output = inKg / _weightFactors[_toUnit]!;
    } else if (_selectedCategory == 'Sıcaklık') {
      output = _convertTemperature(input, _fromUnit, _toUnit);
    }

    setState(() {
      _result = output;
    });
  }

  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;

    // Convert to Celsius first
    double celsius;
    if (from == 'Celsius')
      celsius = value;
    else if (from == 'Fahrenheit')
      celsius = (value - 32) * 5 / 9;
    else /* Kelvin */
      celsius = value - 273.15;

    // Convert to Target
    if (to == 'Celsius') return celsius;
    if (to == 'Fahrenheit') return (celsius * 9 / 5) + 32;
    /* Kelvin */
    return celsius + 273.15;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Category Selector
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                      _fromUnit = _units[val]!.first;
                      _toUnit = _units[val]![1];
                      _convert();
                    });
                  }
                },
                items: _units.keys
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // From Section
          Row(
            children: [
              Expanded(
                flex: 2,
                child: KeyboardTextField(
                  controller: _inputController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildUnitDropdown(_fromUnit, (val) {
                  setState(() {
                    _fromUnit = val!;
                    _convert();
                  });
                }),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.arrow_downward, color: Colors.grey),
          ),

          // To Section
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _result
                        .toStringAsFixed(4)
                        .replaceAll(
                          RegExp(r'([.]*0)(?!.*\d)'),
                          '',
                        ), // Remove trailing zeros
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildUnitDropdown(_toUnit, (val) {
                  setState(() {
                    _toUnit = val!;
                    _convert();
                  });
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(String current, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          onChanged: onChanged,
          items: _units[_selectedCategory]!
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
        ),
      ),
    );
  }
}
