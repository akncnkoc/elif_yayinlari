class DownloadedBook {
  final String id; // Google Drive ID
  final String name;
  final String localPath;
  final int size;
  final DateTime downloadedAt;

  DownloadedBook({
    required this.id,
    required this.name,
    required this.localPath,
    required this.size,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localPath': localPath,
      'size': size,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedBook.fromJson(Map<String, dynamic> json) {
    return DownloadedBook(
      id: json['id'],
      name: json['name'],
      localPath: json['localPath'],
      size: json['size'],
      downloadedAt: DateTime.parse(json['downloadedAt']),
    );
  }
}
