import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/crop_data.dart';
import 'animation_player_widget.dart';
import 'drawable_content_widget.dart';
import '../tool_state.dart';

class SolutionDetailDialog extends StatefulWidget {
  final CropItem crop;
  final String baseDirectory;
  final String? zipFilePath;
  final Uint8List? zipBytes; // Web platformu için

  const SolutionDetailDialog({
    super.key,
    required this.crop,
    required this.baseDirectory,
    this.zipFilePath,
    this.zipBytes,
  });

  @override
  State<SolutionDetailDialog> createState() => _SolutionDetailDialogState();
}

class _SolutionDetailDialogState extends State<SolutionDetailDialog> {
  final GlobalKey<AnimationPlayerWidgetState> _animationKey =
      GlobalKey<AnimationPlayerWidgetState>();
  final GlobalKey<DrawableContentWidgetState> _drawableKey =
      GlobalKey<DrawableContentWidgetState>();

  // Drawing state
  bool _isDrawingMode = false;
  final ValueNotifier<ToolState> _toolNotifier = ValueNotifier<ToolState>(
    ToolState(
      mouse: true,
      eraser: false,
      pencil: false,
      highlighter: false,
      grab: false,
      shape: false,
      selection: false,
      magnifier: false,
      selectedShape: ShapeType.rectangle,
      color: Colors.red,
      width: 2.0,
    ),
  );

