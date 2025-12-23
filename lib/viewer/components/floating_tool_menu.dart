import 'package:flutter/material.dart';

class FloatingToolMenu extends StatelessWidget {
  final VoidCallback
  onOpenCalculator; // Keep for backward compatibility if needed, or remove
  final VoidCallback onOpenScratchpad;
  final Function(String)? onToolSelected; // [NEW]

  const FloatingToolMenu({
    super.key,
    required this.onOpenCalculator,
    required this.onOpenScratchpad,
    this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80, // Moved to bottom right
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          child: Container(
            width: 180, // Slightly wider
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.calculate_rounded,
                  label: 'Hesap Makinesi',
                  color: Colors.orange,
                  onTap: () => onToolSelected?.call('calculator'),
                ),
                _buildDivider(context),
                _buildMenuItem(
                  context,
                  icon: Icons.casino_rounded,
                  label: 'Zar / Kura',
                  color: Colors.purple,
                  onTap: () => onToolSelected?.call('dice'),
                ),
                _buildDivider(context),
                _buildMenuItem(
                  context,
                  icon: Icons.science_rounded,
                  label: 'Periyodik Tablo',
                  color: Colors.green,
                  onTap: () => onToolSelected?.call('periodic_table'),
                ),
                _buildDivider(context),
                _buildMenuItem(
                  context,
                  icon: Icons.map_rounded,
                  label: 'Harita',
                  color: Colors.blue,
                  onTap: () => onToolSelected?.call('map'),
                ),
                _buildDivider(context),
                _buildMenuItem(
                  context,
                  icon: Icons.translate_rounded,
                  label: 'Sözlük & Çeviri',
                  color: Colors.indigo,
                  onTap: () => onToolSelected?.call('dictionary'),
                ),
                _buildDivider(context),
                _buildMenuItem(
                  context,
                  icon: Icons.piano_rounded,
                  label: 'Piyano',
                  color: Colors.pink,
                  onTap: () => onToolSelected?.call('piano'),
                ),
                _buildDivider(context),
                _buildMenuItem(
                  context,
                  icon: Icons.edit_note_rounded,
                  label: 'Not Defteri',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: onOpenScratchpad,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 10,
      endIndent: 10,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10, // Increased touch area
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
