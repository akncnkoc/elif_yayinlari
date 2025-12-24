import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class SoruCozucuService {
  final String baseUrl;

  SoruCozucuService({this.baseUrl = 'http://localhost:5000'});

  /// Sunucu sağlık kontrolü
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Tek bir görseli analiz et
  ///
  /// [imageBytes]: PNG/JPG görsel verisi
  /// [returnImage]: true ise cevaplı görseli de döndürür
  Future<AnalysisResult?> analyzeImage(
    Uint8List imageBytes, {
    bool returnImage = false,
  }) async {
    try {
      // Base64 encode
      final base64Image = base64Encode(imageBytes);

      // HTTP request
      final response = await http.post(
        Uri.parse('$baseUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image, 'return_image': returnImage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return AnalysisResult.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Toplu görsel analizi (klasör bazlı)
  Future<BatchAnalysisResult?> batchAnalyze(
    String inputDir,
    String outputDir,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/batch_analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'input_dir': inputDir, 'output_dir': outputDir}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return BatchAnalysisResult.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

/// Soru modeli
class Soru {
  final String soruNo;
  final String metin;
  final String dogruSecenek;
  final String aciklama;

  Soru({
    required this.soruNo,
    required this.metin,
    required this.dogruSecenek,
    required this.aciklama,
  });

  factory Soru.fromJson(Map<String, dynamic> json) {
    return Soru(
      soruNo: json['soru_no'] ?? '',
      metin: json['metin'] ?? '',
      dogruSecenek: json['dogru_secenek'] ?? '?',
      aciklama: json['aciklama'] ?? '',
    );
  }
}

/// Analiz sonucu
class AnalysisResult {
  final bool success;
  final List<Soru> sorular;
  final int soruSayisi;
  final Uint8List? resultImage;
  final String? error;

  AnalysisResult({
    required this.success,
    required this.sorular,
    required this.soruSayisi,
    this.resultImage,
    this.error,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final sorularList =
        (json['sorular'] as List?)?.map((s) => Soru.fromJson(s)).toList() ?? [];

    Uint8List? image;
    if (json['result_image'] != null) {
      image = base64Decode(json['result_image']);
    }

    return AnalysisResult(
      success: json['success'] ?? false,
      sorular: sorularList,
      soruSayisi: json['soru_sayisi'] ?? 0,
      resultImage: image,
      error: json['error'],
    );
  }
}

/// Toplu analiz sonucu
class BatchAnalysisResult {
  final bool success;
  final int toplamDosya;
  final List<BatchFileResult> results;
  final String? error;

  BatchAnalysisResult({
    required this.success,
    required this.toplamDosya,
    required this.results,
    this.error,
  });

  factory BatchAnalysisResult.fromJson(Map<String, dynamic> json) {
    final resultsList =
        (json['results'] as List?)
            ?.map((r) => BatchFileResult.fromJson(r))
            .toList() ??
        [];

    return BatchAnalysisResult(
      success: json['success'] ?? false,
      toplamDosya: json['toplam_dosya'] ?? 0,
      results: resultsList,
      error: json['error'],
    );
  }
}

class BatchFileResult {
  final String dosya;
  final bool success;
  final int? soruSayisi;
  final String? error;

  BatchFileResult({
    required this.dosya,
    required this.success,
    this.soruSayisi,
    this.error,
  });

  factory BatchFileResult.fromJson(Map<String, dynamic> json) {
    return BatchFileResult(
      dosya: json['dosya'] ?? '',
      success: json['success'] ?? false,
      soruSayisi: json['soru_sayisi'],
      error: json['error'],
    );
  }
}
