import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DiceWidget extends StatefulWidget {
  const DiceWidget({super.key});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Zar State
  int _die1 = 1;
  int _die2 = 1;
  bool _twoDice = false;
  bool _isRollingDice = false;

  // Coin State
  bool _isHeads = true;
  bool _isFlippingCoin = false;

  // Kura State
  final TextEditingController _kuraController = TextEditingController();
  final List<String> _participants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _kuraController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _rollDice() {
    if (_isRollingDice) return;
    setState(() => _isRollingDice = true);

    Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _die1 = Random().nextInt(6) + 1;
        _die2 = Random().nextInt(6) + 1;
      });
      if (timer.tick > 10) {
        timer.cancel();
        setState(() => _isRollingDice = false);
      }
    });
  }

  void _flipCoin() {
    if (_isFlippingCoin) return;
    setState(() {
      _isFlippingCoin = true;
    });

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _isHeads = Random().nextBool();
      });
      if (timer.tick > 20) {
        timer.cancel();
        setState(() => _isFlippingCoin = false);
      }
    });
  }

  void _addParticipant() {
    if (_kuraController.text.trim().isNotEmpty) {
      setState(() {
        _participants.add(_kuraController.text.trim());
        _kuraController.clear();
      });
    }
  }

  void _drawWinner() {
    if (_participants.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => _WinnerDialog(participants: _participants),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(icon: Icon(Icons.casino), text: 'Zar'),
              Tab(icon: Icon(Icons.monetization_on), text: 'Yazı Tura'),
              Tab(icon: Icon(Icons.list), text: 'Kura'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Zar Tab
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDie(_die1),
                        if (_twoDice) ...[
                          const SizedBox(width: 20),
                          _buildDie(_die2),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Toplam: ${_twoDice ? _die1 + _die2 : _die1}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('1 Zar'),
                        Switch(
                          value: _twoDice,
                          onChanged: (v) => setState(() => _twoDice = v),
                        ),
                        const Text('2 Zar'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _rollDice,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Zar At'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                // Yazı Tura Tab
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.shade400,
                        border: Border.all(
                          color: Colors.amber.shade700,
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isHeads ? 'TURA' : 'YAZI',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _flipCoin,
                      icon: const Icon(Icons.rotate_right),
                      label: const Text('Para At'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                // Kura Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _kuraController,
                              decoration: const InputDecoration(
                                hintText: 'İsim ekle...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onSubmitted: (_) => _addParticipant(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addParticipant,
                            icon: const Icon(
                              Icons.add_circle,
                              size: 32,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _participants.isEmpty
                          ? const Center(child: Text('Henüz isim eklenmedi.'))
                          : ListView.builder(
                              itemCount: _participants.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(_participants[index]),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => setState(
                                      () => _participants.removeAt(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _participants.isEmpty ? null : _drawWinner,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Çekiliş Yap',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDie(int value) {
    // Basic distinct faces
    List<Widget> dots = [];
    if ([1, 3, 5].contains(value))
      dots.add(const Align(alignment: Alignment.center, child: _Dot()));
    if ([2, 3, 4, 5, 6].contains(value)) {
      dots.add(const Align(alignment: Alignment.topLeft, child: _Dot()));
      dots.add(const Align(alignment: Alignment.bottomRight, child: _Dot()));
    }
    if ([4, 5, 6].contains(value)) {
      dots.add(const Align(alignment: Alignment.topRight, child: _Dot()));
      dots.add(const Align(alignment: Alignment.bottomLeft, child: _Dot()));
    }
    if (value == 6) {
      dots.add(const Align(alignment: Alignment.centerLeft, child: _Dot()));
      dots.add(const Align(alignment: Alignment.centerRight, child: _Dot()));
    }

    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Stack(children: dots),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WinnerDialog extends StatefulWidget {
  final List<String> participants;
  const _WinnerDialog({required this.participants});

  @override
  State<_WinnerDialog> createState() => _WinnerDialogState();
}

class _WinnerDialogState extends State<_WinnerDialog> {
  String _currentName = '';
  late Timer _timer;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _currentName =
            widget.participants[Random().nextInt(widget.participants.length)];
        _ticks++;
      });

      if (_ticks > 20) {
        timer.cancel();
        _showConfetti();
      }
    });
  }

  void _showConfetti() {
    // TODO: Add confetti if available, simple scale animation for now
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kazanan Belirleniyor...'),
      content: SizedBox(
        height: 100,
        child: Center(
          child: Text(
            _currentName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _timer.isActive ? Colors.grey : Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      actions: [
        if (!_timer.isActive)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
      ],
    );
  }
}
