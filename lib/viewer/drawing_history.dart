import 'stroke.dart';

/// Çizim geçmişini yöneten sınıf - Undo/Redo için kullanılır
class DrawingHistory<T> {
  // Her anahtar için ayrı geçmiş tutar (örneğin, sayfa numarası veya resim adı)
  final Map<T, List<List<Stroke>>> _history = {};
  final Map<T, int> _currentIndex = {};

  static const int maxHistorySize = 50; // Maksimum 50 adım geriye gidebilir

  /// Mevcut durumu kaydet
  void saveState(T key, List<Stroke> strokes) {
    // Geçmiş listesini al veya oluştur
    final history = _history[key] ?? [];
    final currentIndex = _currentIndex[key] ?? -1;

    // Eğer ortadaysak (undo yapılmışsa), ileriyi sil
    if (currentIndex < history.length - 1) {
      history.removeRange(currentIndex + 1, history.length);
    }

    // Yeni durumu ekle (deep copy)
    final stateCopy = strokes.map((stroke) {
      if (stroke.type != StrokeType.freehand) {
        return Stroke.shape(
          color: stroke.color,
          width: stroke.width,
          type: stroke.type,
          shapePoints: List.from(stroke.points),
        );
      } else {
        final newStroke = Stroke(
          color: stroke.color,
          width: stroke.width,
          erase: stroke.erase,
          type: stroke.type,
        );
        newStroke.points.addAll(stroke.points);
        return newStroke;
      }
    }).toList();

    history.add(stateCopy);

    // Maksimum boyutu aşarsa en eskiyi sil
    if (history.length > maxHistorySize) {
      history.removeAt(0);
    }

    // İndeksi güncelle
    _history[key] = history;
    _currentIndex[key] = history.length - 1;
  }

  /// Undo yapılabilir mi?
  bool canUndo(T key) {
    final currentIndex = _currentIndex[key] ?? -1;
    return currentIndex > 0;
  }

  /// Redo yapılabilir mi?
  bool canRedo(T key) {
    final history = _history[key];
    if (history == null) return false;

    final currentIndex = _currentIndex[key] ?? -1;
    return currentIndex < history.length - 1;
  }

  /// Undo işlemi - bir önceki duruma dön
  List<Stroke>? undo(T key) {
    if (!canUndo(key)) return null;

    final currentIndex = _currentIndex[key]!;
    _currentIndex[key] = currentIndex - 1;

    final history = _history[key]!;
    final previousState = history[currentIndex - 1];

    // Deep copy döndür
    return previousState.map((stroke) {
      if (stroke.type != StrokeType.freehand) {
        return Stroke.shape(
          color: stroke.color,
          width: stroke.width,
          type: stroke.type,
          shapePoints: List.from(stroke.points),
        );
      } else {
        final newStroke = Stroke(
          color: stroke.color,
          width: stroke.width,
          erase: stroke.erase,
          type: stroke.type,
        );
        newStroke.points.addAll(stroke.points);
        return newStroke;
      }
    }).toList();
  }

  /// Redo işlemi - bir sonraki duruma git
  List<Stroke>? redo(T key) {
    if (!canRedo(key)) return null;

    final currentIndex = _currentIndex[key]!;
    _currentIndex[key] = currentIndex + 1;

    final history = _history[key]!;
    final nextState = history[currentIndex + 1];

    // Deep copy döndür
    return nextState.map((stroke) {
      if (stroke.type != StrokeType.freehand) {
        return Stroke.shape(
          color: stroke.color,
          width: stroke.width,
          type: stroke.type,
          shapePoints: List.from(stroke.points),
        );
      } else {
        final newStroke = Stroke(
          color: stroke.color,
          width: stroke.width,
          erase: stroke.erase,
          type: stroke.type,
        );
        newStroke.points.addAll(stroke.points);
        return newStroke;
      }
    }).toList();
  }

  /// Belirli bir anahtarın geçmişini temizle
  void clear(T key) {
    _history.remove(key);
    _currentIndex.remove(key);
  }

  /// Tüm geçmişi temizle
  void clearAll() {
    _history.clear();
    _currentIndex.clear();
  }

  /// Debug için - mevcut durumu göster
  String getDebugInfo(T key) {
    final history = _history[key];
    final currentIndex = _currentIndex[key];

    if (history == null) {
      return 'Key $key: Geçmiş yok';
    }

    return 'Key $key: ${currentIndex! + 1}/${history.length} adım';
  }
}
