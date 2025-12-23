import 'package:flutter/material.dart';

class PeriodicTableWidget extends StatefulWidget {
  const PeriodicTableWidget({super.key});

  @override
  State<PeriodicTableWidget> createState() => _PeriodicTableWidgetState();
}

class _PeriodicTableWidgetState extends State<PeriodicTableWidget> {
  // Model for Chemical Elements
  final List<ElementData> _elements = [
    // Period 1
    ElementData(1, 'H', 'Hidrojen', 'Ametal', 1, 1),
    ElementData(2, 'He', 'Helyum', 'Soygaz', 1, 18),
    // Period 2
    ElementData(3, 'Li', 'Lityum', 'Alkali Metal', 2, 1),
    ElementData(4, 'Be', 'Berilyum', 'Toprak Alkali', 2, 2),
    ElementData(5, 'B', 'Bor', 'Yarı Metal', 2, 13),
    ElementData(6, 'C', 'Karbon', 'Ametal', 2, 14),
    ElementData(7, 'N', 'Azot', 'Ametal', 2, 15),
    ElementData(8, 'O', 'Oksijen', 'Ametal', 2, 16),
    ElementData(9, 'F', 'Flor', 'Halojen', 2, 17),
    ElementData(10, 'Ne', 'Neon', 'Soygaz', 2, 18),
    // Period 3
    ElementData(11, 'Na', 'Sodyum', 'Alkali Metal', 3, 1),
    ElementData(12, 'Mg', 'Magnezyum', 'Toprak Alkali', 3, 2),
    ElementData(13, 'Al', 'Alüminyum', 'Metal', 3, 13),
    ElementData(14, 'Si', 'Silisyum', 'Yarı Metal', 3, 14),
    ElementData(15, 'P', 'Fosfor', 'Ametal', 3, 15),
    ElementData(16, 'S', 'Kükürt', 'Ametal', 3, 16),
    ElementData(17, 'Cl', 'Klor', 'Halojen', 3, 17),
    ElementData(18, 'Ar', 'Argon', 'Soygaz', 3, 18),
    // Period 4
    ElementData(19, 'K', 'Potasyum', 'Alkali Metal', 4, 1),
    ElementData(20, 'Ca', 'Kalsiyum', 'Toprak Alkali', 4, 2),
    ElementData(21, 'Sc', 'Skandiyum', 'Geçiş Metali', 4, 3),
    ElementData(22, 'Ti', 'Titanyum', 'Geçiş Metali', 4, 4),
    ElementData(23, 'V', 'Vanadyum', 'Geçiş Metali', 4, 5),
    ElementData(24, 'Cr', 'Krom', 'Geçiş Metali', 4, 6),
    ElementData(25, 'Mn', 'Mangan', 'Geçiş Metali', 4, 7),
    ElementData(26, 'Fe', 'Demir', 'Geçiş Metali', 4, 8),
    ElementData(27, 'Co', 'Kobalt', 'Geçiş Metali', 4, 9),
    ElementData(28, 'Ni', 'Nikel', 'Geçiş Metali', 4, 10),
    ElementData(29, 'Cu', 'Bakır', 'Geçiş Metali', 4, 11),
    ElementData(30, 'Zn', 'Çinko', 'Geçiş Metali', 4, 12),
    ElementData(31, 'Ga', 'Galyum', 'Metal', 4, 13),
    ElementData(32, 'Ge', 'Germanyum', 'Yarı Metal', 4, 14),
    ElementData(33, 'As', 'Arsenik', 'Yarı Metal', 4, 15),
    ElementData(34, 'Se', 'Selenyum', 'Ametal', 4, 16),
    ElementData(35, 'Br', 'Brom', 'Halojen', 4, 17),
    ElementData(36, 'Kr', 'Kripton', 'Soygaz', 4, 18),
    // Period 5
    ElementData(37, 'Rb', 'Rubidyum', 'Alkali Metal', 5, 1),
    ElementData(38, 'Sr', 'Stronsiyum', 'Toprak Alkali', 5, 2),
    ElementData(39, 'Y', 'İtriyum', 'Geçiş Metali', 5, 3),
    ElementData(40, 'Zr', 'Zirkonyum', 'Geçiş Metali', 5, 4),
    ElementData(41, 'Nb', 'Niyobyum', 'Geçiş Metali', 5, 5),
    ElementData(42, 'Mo', 'Molibden', 'Geçiş Metali', 5, 6),
    ElementData(43, 'Tc', 'Teknetyum', 'Geçiş Metali', 5, 7),
    ElementData(44, 'Ru', 'Rutenyum', 'Geçiş Metali', 5, 8),
    ElementData(45, 'Rh', 'Rodyum', 'Geçiş Metali', 5, 9),
    ElementData(46, 'Pd', 'Paladyum', 'Geçiş Metali', 5, 10),
    ElementData(47, 'Ag', 'Gümüş', 'Geçiş Metali', 5, 11),
    ElementData(48, 'Cd', 'Kadmiyum', 'Geçiş Metali', 5, 12),
    ElementData(49, 'In', 'İndiyum', 'Metal', 5, 13),
    ElementData(50, 'Sn', 'Kalay', 'Metal', 5, 14),
    ElementData(51, 'Sb', 'Antimon', 'Yarı Metal', 5, 15),
    ElementData(52, 'Te', 'Tellür', 'Yarı Metal', 5, 16),
    ElementData(53, 'I', 'İyot', 'Halojen', 5, 17),
    ElementData(54, 'Xe', 'Ksenon', 'Soygaz', 5, 18),
    // Period 6
    ElementData(55, 'Cs', 'Sezyum', 'Alkali Metal', 6, 1),
    ElementData(56, 'Ba', 'Baryum', 'Toprak Alkali', 6, 2),
    ElementData(
      57,
      'La',
      'Lantan',
      'Lantanit',
      6,
      3,
    ), // Placeholder for Lanthanides
    // Lanthanides (57-71) - Visually placed in row 9
    ElementData(57, 'La', 'Lantan', 'Lantanit', 9, 3),
    ElementData(58, 'Ce', 'Seryum', 'Lantanit', 9, 4),
    ElementData(59, 'Pr', 'Praseodim', 'Lantanit', 9, 5),
    ElementData(60, 'Nd', 'Neodim', 'Lantanit', 9, 6),
    ElementData(61, 'Pm', 'Prometyum', 'Lantanit', 9, 7),
    ElementData(62, 'Sm', 'Samaryum', 'Lantanit', 9, 8),
    ElementData(63, 'Eu', 'Evropiyum', 'Lantanit', 9, 9),
    ElementData(64, 'Gd', 'Gadolinyum', 'Lantanit', 9, 10),
    ElementData(65, 'Tb', 'Terbiyum', 'Lantanit', 9, 11),
    ElementData(66, 'Dy', 'Disprosyum', 'Lantanit', 9, 12),
    ElementData(67, 'Ho', 'Holmiyum', 'Lantanit', 9, 13),
    ElementData(68, 'Er', 'Erbiyum', 'Lantanit', 9, 14),
    ElementData(69, 'Tm', 'Tulyum', 'Lantanit', 9, 15),
    ElementData(70, 'Yb', 'İterbiyum', 'Lantanit', 9, 16),
    ElementData(71, 'Lu', 'Lutesyum', 'Lantanit', 9, 17),
    ElementData(72, 'Hf', 'Hafniyum', 'Geçiş Metali', 6, 4),
    ElementData(73, 'Ta', 'Tantal', 'Geçiş Metali', 6, 5),
    ElementData(74, 'W', 'Tungsten', 'Geçiş Metali', 6, 6),
    ElementData(75, 'Re', 'Renyum', 'Geçiş Metali', 6, 7),
    ElementData(76, 'Os', 'Osmiyum', 'Geçiş Metali', 6, 8),
    ElementData(77, 'Ir', 'İridyum', 'Geçiş Metali', 6, 9),
    ElementData(78, 'Pt', 'Platin', 'Geçiş Metali', 6, 10),
    ElementData(79, 'Au', 'Altın', 'Geçiş Metali', 6, 11),
    ElementData(80, 'Hg', 'Cıva', 'Geçiş Metali', 6, 12),
    ElementData(81, 'Tl', 'Talyum', 'Metal', 6, 13),
    ElementData(82, 'Pb', 'Kurşun', 'Metal', 6, 14),
    ElementData(83, 'Bi', 'Bizmut', 'Metal', 6, 15),
    ElementData(84, 'Po', 'Polonyum', 'Yarı Metal', 6, 16),
    ElementData(85, 'At', 'Astatin', 'Halojen', 6, 17),
    ElementData(86, 'Rn', 'Radon', 'Soygaz', 6, 18),
    // Period 7
    ElementData(87, 'Fr', 'Fransiyum', 'Alkali Metal', 7, 1),
    ElementData(88, 'Ra', 'Radyum', 'Toprak Alkali', 7, 2),
    ElementData(
      89,
      'Ac',
      'Aktinyum',
      'Aktinit',
      7,
      3,
    ), // Placeholder for Actinides
    // Actinides (89-103) - Visually placed in row 10
    ElementData(89, 'Ac', 'Aktinyum', 'Aktinit', 10, 3),
    ElementData(90, 'Th', 'Toryum', 'Aktinit', 10, 4),
    ElementData(91, 'Pa', 'Protaktinyum', 'Aktinit', 10, 5),
    ElementData(92, 'U', 'Uranyum', 'Aktinit', 10, 6),
    ElementData(93, 'Np', 'Neptünyum', 'Aktinit', 10, 7),
    ElementData(94, 'Pu', 'Plütonyum', 'Aktinit', 10, 8),
    ElementData(95, 'Am', 'Amerikyum', 'Aktinit', 10, 9),
    ElementData(96, 'Cm', 'Küriyum', 'Aktinit', 10, 10),
    ElementData(97, 'Bk', 'Berkelyum', 'Aktinit', 10, 11),
    ElementData(98, 'Cf', 'Kaliforniyum', 'Aktinit', 10, 12),
    ElementData(99, 'Es', 'Aynştaynyum', 'Aktinit', 10, 13),
    ElementData(100, 'Fm', 'Fermiyum', 'Aktinit', 10, 14),
    ElementData(101, 'Md', 'Mendelevyum', 'Aktinit', 10, 15),
    ElementData(102, 'No', 'Nobelyum', 'Aktinit', 10, 16),
    ElementData(103, 'Lr', 'Lavrensiyum', 'Aktinit', 10, 17),
    ElementData(104, 'Rf', 'Rutherfordiyum', 'Geçiş Metali', 7, 4),
    ElementData(105, 'Db', 'Dubniyum', 'Geçiş Metali', 7, 5),
    ElementData(106, 'Sg', 'Seaborgiyum', 'Geçiş Metali', 7, 6),
    ElementData(107, 'Bh', 'Bohriyum', 'Geçiş Metali', 7, 7),
    ElementData(108, 'Hs', 'Hassiyum', 'Geçiş Metali', 7, 8),
    ElementData(109, 'Mt', 'Meitneriyum', 'Geçiş Metali', 7, 9),
    ElementData(110, 'Ds', 'Darmstadtiyum', 'Geçiş Metali', 7, 10),
    ElementData(111, 'Rg', 'Röntgenyum', 'Geçiş Metali', 7, 11),
    ElementData(112, 'Cn', 'Kopernikyum', 'Geçiş Metali', 7, 12),
    ElementData(113, 'Nh', 'Nihonyum', 'Metal', 7, 13),
    ElementData(114, 'Fl', 'Flerovyum', 'Metal', 7, 14),
    ElementData(115, 'Mc', 'Moskovyum', 'Metal', 7, 15),
    ElementData(116, 'Lv', 'Livermoryum', 'Metal', 7, 16),
    ElementData(117, 'Ts', 'Tennesin', 'Halojen', 7, 17),
    ElementData(118, 'Og', 'Oganesson', 'Soygaz', 7, 18),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar / Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.science_rounded, color: Colors.blueGrey),
                const SizedBox(width: 8),
                const Text(
                  'Periyodik Tablo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                const Text(
                  'Yakınlaştırmak için sürükleyin veya çimdikleyin',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Main Table Area
          Expanded(
            child: InteractiveViewer(
              minScale: 0.1,
              maxScale: 4.0,
              constrained: false, // Allow infinite size for scrolling
              boundaryMargin: const EdgeInsets.all(500),
              child: Container(
                width: 1200,
                height: 800,
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    ..._buildTableCells(),
                    // Row labels
                    Positioned(left: 0, top: 0, child: _buildPeriodLabel(1, 0)),
                    Positioned(
                      left: 0,
                      top: 54,
                      child: _buildPeriodLabel(2, 54),
                    ),
                    Positioned(
                      left: 0,
                      top: 108,
                      child: _buildPeriodLabel(3, 108),
                    ),
                    Positioned(
                      left: 0,
                      top: 162,
                      child: _buildPeriodLabel(4, 162),
                    ),
                    Positioned(
                      left: 0,
                      top: 216,
                      child: _buildPeriodLabel(5, 216),
                    ),
                    Positioned(
                      left: 0,
                      top: 270,
                      child: _buildPeriodLabel(6, 270),
                    ),
                    Positioned(
                      left: 0,
                      top: 324,
                      child: _buildPeriodLabel(7, 324),
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

  Widget _buildPeriodLabel(int period, double top) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        '$period',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  List<Widget> _buildTableCells() {
    // 18 Columns, 7 Rows + 2 bottom rows
    const double cellSize = 54.0;
    const double gap = 4.0;
    const double startX = 30.0;

    return _elements.map((element) {
      final left = startX + (element.col - 1) * (cellSize + gap);
      final top = (element.row - 1) * (cellSize + gap);

      // Add extra gap for Lanthanides/Actinides (Rows 9/10)
      final actualTop = (element.row >= 9) ? top + 20 : top;

      return Positioned(
        left: left,
        top: actualTop,
        width: cellSize,
        height: cellSize,
        child: _buildElementCell(element),
      );
    }).toList();
  }

  Widget _buildElementCell(ElementData element) {
    return Material(
      color: _getElementColor(element.category),
      borderRadius: BorderRadius.circular(4),
      elevation: 2,
      child: InkWell(
        onTap: () => _showElementDetails(element),
        borderRadius: BorderRadius.circular(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${element.number}',
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            ),
            Text(
              element.symbol,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              element.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 7, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  void _showElementDetails(ElementData element) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getElementColor(element.category),
                shape: BoxShape.circle,
              ),
              child: Text(
                element.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(element.name),
                Text(
                  'Atom No: ${element.number}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Kategori', element.category),
            _detailRow(
              'Periyot',
              '${element.row > 7 ? (element.row == 9 ? 6 : 7) : element.row}',
            ),
            _detailRow('Grup', '${element.col}'),
            const SizedBox(height: 10),
            const Text(
              'Detaylı kimyasal özellikler veritabanı bağlandığında burada görünecektir.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Color _getElementColor(String category) {
    switch (category) {
      case 'Ametal':
        return Colors.green.shade100;
      case 'Soygaz':
        return Colors.cyan.shade100;
      case 'Alkali Metal':
        return Colors.red.shade100;
      case 'Toprak Alkali':
        return Colors.orange.shade100;
      case 'Yarı Metal':
        return Colors.teal.shade100;
      case 'Halojen':
        return Colors.yellow.shade100;
      case 'Geçiş Metali':
        return Colors.blue.shade100;
      case 'Metal':
        return Colors.indigo.shade100;
      case 'Lantanit':
        return Colors.pink.shade100;
      case 'Aktinit':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade200;
    }
  }
}

class ElementData {
  final int number;
  final String symbol;
  final String name;
  final String category;
  final int row;
  final int col;

  ElementData(
    this.number,
    this.symbol,
    this.name,
    this.category,
    this.row,
    this.col,
  );
}
