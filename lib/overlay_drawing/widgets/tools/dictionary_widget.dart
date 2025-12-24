import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import '../../../widgets/keyboard_text_field.dart';

class DictionaryWidget extends StatefulWidget {
  const DictionaryWidget({super.key});

  @override
  State<DictionaryWidget> createState() => _DictionaryWidgetState();
}

class _DictionaryWidgetState extends State<DictionaryWidget> {
  final GoogleTranslator _translator = GoogleTranslator();
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _controller = TextEditingController();

  String _translation = '';
  bool _isLoading = false;

  // Language Codes
  String _sourceLang = 'tr';
  String _targetLang = 'en';

  // Top 10 World Languages + Turkish
  final Map<String, String> _languages = {
    'tr': 'Türkçe',
    'en': 'İngilizce',
    'de': 'Almanca',
    'fr': 'Fransızca',
    'es': 'İspanyolca',
    'it': 'İtalyanca',
    'ru': 'Rusça',
    'zh-cn': 'Çince',
    'ja': 'Japonca',
    'ar': 'Arapça',
    'pt': 'Portekizce',
  };

  // Helper for TTS locale codes
  String _getTtsCode(String langCode) {
    switch (langCode) {
      case 'tr':
        return 'tr-TR';
      case 'en':
        return 'en-US';
      case 'de':
        return 'de-DE';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'it':
        return 'it-IT';
      case 'ru':
        return 'ru-RU';
      case 'zh-cn':
        return 'zh-CN';
      case 'ja':
        return 'ja-JP';
      case 'ar':
        return 'ar-SA';
      case 'pt':
        return 'pt-BR';
      default:
        return 'en-US';
    }
  }

  Future<void> _translate() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _translation = '';
    });

    try {
      var result = await _translator.translate(
        _controller.text,
        from: _sourceLang,
        to: _targetLang,
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
          _translation = 'Hata: Çeviri yapılamadı.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _speak(String text, String languageCode) async {
    if (text.isEmpty) return;
    try {
      await _flutterTts.setLanguage(_getTtsCode(languageCode));
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {}
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
      _translation = ''; // Clear result
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Language Selectors
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildLangDropdown(
                    value: _sourceLang,
                    color: Colors.blue.shade900,
                    onChanged: (val) => setState(() => _sourceLang = val!),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.indigo),
                  onPressed: _swapLanguages,
                  tooltip: 'Değiştir',
                ),
                Expanded(
                  child: _buildLangDropdown(
                    value: _targetLang,
                    color: Colors.red.shade900,
                    onChanged: (val) => setState(() => _targetLang = val!),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Input Area
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: KeyboardTextField(
                        controller: _controller,
                        hintText: 'Metin girin...',
                        maxLines: 4,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        onSubmitted: (_) => _translate(),
                      ),
                    ),
                  ),
                  // Actions Bar for Input
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.volume_up,
                            size: 20,
                            color: Colors.blue,
                          ),
                          onPressed: () =>
                              _speak(_controller.text, _sourceLang),
                          tooltip: 'Dinle',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _translate,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.translate, size: 16),
                          label: const Text('Çevir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Result Area
          if (_translation.isNotEmpty || _isLoading)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SingleChildScrollView(
                          child: Text(
                            _translation,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!_isLoading && _translation.isNotEmpty)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.indigo,
                            ),
                            onPressed: () => _speak(_translation, _targetLang),
                            tooltip: 'Okunuşu Dinle',
                          ),
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

  Widget _buildLangDropdown({
    required String value,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: color),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          onChanged: onChanged,
          items: _languages.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }
}
