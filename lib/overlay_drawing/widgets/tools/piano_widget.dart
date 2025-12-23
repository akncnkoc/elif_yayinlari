import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PianoWidget extends StatefulWidget {
  const PianoWidget({super.key});

  @override
  State<PianoWidget> createState() => _PianoWidgetState();
}

class _PianoWidgetState extends State<PianoWidget> {
  // Define notes for 1 octave (C4 to C5)
  // Using GitHub raw links for ease (Credits: fuhton/piano-mp3)
  final String _baseUrl =
      'https://raw.githubusercontent.com/fuhton/piano-mp3/master/piano-mp3/';

  final List<String> _whiteKeys = [
    'C4',
    'D4',
    'E4',
    'F4',
    'G4',
    'A4',
    'B4',
    'C5',
  ];

  Future<void> _playNote(String note) async {
    try {
      // Create a specific player for polyphony?
      // AudioPlayer simple usage stops previous.
      // To play multiple keys quickly, we might need multiple players or 'mode: PlayerMode.lowLatency'
      // But for this widget, a single player re-triggering is acceptable for "toy" piano.
      // Better: Use a pool if possible, but package simple usage is single track.
      // Let's create a temporary player for each note for polyphony.
      final player = AudioPlayer();
      await player.play(UrlSource('$_baseUrl$note.mp3'));
      // Auto dispose is tricky. AudioPlayer mostly handles it if we don't hold ref.
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint('Error playing note: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
      child: Column(
        children: [
          const Text(
            'Sanal Piyano',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // White Keys
                    Row(
                      children: _whiteKeys.map((note) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                            ),
                            child: _PianoKey(
                              isBlack: false,
                              label: note,
                              onTap: () => _playNote(note),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Black Keys Overlay
                    // Calculated positions based on white keys flex.
                    // 7 gaps between 8 white keys.
                    // C# (Db), D# (Eb), F# (Gb), G# (Ab), A# (Bb)
                    // C D E F G A B C
                    //  ^ ^   ^ ^ ^

                    // Positions (approximate percentages) including gaps
                    // Key width ~ 100% / 8 = 12.5%
                    // Black key should be on the boundary.
                    _buildBlackKey(
                      0,
                      'Db4',
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ), // C-D
                    _buildBlackKey(
                      1,
                      'Eb4',
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ), // D-E
                    // Skip E-F
                    _buildBlackKey(
                      3,
                      'Gb4',
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ), // F-G
                    _buildBlackKey(
                      4,
                      'Ab4',
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ), // G-A
                    _buildBlackKey(
                      5,
                      'Bb4',
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ), // A-B
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlackKey(
    int whiteKeyIndex,
    String note,
    double totalWidth,
    double parentHeight,
  ) {
    // 8 white keys. width = total / 8.
    // Left offset = (index + 1) * width - (blackWidth / 2)
    double whiteKeyWidth = totalWidth / 8;
    double blackKeyWidth = whiteKeyWidth * 0.6;
    double left = (whiteKeyIndex + 1) * whiteKeyWidth - (blackKeyWidth / 2);

    return Positioned(
      left: left,
      top: 0,
      bottom: parentHeight * 0.4,
      width: blackKeyWidth,
      child: _PianoKey(
        isBlack: true,
        label: note,
        onTap: () => _playNote(note),
      ),
    );
  }
}

class _PianoKey extends StatefulWidget {
  final bool isBlack;
  final String label;
  final VoidCallback onTap;

  const _PianoKey({
    required this.isBlack,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PianoKey> createState() => _PianoKeyState();
}

class _PianoKeyState extends State<_PianoKey> {
  bool _isPressed = false;

  void _trigger() {
    widget.onTap();
    setState(() => _isPressed = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _trigger(),
      // onPanUpdate? For sliding fingers.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: widget.isBlack
              ? (_isPressed ? Colors.grey.shade800 : Colors.black)
              : (_isPressed ? Colors.grey.shade300 : Colors.white),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(widget.isBlack ? 4 : 8),
          ),
          border: Border.all(color: Colors.black, width: 1),
          gradient: widget.isBlack
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isPressed
                      ? [Colors.grey.shade400, Colors.grey.shade300]
                      : [Colors.white, Colors.grey.shade100],
                ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isBlack ? Colors.white : Colors.black,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