  @override
  void dispose() {
    _toolNotifier.dispose();
    super.dispose();
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (_isDrawingMode) {
        // Enable pencil by default when entering drawing mode
        _toolNotifier.value = _toolNotifier.value.copyWith(
          pencil: true,
          mouse: false,
        );
      } else {
        // Return to mouse mode
        _toolNotifier.value = _toolNotifier.value.copyWith(
          pencil: false,
          mouse: true,
        );
      }
    });
  }

  void _selectTool(String tool) {
    final currentTool = _toolNotifier.value;
    _toolNotifier.value = currentTool.copyWith(
      pencil: tool == 'pencil',
      eraser: tool == 'eraser',
      highlighter: tool == 'highlighter',
      shape: tool == 'shape',
      mouse: false,
    );
  }

  void _selectShape(ShapeType shape) {
    _toolNotifier.value = _toolNotifier.value.copyWith(
      selectedShape: shape,
    );
  }

  void _selectColor(Color color) {
    _toolNotifier.value = _toolNotifier.value.copyWith(
      color: color,
    );
  }

  void _clearDrawing() {
    _drawableKey.currentState?.clearDrawing();
  }

  void _undoDrawing() {
    _drawableKey.currentState?.undo();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.quiz,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Soru ${widget.crop.questionNumber ?? "?"} - Çözüm Animasyonu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content - Horizontal Layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side - Animation Player with Drawing
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          // Content with drawing layer
                          widget.crop.userSolution?.hasAnimationData == true &&
                                  widget.crop.userSolution?.drawingDataFile != null
                              ? DrawableContentWidget(
                                  key: _drawableKey,
                                  isDrawingEnabled: _isDrawingMode,
                                  toolNotifier: _toolNotifier,
                                  child: AnimationPlayerWidget(
                                    key: _animationKey,
                                    animationDataPath:
                                        widget.crop.userSolution!.drawingDataFile!,
                                    baseDirectory: widget.baseDirectory,
                                    zipFilePath: widget.zipFilePath,
                                    zipBytes: widget.zipBytes,
                                  ),
                                )
                              : const Center(
                                  child: Text('Animasyon verisi bulunamadı'),
                                ),

                          // Drawing toolbar (top-left)
                          if (_isDrawingMode)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: _buildDrawingToolbar(),
                            ),

                          // Drawing mode toggle button (top-right)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Column(
                              children: [
                                FloatingActionButton.small(
                                  onPressed: _toggleDrawingMode,
                                  backgroundColor: _isDrawingMode
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  child: Icon(
                                    _isDrawingMode ? Icons.check : Icons.edit,
                                    color: _isDrawingMode
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ),
                                if (_isDrawingMode) ...[
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    onPressed: _undoDrawing,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: Icon(
                                      Icons.undo,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    onPressed: _clearDrawing,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),

                  // Right Side - Controls and Answer
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Answer Choice (large)
                          if (widget.crop.solutionMetadata?.answerChoice != null ||
                              widget.crop.userSolution?.answerChoice != null) ...[
                            const Text(
                              'CEVAP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.crop.solutionMetadata?.answerChoice ??
                                      widget.crop.userSolution?.answerChoice ??
                                      '?',
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Animation Controls
                          const Text(
                            'KONTROLLER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Control Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // First step
                              IconButton(
                                icon: const Icon(Icons.first_page, size: 24),
                                onPressed: () => _animationKey.currentState?.resetAnimation(),
                                tooltip: 'İlk Adım',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primaryContainer,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Previous step
                              IconButton(
                                icon: const Icon(Icons.chevron_left, size: 32),
                                onPressed: () => _animationKey.currentState?.previousStep(),
                                tooltip: 'Geri',
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Next step
                              IconButton(
                                icon: const Icon(Icons.chevron_right, size: 32),
                                onPressed: () => _animationKey.currentState?.nextStep(),
                                tooltip: 'İleri',
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Last step
                              IconButton(
                                icon: const Icon(Icons.last_page, size: 24),
                                onPressed: () => _animationKey.currentState?.goToLastStep(),
                                tooltip: 'Son Adım',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primaryContainer,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Step indicator
                          if (widget.crop.userSolution?.stepsCount != null &&
                              widget.crop.userSolution!.stepsCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${widget.crop.userSolution!.stepsCount} Adım',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    bool hasSolution,
    String? solutionType,
  ) {
    final color = hasSolution ? Colors.green : Colors.orange;
    final icon = hasSolution ? Icons.check_circle : Icons.pending;
    final statusText = hasSolution ? 'Çözüldü' : 'Çözülmedi';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (solutionType != null)
                  Text(
                    _getSolutionTypeText(solutionType),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(BuildContext context, String answer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Seçilen Cevap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualSolutionCard(BuildContext context, UserSolution solution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Manuel Çözüm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              solution.explanation ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            if (solution.drawingFile != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.draw,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Çizim mevcut',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiSolutionCard(BuildContext context, AiSolution aiSolution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Çözümü',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(aiSolution.confidence)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '%${(aiSolution.confidence * 100).toInt()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(aiSolution.confidence),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cevap: ${aiSolution.answer}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aiSolution.reasoning,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            if (aiSolution.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Çözüm Adımları:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...aiSolution.steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(step, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSolvedByCard(BuildContext context, List<String> solvedBy) {
    if (solvedBy.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Çözüm Yöntemi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: solvedBy.map((method) {
                return Chip(
                  label: Text(_getMethodText(method)),
                  avatar: Icon(
                    _getMethodIcon(method),
                    size: 16,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Soru Detayları',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Sayfa', '${widget.crop.pageNumber}'),
            _buildDetailRow('Sınıf', widget.crop.className),
            _buildDetailRow(
              'Güven',
              '%${(widget.crop.confidence * 100).toInt()}',
            ),
            if (widget.crop.questionNumberDetails != null) ...[
              _buildDetailRow(
                'Soru No',
                widget.crop.questionNumberDetails!.text,
              ),
              _buildDetailRow(
                'OCR Güven',
                '%${(widget.crop.questionNumberDetails!.ocrConfidence * 100).toInt()}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getSolutionTypeText(String type) {
    switch (type) {
      case 'manual':
        return 'Manuel olarak çözüldü';
      case 'ai':
        return 'AI tarafından çözüldü';
      case 'mixed':
        return 'Manuel ve AI ile çözüldü';
      default:
        return type;
    }
  }

  String _getMethodText(String method) {
    switch (method) {
      case 'manual':
        return 'Manuel';
      case 'ai':
        return 'AI';
      case 'drawing':
        return 'Çizim';
      default:
        return method;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'manual':
        return Icons.edit;
      case 'ai':
        return Icons.psychology;
      case 'drawing':
        return Icons.draw;
      default:
        return Icons.help;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDrawingToolbar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ValueListenableBuilder<ToolState>(
          valueListenable: _toolNotifier,
          builder: (context, tool, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tools row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pencil
                    _buildToolButton(
                      icon: Icons.edit,
                      isSelected: tool.pencil,
                      onPressed: () => _selectTool('pencil'),
                      tooltip: 'Kalem',
                    ),
                    const SizedBox(width: 4),
                    // Highlighter
                    _buildToolButton(
                      icon: Icons.highlight,
                      isSelected: tool.highlighter,
                      onPressed: () => _selectTool('highlighter'),
                      tooltip: 'Fosforlu Kalem',
                    ),
                    const SizedBox(width: 4),
                    // Eraser
                    _buildToolButton(
                      icon: Icons.auto_fix_high,
                      isSelected: tool.eraser,
                      onPressed: () => _selectTool('eraser'),
                      tooltip: 'Silgi',
                    ),
                    const SizedBox(width: 4),
                    // Shape
                    _buildToolButton(
                      icon: Icons.rectangle,
                      isSelected: tool.shape,
                      onPressed: () => _selectTool('shape'),
                      tooltip: 'Şekiller',
                    ),
                  ],
                ),

                // Shapes row (only shown when shape tool is selected)
                if (tool.shape) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildShapeButton(
                        icon: Icons.rectangle_outlined,
                        isSelected: tool.selectedShape == ShapeType.rectangle,
                        onPressed: () => _selectShape(ShapeType.rectangle),
                        tooltip: 'Dikdörtgen',
                      ),
                      const SizedBox(width: 4),
                      _buildShapeButton(
                        icon: Icons.circle_outlined,
                        isSelected: tool.selectedShape == ShapeType.circle,
                        onPressed: () => _selectShape(ShapeType.circle),
                        tooltip: 'Daire',
                      ),
                      const SizedBox(width: 4),
                      _buildShapeButton(
                        icon: Icons.arrow_forward,
                        isSelected: tool.selectedShape == ShapeType.arrow,
                        onPressed: () => _selectShape(ShapeType.arrow),
                        tooltip: 'Ok',
                      ),
                      const SizedBox(width: 4),
                      _buildShapeButton(
                        icon: Icons.remove,
                        isSelected: tool.selectedShape == ShapeType.line,
                        onPressed: () => _selectShape(ShapeType.line),
                        tooltip: 'Çizgi',
                      ),
                    ],
                  ),
                ],

                // Colors row
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildColorButton(Colors.red, tool.color == Colors.red),
                    const SizedBox(width: 4),
                    _buildColorButton(Colors.blue, tool.color == Colors.blue),
                    const SizedBox(width: 4),
                    _buildColorButton(Colors.green, tool.color == Colors.green),
                    const SizedBox(width: 4),
                    _buildColorButton(Colors.orange, tool.color == Colors.orange),
                    const SizedBox(width: 4),
                    _buildColorButton(Colors.purple, tool.color == Colors.purple),
                    const SizedBox(width: 4),
                    _buildColorButton(Colors.black, tool.color == Colors.black),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildShapeButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color, bool isSelected) {
    return InkWell(
      onTap: () => _selectColor(color),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationCard(BuildContext context) {
    if (widget.crop.userSolution?.drawingDataFile == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.animation,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Çözüm Animasyonu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.crop.userSolution!.stepsCount} Adım',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimationPlayerWidget(
              animationDataPath: widget.crop.userSolution!.drawingDataFile!,
              baseDirectory: widget.baseDirectory,
              zipFilePath: widget.zipFilePath,
              zipBytes: widget.zipBytes,
            ),
          ],
        ),
      ),
    );
  }
}
