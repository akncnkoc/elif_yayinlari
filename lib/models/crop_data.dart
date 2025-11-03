import 'dart:convert';
import 'dart:ui' show Size;

class CropCoordinates {
  final int x1;
  final int y1;
  final int x2;
  final int y2;
  final int width;
  final int height;

  CropCoordinates({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.width,
    required this.height,
  });

  // Convenience getters for top-left corner coordinates
  int get x => x1;
  int get y => y1;

  factory CropCoordinates.fromJson(Map<String, dynamic> json) {
    return CropCoordinates(
      x1: (json['x1'] as num?)?.toInt() ?? 0,
      y1: (json['y1'] as num?)?.toInt() ?? 0,
      x2: (json['x2'] as num?)?.toInt() ?? 0,
      y2: (json['y2'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuestionNumberLocation {
  final int x;
  final int y;
  final int width;
  final int height;

  QuestionNumberLocation({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory QuestionNumberLocation.fromJson(Map<String, dynamic> json) {
    return QuestionNumberLocation(
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuestionNumberDetails {
  final String text;
  final double ocrConfidence;
  final QuestionNumberLocation? location;

  QuestionNumberDetails({
    required this.text,
    required this.ocrConfidence,
    this.location,
  });

  factory QuestionNumberDetails.fromJson(Map<String, dynamic> json) {
    return QuestionNumberDetails(
      text: json['text']?.toString() ?? '',
      ocrConfidence: (json['ocr_confidence'] as num?)?.toDouble() ?? 0.0,
      location: json['location_in_page'] != null
          ? QuestionNumberLocation.fromJson(
              json['location_in_page'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class CropItem {
  final String imageFile;
  final int pageNumber;
  final int? questionNumber;
  final String className;
  final double confidence;
  final CropCoordinates coordinates;
  final QuestionNumberDetails? questionNumberDetails;

  CropItem({
    required this.imageFile,
    required this.pageNumber,
    this.questionNumber,
    required this.className,
    required this.confidence,
    required this.coordinates,
    this.questionNumberDetails,
  });

  factory CropItem.fromJson(Map<String, dynamic> json) {
    return CropItem(
      imageFile: json['image_file']?.toString() ?? '',
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
      questionNumber: (json['question_number'] as num?)?.toInt(),
      className: json['class']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      coordinates: CropCoordinates.fromJson(
        json['coordinates'] as Map<String, dynamic>? ?? {},
      ),
      questionNumberDetails: json['question_number_details'] != null
          ? QuestionNumberDetails.fromJson(
              json['question_number_details'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class CropData {
  final String pdfFile;
  final int totalPages;
  final int totalDetected;
  final List<CropItem> objects;

  CropData({
    required this.pdfFile,
    required this.totalPages,
    required this.totalDetected,
    required this.objects,
  });

  factory CropData.fromJson(Map<String, dynamic> json) {
    return CropData(
      pdfFile: json['pdf_file']?.toString() ?? '',
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
      totalDetected: (json['total_detected'] as num?)?.toInt() ?? 0,
      objects: (json['objects'] as List?)
              ?.map((obj) => CropItem.fromJson(obj as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory CropData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return CropData.fromJson(json);
  }

  /// Belirli bir sayfa numarası için crop'ları getir
  List<CropItem> getCropsForPage(int pageNumber) {
    return objects.where((crop) => crop.pageNumber == pageNumber).toList();
  }

  /// Crop koordinatlarının referans boyutunu hesapla
  /// Her sayfa için ayrı ayrı max değerleri bulur
  Size getReferenceSizeForPage(int pageNumber) {
    final pageCrops = getCropsForPage(pageNumber);
    if (pageCrops.isEmpty) return Size.zero;

    double maxX = 0;
    double maxY = 0;

    for (final crop in pageCrops) {
      if (crop.coordinates.x2 > maxX) maxX = crop.coordinates.x2.toDouble();
      if (crop.coordinates.y2 > maxY) maxY = crop.coordinates.y2.toDouble();
    }

    return Size(maxX, maxY);
  }
}
