class DriveItem {
  final String id;
  final String name;
  final bool isFolder;
  final String? mimeType;
  final int? size;

  DriveItem({
    required this.id,
    required this.name,
    required this.isFolder,
    this.mimeType,
    this.size,
  });

  bool get isBook => !isFolder && name.toLowerCase().endsWith('.book');

  factory DriveItem.fromJson(Map<String, dynamic> json) {
    final mimeType = json['mimeType'] as String?;
    final isFolder = mimeType == 'application/vnd.google-apps.folder';

    return DriveItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isFolder: isFolder,
      mimeType: mimeType,
      size: json['size'] != null ? int.tryParse(json['size'].toString()) : null,
    );
  }
}
