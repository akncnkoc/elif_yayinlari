# TechAtlas

TechAtlas, Windows için Flutter ile geliştirilmiş kapsamlı bir Akıllı Tahta uygulamasıdır. PDF kitap görüntüleme, Google Drive entegrasyonu ve etkileşimli çizim yeteneklerine odaklanarak eğitim kaynaklarına sorunsuz erişim sağlar.

## Özellikler

-   **Akıllı PDF Görüntüleyici**:
    -   Yüksek performanslı PDF oluşturma.
    -   Yakınlaştırma ve kaydırma özellikleri.
    -   "Kırpılmış" soru/bölüm desteği (`.book` formatı kullanarak).
    -   Birden fazla kitabı açmak için sekmeli arayüz.
-   **Google Drive Entegrasyonu**:
    -   Dosya ve klasörleri doğrudan uygulama içinde gezebilme.
    -   Güvenli klasör erişimi için Erişim Kodu sistemi.
    -   Servis Hesabı kimlik doğrulaması (şifreli).
-   **Çizim Araçları**:
    -   Entegre "Çizim Kalemi" modu.
    -   Çizim ve fare etkileşimi arasında geçiş yapabilme.
-   **Yerel Kütüphane**:
    -   İndirilen içerikler için "Kitaplarım" bölümü.
    -   Son açılan dosyalar geçmişi.
-   **Güvenlik**:
    -   Servis hesabı kimlik bilgileri **şifrelenmiştir** (`assets/service_account.enc`) ve çalışma zamanında çözülür.
    -   Düz metin anahtarlar kod tabanından ve derlemelerden hariç tutulmuştur.

## Kurulum ve Geliştirme

### Gereksinimler

-   [Flutter SDK](https://flutter.dev/docs/get-started/install/windows) (Kararlı kanal)
-   Visual Studio (C++ workload ile, Windows geliştirmesi için)
-   Dart SDK

### Bağımlılıklar

Bağımlılıkları yükleyin:

```bash
flutter pub get
```

### Kimlik Bilgileri (Credentials)

Uygulama, Google Cloud Servis Hesabı kimlik bilgilerini gerektirir.
Bunlar `assets/service_account.enc` içinde (şifreli olarak) saklanır.

Kimlik bilgilerini güncellemeniz gerekirse:
1.  Yeni `service_account.json` dosyasını proje kök dizinine yerleştirin.
2.  Şifreleme betiğini çalıştırın:
    ```bash
    flutter pub run tool/encrypt_sa.dart
    ```
3.  Bu işlem `assets/service_account.enc` dosyasını güncelleyecektir.
4.  Düz metin `service_account.json` dosyasını **commit etmeyin** (gitignore'a eklenmiştir).

## Windows için Derleme (Build)

Release sürümü oluşturmak için:

```bash
flutter build windows --release
```

Çıktı `build\windows\x64\runner\Release` dizininde olacaktır.

## GitHub Release İçin Paketleme

Uygulamayı, varlıkları ve başlatıcı betikleri içeren dağıtılabilir bir ZIP dosyası oluşturmak için:

```powershell
.\package_for_github.ps1
```

Bu işlem proje kök dizininde yüklenmeye hazır `techatlas.zip` dosyasını oluşturacaktır.

## Yükleyici (Installer)

Proje, `Installer_Bootstrap.cs` dosyasından derlenen özel bir önyükleyici yükleyici (`TechAtlas_Setup.exe`) içerir.
Yükleyiciyi derlemek için:

```powershell
.\build_installer.ps1
```

## Mimari

-   **Önyüz**: Flutter (Material Design 3)
-   **Durum Yönetimi**: `setState` ve basit yerel durum (karmaşıklık artarsa Provider/Riverpod'a geçiş planlanıyor).
-   **Depolama**:
    -   Ayarlar için `shared_preferences`.
    -   İndirilen kitaplar için yerel dosya sistemi.
    -   Bulut içeriği için Google Drive API.
-   **Windows Entegrasyonu**: Pencere kontrolü, tam ekran ve her zaman üstte (always-on-top) davranışları için `window_manager`.
