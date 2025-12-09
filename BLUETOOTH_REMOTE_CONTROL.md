# Bluetooth Remote Control - Drawing Pen

Drawing Pen uygulamasını telefonunuzdan Bluetooth ile kontrol edin!

## 🎯 Özellikler

### Desktop Uygulaması (Windows)
- ✅ Native Bluetooth RFCOMM Server
- ✅ Platform Channel ile Flutter entegrasyonu
- ✅ Otomatik Bluetooth başlatma
- ✅ Gerçek zamanlı bağlantı durumu göstergesi
- ✅ Mouse ve klavye event'lerini işleme

### Mobil Uygulama (Android/iOS)
- ✅ Bluetooth cihaz tarama
- ✅ Drawing Pen'e otomatik bağlanma
- ✅ Touchpad ile mouse kontrolü
- ✅ Klavye kısayolları
- ✅ Bağlantı durumu göstergesi

## 🚀 Kurulum

### 1. Desktop Uygulaması (Windows)

Desktop uygulaması zaten Bluetooth desteği ile kuruldu. Hiçbir ek işlem gerekmez.

```bash
# Drawing Pen uygulamasını başlat
flutter run -t lib/drawing_pen_main.dart
```

Uygulama başladığında:
- Bluetooth otomatik olarak başlar
- "Drawing Pen Remote" servisi yayına başlar
- Sağ üst köşede Bluetooth durumu görünür (🔵 veya 🟢)

### 2. Mobil Uygulama

#### Android/iOS için build

```bash
cd remote_control_app
flutter pub get

# Android için
flutter build apk

# iOS için
flutter build ios
```

APK dosyası şurada olacak:
```
remote_control_app/build/app/outputs/flutter-apk/app-release.apk
```

## 📱 Kullanım

### Adım 1: Desktop'ta Drawing Pen'i başlat
```bash
flutter run -t lib/drawing_pen_main.dart
```

### Adım 2: Telefonda Remote Control uygulamasını aç

### Adım 3: Bluetooth ile bağlan
1. "Cihaz Ara" butonuna bas
2. "Drawing Pen Remote" veya bilgisayar adını seç
3. Bağlantı kurulacak ve touchpad ekranı açılacak

### Adım 4: Kontrol et!
- **Touchpad**: Parmağını sürükle → Mouse hareketi
- **Tek dokunuş**: Sol tık
- **Kısayollar**:
  - **C**: Canvas'ı temizle
  - **Z**: Geri al
  - **E**: Silgi modu aç/kapat
  - **Q**: Uygulamayı kapat

## 🔧 Teknik Detaylar

### Mimari

```
┌─────────────────┐                    ┌──────────────────┐
│  Mobile App     │                    │  Desktop App     │
│  (Flutter)      │                    │  (Flutter)       │
│                 │                    │                  │
│  ┌───────────┐  │                    │  ┌────────────┐  │
│  │Touchpad   │  │   Bluetooth RFCOMM │  │MethodChannel│ │
│  │Widget     ├──┼────────────────────┼──►Platform     │  │
│  └───────────┘  │    JSON Events     │  │Channel      │  │
│                 │                    │  └──────┬──────┘  │
│  ┌───────────┐  │                    │         │         │
│  │flutter_   │  │                    │  ┌──────▼──────┐  │
│  │blue_plus  │  │                    │  │Native C++   │  │
│  └───────────┘  │                    │  │Bluetooth    │  │
└─────────────────┘                    │  │Server       │  │
                                       │  └─────────────┘  │
                                       └──────────────────┘
```

### Bluetooth Protokolü

#### Service UUID
```
00001101-0000-1000-8000-00805F9B34FB
(Standard Serial Port Profile)
```

#### Message Format (JSON)
```json
{
  "type": "mousedelta",
  "deltaX": 10.5,
  "deltaY": -5.2
}
```

#### Event Türleri

