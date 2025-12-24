import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({super.key});

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  String _expression = '';
  String _result = '0';
  bool _isScientific = false;
  bool _isDegree = true; // Default to Degrees

  void _onPressed(String text) {
    setState(() {
      if (text == 'C') {
        _expression = '';
        _result = '0';
      } else if (text == 'DEL') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (text == '=') {
        try {
          Parser p = Parser();
          String finalExp = _expression
              .replaceAll('x', '*')
              .replaceAll('÷', '/')
              .replaceAll('π', '3.14159265')
              .replaceAll('e', '2.71828');

          if (finalExp.isEmpty) return;

          // Auto-close parentheses
          int openCount = '('.allMatches(finalExp).length;
          int closeCount = ')'.allMatches(finalExp).length;
          if (openCount > closeCount) {
            finalExp += ')' * (openCount - closeCount);
          }

          // Handle Degrees conversion for sin/cos/tan
          // Note: math_expressions uses Radians.
          // We wrap the valid terms? No, string replacement is risky if nested.
          // BUT, injecting conversion factor at the function start is safe logic-wise:
          // sin(30) -> sin((30) * deg2rad) ?
          // No, sin(X) in deg is sin(X * pi/180).
          // Replaces 'sin(' with 'sin((3.14159265/180)*'

          if (_isDegree) {
            finalExp = finalExp.replaceAll('sin(', 'sin((3.14159265/180)*');
            finalExp = finalExp.replaceAll('cos(', 'cos((3.14159265/180)*');
            finalExp = finalExp.replaceAll('tan(', 'tan((3.14159265/180)*');
            // Inverses like asin need result conversion? asin(x) gives radians -> * 180/pi
            // We only implemented sin/cos/tan buttons so far.
          }

          Expression exp = p.parse(finalExp);
          ContextModel cm = ContextModel();
          double eval = exp.evaluate(EvaluationType.REAL, cm);

          _result = eval.toString();
          if (_result.endsWith('.0')) {
            _result = _result.substring(0, _result.length - 2);
          }
        } catch (e) {
          _result = 'Hata';
          //
        }
      } else {
        // Functions
        if (['sin', 'cos', 'tan', 'log', 'ln', 'sqrt'].contains(text)) {
          _expression += '$text(';
        } else {
          _expression += text;
        }
      }
    });
  }

  Widget _buildButton(
    String text, {
    Color? color,
    Color? textColor,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.all(2),
        child: ElevatedButton(
          onPressed: () => _onPressed(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.white,
            foregroundColor: textColor ?? Colors.black87,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        children: [
          // Display Area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Mode Toggle Bar
          Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Scientific Toggle
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _isScientific = !_isScientific),
                  icon: Icon(
                    _isScientific ? Icons.science : Icons.calculate,
                    size: 18,
                  ),
                  label: Text(
                    _isScientific ? 'Basit' : 'Bilimsel',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),

                // DEG / RAD Toggle
                if (_isScientific)
                  GestureDetector(
                    onTap: () => setState(() => _isDegree = !_isDegree),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isDegree ? 'DEG' : 'RAD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: Colors.black54,
                  ),
                  onPressed: () => _onPressed('DEL'),
                  tooltip: 'Sil',
                ),
              ],
            ),
          ),

          // Keypad
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  if (_isScientific)
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(
                            'sin',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                          _buildButton(
                            'cos',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                          _buildButton(
                            'tan',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                          _buildButton(
                            '^',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                          _buildButton(
                            'sqrt',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                  if (_isScientific)
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(
                            'ln',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                          _buildButton(
                            'log',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                          _buildButton(
                            '(',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                          _buildButton(
                            ')',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                          _buildButton(
                            'e',
                            color: Colors.indigo.shade50,
                            textColor: Colors.indigo,
                          ),
                        ],
                      ),
                    ),

                  // Standard Keypad
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          'C',
                          color: Colors.red.shade100,
                          textColor: Colors.red,
                        ),
                        _buildButton('π', color: Colors.grey.shade300),
                        _buildButton('%', color: Colors.grey.shade300),
                        _buildButton(
                          '÷',
                          color: Colors.orange.shade100,
                          textColor: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('7'),
                        _buildButton('8'),
                        _buildButton('9'),
                        _buildButton(
                          'x',
                          color: Colors.orange.shade100,
                          textColor: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('4'),
                        _buildButton('5'),
                        _buildButton('6'),
                        _buildButton(
                          '-',
                          color: Colors.orange.shade100,
                          textColor: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('1'),
                        _buildButton('2'),
                        _buildButton('3'),
                        _buildButton(
                          '+',
                          color: Colors.orange.shade100,
                          textColor: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('0', flex: 2),
                        _buildButton('.'),
                        _buildButton(
                          '=',
                          color: Colors.orange,
                          textColor: Colors.white,
                        ),
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
}
