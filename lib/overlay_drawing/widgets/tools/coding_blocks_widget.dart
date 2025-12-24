import 'package:flutter/material.dart';
import 'dart:async';

class CodingBlocksWidget extends StatefulWidget {
  const CodingBlocksWidget({super.key});

  @override
  State<CodingBlocksWidget> createState() => _CodingBlocksWidgetState();
}

enum Direction { up, right, down, left }

enum CommandType { forward, left, right }

class _CodingBlocksWidgetState extends State<CodingBlocksWidget> {
  // Game State
  final int gridSize = 5;
  int playerX = 0;
  int playerY = 0;
  Direction playerDir = Direction.right;
  final int goalX = 4;
  final int goalY = 2;

  // Obstacles
  final List<List<int>> obstacles = [
    [1, 1],
    [3, 3],
    [1, 3],
    [3, 1],
  ];

  // Code
  final List<CommandType> _program = [];
  bool _isRunning = false;
  String _status = 'Hedefe ulaşmak için komutları ekle!';

  void _reset() {
    setState(() {
      playerX = 0;
      playerY = 0;
      playerDir = Direction.right;
      _isRunning = false;
      _status = 'Hazır.';
    });
  }

  void _addCommand(CommandType type) {
    if (_isRunning) return;
    setState(() {
      _program.add(type);
    });
  }

  void _clearProgram() {
    setState(() {
      _program.clear();
      _reset();
    });
  }

  Future<void> _runProgram() async {
    if (_program.isEmpty) return;
    _reset();
    setState(() => _isRunning = true);

    for (var cmd in _program) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        switch (cmd) {
          case CommandType.forward:
            _moveForward();
            break;
          case CommandType.left:
            _turnLeft();
            break;
          case CommandType.right:
            _turnRight();
            break;
        }
      });

      // Check collision
      if (_checkCollision()) {
        setState(() {
          _status = 'Kaza! Bir engele çarptın.';
          _isRunning = false;
        });
        return;
      }

      // Check win
      if (playerX == goalX && playerY == goalY) {
        setState(() {
          _status = 'Tebrikler! Hedefe ulaştın! 🎉';
          _isRunning = false;
        });
        return;
      }
    }

    if (_status == 'Hazır.') {
      setState(() => _status = 'Program bitti ama hedefe ulaşamadın.');
      _isRunning = false;
    }
  }

  void _moveForward() {
    int nextX = playerX;
    int nextY = playerY;
    switch (playerDir) {
      case Direction.up:
        nextY--;
        break;
      case Direction.right:
        nextX++;
        break;
      case Direction.down:
        nextY++;
        break;
      case Direction.left:
        nextX--;
        break;
    }
    // Boundary check
    if (nextX >= 0 && nextX < gridSize && nextY >= 0 && nextY < gridSize) {
      playerX = nextX;
      playerY = nextY;
    }
  }

  void _turnLeft() {
    int idx = playerDir.index - 1;
    if (idx < 0) idx = 3;
    playerDir = Direction.values[idx];
  }

  void _turnRight() {
    int idx = playerDir.index + 1;
    if (idx > 3) idx = 0;
    playerDir = Direction.values[idx];
  }

  bool _checkCollision() {
    for (var obs in obstacles) {
      if (obs[0] == playerX && obs[1] == playerY) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top: Game & Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.blueGrey.shade50,
                    child: Center(child: _buildGrid()),
                  ),
                ),
              ],
            ),
          ),

          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: _status.contains('Tebrikler')
                ? Colors.green.shade100
                : Colors.grey.shade200,
            child: Text(
              _status,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // Bottom: Controls & Program
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Toolbox
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCmdBtn(
                        Icons.arrow_upward,
                        'İleri',
                        CommandType.forward,
                        Colors.green,
                      ),
                      Row(
                        children: [
                          _buildCmdBtn(
                            Icons.turn_left,
                            'Sol',
                            CommandType.left,
                            Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          _buildCmdBtn(
                            Icons.turn_right,
                            'Sağ',
                            CommandType.right,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const VerticalDivider(),
                  // Program Strip
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Program:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: _clearProgram,
                                  tooltip: 'Temizle',
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Çalıştır'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _isRunning ? null : _runProgram,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _program
                                  .map(
                                    (cmd) => Container(
                                      margin: const EdgeInsets.all(2),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: cmd == CommandType.forward
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Icon(_getIcon(cmd), size: 16),
                                    ),
                                  )
                                  .toList(),
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
        ],
      ),
    );
  }

  IconData _getIcon(CommandType type) {
    if (type == CommandType.forward) return Icons.arrow_upward;
    if (type == CommandType.left) return Icons.turn_left;
    return Icons.turn_right;
  }

  Widget _buildCmdBtn(
    IconData icon,
    String label,
    CommandType type,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(60, 30),
        ),
        onPressed: () => _addCommand(type),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        itemCount: gridSize * gridSize,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
        ),
        itemBuilder: (context, index) {
          int x = index % gridSize;
          int y = index ~/ gridSize;

          bool isPlayer = (x == playerX && y == playerY);
          bool isGoal = (x == goalX && y == goalY);
          bool isObstacle = false;
          for (var o in obstacles)
            if (o[0] == x && o[1] == y) isObstacle = true;

          Color bg = (x + y) % 2 == 0 ? Colors.white : Colors.grey.shade50;
          if (isObstacle) bg = Colors.red.shade100;

          return Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: Colors.black12),
            ),
            child: Center(
              child: isPlayer
                  ? Transform.rotate(
                      angle: _getRotation(),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.blue,
                        size: 32,
                      ),
                    )
                  : isGoal
                  ? const Icon(Icons.flag, color: Colors.green, size: 32)
                  : isObstacle
                  ? const Icon(Icons.block, color: Colors.red, size: 24)
                  : null,
            ),
          );
        },
      ),
    );
  }

  double _getRotation() {
    switch (playerDir) {
      case Direction.up:
        return 0;
      case Direction.right:
        return 1.57;
      case Direction.down:
        return 3.14;
      case Direction.left:
        return 4.71;
    }
  }
}
