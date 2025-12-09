# Drawing Pen Remote Control

Bluetooth ile bilgisayarınızdaki Drawing Pen uygulamasını kontrol edin.

## Özellikler

- 📱 Touchpad ile mouse kontrolü
- ⌨️ Klavye kısayolları (Temizle, Geri Al, Silgi, Kapat)
- 🔵 Bluetooth RFCOMM bağlantısı
- 🎨 Kolay kullanım

## Kullanım

1. Bilgisayarınızda Drawing Pen uygulamasını başlatın
2. Telefonunuzda bu uygulamayı açın
3. "Cihaz Ara" butonuna basın
4. "Drawing Pen Remote" cihazını seçin
5. Bağlandıktan sonra touchpad ile mouse'u kontrol edin

## Touchpad

- Parmağınızı sürükleyin: Mouse hareketi
- Tek dokunuş: Sol tık

## Kısayollar

- **C**: Canvas'ı temizle
- **Z**: Son çizimi geri al
- **E**: Silgi modunu aç/kapat
- **Q**: Uygulamayı kapat

## Teknik Detaylar

### Bluetooth Protokolü

Telefon JSON formatında komutlar gönderir:

```json
{
  "type": "mousedelta",
  "deltaX": 10.5,
  "deltaY": -5.2
}
```

### Event Türleri

- `mousemove`: Absolute pozisyon (x, y)
- `mousedelta`: Relative hareket (deltaX, deltaY)
- `mousedown`: Mouse button basıldı (button: 0/1/2)
- `mouseup`: Mouse button bırakıldı
- `keydown`: Klavye tuşu basıldı (key: string)
- `keyup`: Klavye tuşu bırakıldı

## Gereksinimler

- Android 6.0+ veya iOS 12.0+
- Bluetooth desteği
- Windows bilgisayar (Drawing Pen uygulaması için)

## Kurulum

```bash
cd remote_control_app
flutter pub get
flutter run
```