| Type | Parametreler | Açıklama |
|------|-------------|----------|
| `mousemove` | x, y | Absolute mouse pozisyonu |
| `mousedelta` | deltaX, deltaY | Relative mouse hareketi (tavsiye) |
| `mousedown` | button (0/1/2) | Mouse button basıldı |
| `mouseup` | button | Mouse button bırakıldı |
| `keydown` | key (string) | Klavye tuşu basıldı |
| `keyup` | key | Klavye tuşu bırakıldı |
| `scroll` | deltaX, deltaY | Scroll hareketi |

### Native Platform Implementasyonları

#### Windows (C++)
- Dosya: `windows/runner/bluetooth_server_plugin.cpp`
- Winsock2 + Bluetooth API kullanır
- RFCOMM socket server
- SDP service registration
- Multi-threaded client handling

#### Dart Service
- Dosya: `lib/services/bluetooth_server_service.dart`
- MethodChannel bridge
- EventChannel for real-time events
- JSON message parsing

#### Input Handler
- Dosya: `lib/services/bluetooth_input_handler.dart`
- Event routing
- Keyboard shortcuts
- Connection status tracking

## 🐛 Troubleshooting

### Desktop Uygulaması

**Problem**: Bluetooth başlamıyor
```
✓ Windows Bluetooth ayarlarından Bluetooth'un açık olduğundan emin olun
✓ Windows güvenlik duvarı Bluetooth bağlantılarına izin veriyor mu kontrol edin
✓ Uygulamayı yönetici olarak çalıştırmayı deneyin
```

**Problem**: Bağlantı kurulmuyor
```
✓ Telefon ve bilgisayar Bluetooth menzilinde mi? (max 10m)
✓ Bilgisayar "keşfedilebilir" modda mı?
✓ Başka Bluetooth cihazlar bağlantıyı engelliyor olabilir
```

### Mobil Uygulama

**Problem**: Cihaz listesi boş
```
✓ Telefonda Bluetooth açık mı?
✓ Konum izinleri verildi mi? (Android gereksinimi)
✓ Desktop uygulaması çalışıyor mu?
✓ Tekrar "Cihaz Ara" butonuna basın
```

**Problem**: Bağlantı kopuyor
```
✓ Bluetooth sinyal kalitesini kontrol edin
✓ Pil tasarrufu modunu kapatın
✓ Uygulamayı arka planda çalışmaya izin verin
```

## 📝 Geliştirme Notları

### Desktop (Windows)

Plugin dosyaları:
- `windows/runner/bluetooth_server_plugin.h`
- `windows/runner/bluetooth_server_plugin.cpp`
- `windows/runner/flutter_window.cpp` (registration)
- `windows/runner/CMakeLists.txt` (build config)

Dependencies:
- `ws2_32.lib` - Winsock
- `Bthprops.lib` - Bluetooth API

### Dart Services

Core files:
- `lib/services/bluetooth_server_service.dart` - Server service
- `lib/services/bluetooth_input_handler.dart` - Input handler
- `lib/drawing_pen_main.dart` - Integration

### Mobile App

Structure:
```
remote_control_app/
├── lib/
│   └── main.dart              # Full app implementation
├── pubspec.yaml               # Dependencies
└── README.md                  # Documentation
```

## 🔮 Gelecek Geliştirmeler

- [ ] Linux Bluetooth desteği (BlueZ)
- [ ] macOS Bluetooth desteği (IOBluetooth)
- [ ] Dokunmatik çizim (telefonda çiz, desktop'ta görünsün)
- [ ] Sesli komutlar
- [ ] Çoklu telefon bağlantısı
- [ ] Gesture desteği (pinch to zoom, rotate, vb.)
- [ ] Vibration feedback

## 📄 Lisans

Bu proje, elif_yayinlari projesinin bir parçasıdır.

## 🙏 Teşekkürler

- Windows Bluetooth API kullanımı
- Flutter Platform Channels
- flutter_blue_plus paketi

---

**Yazan**: Claude Sonnet 4.5
**Tarih**: 2025-12-09
**Platform**: Windows (primary), Linux & macOS (future)
