import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class DictionaryWidget extends StatefulWidget {
  const DictionaryWidget({super.key});

  @override
  State<DictionaryWidget> createState() => _DictionaryWidgetState();
}

class _DictionaryWidgetState extends State<DictionaryWidget> {
  final GoogleTranslator _translator = GoogleTranslator();
  final TextEditingController _controller = TextEditingController();

  String _translation = '';
  bool _isLoading = false;

  // Toggle: true = TR -> EN, false = EN -> TR
  bool _trToEn = true;

  Future<void> _translate() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _translation = '';
    });

    try {
      var from = _trToEn ? 'tr' : 'en';
      var to = _trToEn ? 'en' : 'tr';

      var result = await _translator.translate(
        _controller.text,
        from: from,
        to: to,
      );

      if (mounted) {
        setState(() {
          _translation = result.text;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translation =
              'Hata: Çeviri yapılamadı.\nİnternet bağlantınızı kontrol edin.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Language Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _trToEn ? 'Türkçe' : 'İngilizce',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _trToEn = !_trToEn;
                    // Auto translate if text exists
                    if (_translation.isNotEmpty ||
                        _controller.text.isNotEmpty) {
                      // Swap input/output visually?
                      // No, just mode switch. User might want to re-translate same text to other lang?
                      // Usually swapping means swapping input. Logic:
                      // If we have a translation, we could put it in input?
                      // Let's keep it simple: just toggle mode.
                    }
                  });
                },
              ),
              Text(
                _trToEn ? 'İngilizce' : 'Türkçe',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Input
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Metni buraya girin...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: (_) => _translate(),
          ),

          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _translate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Çevir'),
          ),

          const SizedBox(height: 20),
          const Divider(),

          // Output
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Çeviri:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translation.isEmpty ? '...' : _translation,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
