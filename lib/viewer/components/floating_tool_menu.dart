import 'package:flutter/material.dart';

class FloatingToolMenu extends StatelessWidget {
  final VoidCallback onOpenCalculator; // Keep for backward compatibility
  final VoidCallback onOpenScratchpad;
  final Function(String)? onToolSelected;

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
      bottom: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
          child: Container(
            width: 240,
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGroup(
                    context,
                    title: 'Ders Araçları',
                    icon: Icons.school_rounded,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.science,
                        label: 'Periyodik Tablo',
                        color: Colors.green,
                        onTap: () => onToolSelected?.call('periodic_table'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.wb_sunny_rounded,
                        label: 'Güneş Sistemi',
                        color: Colors.deepPurple,
                        onTap: () => onToolSelected?.call('solar_system'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.accessibility_new_rounded,
                        label: 'İnsan Vücudu',
                        color: Colors.blueGrey,
                        onTap: () => onToolSelected?.call('anatomy'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.map,
                        label: 'Harita',
                        color: Colors.blue,
                        onTap: () => onToolSelected?.call('map'),
                      ),
                    ],
                  ),
                  _buildDivider(context),
                  _buildGroup(
                    context,
                    title: 'Genel Araçlar',
                    icon: Icons.apps_rounded,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.calculate,
                        label: 'Hesap Makinesi',
                        color: Colors.orange,
                        onTap: () => onToolSelected?.call('calculator'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.translate,
                        label: 'Sözlük & Çeviri',
                        color: Colors.indigo,
                        onTap: () => onToolSelected?.call('dictionary'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.swap_vert_circle_outlined,
                        label: 'Birim Çevirici',
                        color: Colors.teal,
                        onTap: () => onToolSelected?.call('unit_converter'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.edit_note,
                        label: 'Not Defteri',
                        color: Colors.grey,
                        onTap: onOpenScratchpad,
                      ),
                    ],
                  ),
                  _buildDivider(context),
                  _buildGroup(
                    context,
                    title: 'Aktivite & Oyun',
                    icon: Icons.sports_esports,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.piano,
                        label: 'Piyano',
                        color: Colors.pink,
                        onTap: () => onToolSelected?.call('piano'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.casino,
                        label: 'Zar / Kura',
                        color: Colors.purple,
                        onTap: () => onToolSelected?.call('dice'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.code,
                        label: 'Kodlama Atölyesi',
                        color: Colors.orangeAccent,
                        onTap: () => onToolSelected?.call('coding_blocks'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.black54, size: 20),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        childrenPadding: EdgeInsets.zero,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        // initiallyExpanded: false,
        children: children,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 10,
      endIndent: 10,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
