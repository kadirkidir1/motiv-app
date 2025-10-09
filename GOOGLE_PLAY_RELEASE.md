# Google Play Yayınlama Rehberi

## 1. RevenueCat Kurulumu

### 1.1 RevenueCat Hesabı
1. https://app.revenuecat.com/ adresine git
2. Yeni proje oluştur: "Motiv App"
3. Android platformu ekle

### 1.2 Google Play API Entegrasyonu
1. Google Cloud Console'da servis hesabı oluştur
2. JSON key dosyasını indir
3. RevenueCat'te Google Play API credentials ekle
4. Public API Key'i kopyala

### 1.3 Ürün Tanımlamaları
RevenueCat'te şu ürünü oluştur:
- **Product ID**: `premium_yearly`
  - Type: Subscription
  - Duration: 1 year
  - Entitlement: `premium`

### 1.4 Koda API Key Ekleme
`lib/services/revenue_cat_service.dart` dosyasında:
```dart
static const _apiKey = 'YOUR_REVENUECAT_PUBLIC_API_KEY';
```

## 2. Google Play Console Kurulumu

### 2.1 Uygulama Oluşturma
1. https://play.google.com/console adresine git
2. "Uygulama oluştur" tıkla
3. Uygulama adı: "Motiv App"
4. Varsayılan dil: Türkçe
5. Uygulama türü: Uygulama
6. Ücretsiz/Ücretli: Ücretsiz

### 2.2 Uygulama İçi Ürünler
1. Sol menüden "Monetization" > "Products" > "Subscriptions"
2. Yeni abonelik oluştur:

**Yıllık Premium:**
- Product ID: `premium_yearly`
- Name: Premium Yıllık
- Description: Tüm özelliklere 1 yıl boyunca sınırsız erişim
- Price: ₺100.00/yıl
- Billing period: 1 year
- Free trial: Yok (ilk 1 ay uygulama içinde ücretsiz)

### 2.3 Uygulama Bilgileri
**Kısa açıklama (80 karakter):**
```
Hedeflerinize ulaşın! Rutin takibi, görev yönetimi ve motivasyon.
```

**Tam açıklama:**
```
Motiv App ile hayallerinizi gerçeğe dönüştürün! 🎯

✨ ÖZELLİKLER:
• Rutin Takibi: Günlük alışkanlıklarınızı oluşturun ve takip edin
• Görev Yönetimi: Yapılacaklar listenizi organize edin
• Alarm ve Hatırlatıcılar: Hiçbir şeyi kaçırmayın
• İlerleme Grafikleri: Gelişiminizi görselleştirin
• Günlük Notlar: Düşüncelerinizi kaydedin
• Seri Takibi: Motivasyonunuzu koruyun

🎁 PREMIUM ÖZELLİKLER:
• Sınırsız rutin oluşturma
• Gelişmiş istatistikler
• Özel temalar
• Reklamsız deneyim
• Öncelikli destek

Motiv App, hedeflerinize ulaşmanız için ihtiyacınız olan tüm araçları sunar. Bugün başlayın! 🚀
```

### 2.4 Grafikler
Gerekli görseller:
- **Uygulama simgesi**: 512x512 PNG (şeffaf arka plan)
- **Feature graphic**: 1024x500 PNG
- **Ekran görüntüleri**: En az 2 adet (telefon için)
  - Boyut: 16:9 veya 9:16 oran
  - Minimum: 320px
  - Maximum: 3840px

### 2.5 İçerik Derecelendirmesi
1. "Content rating" bölümüne git
2. Anketi doldur
3. Uygulama kategorisi: Productivity
4. Şiddet/cinsel içerik yok

### 2.6 Hedef Kitle ve İçerik
1. Hedef yaş grubu: 13+
2. Reklam içeriği: Hayır (premium varsa)
3. Veri toplama: Evet (Supabase kullanıyoruz)

### 2.7 Gizlilik Politikası
Bir gizlilik politikası URL'i gerekli. Örnek:
```
https://yourdomain.com/privacy-policy
```

## 3. APK/AAB Oluşturma

### 3.1 Keystore Oluşturma
```bash
keytool -genkey -v -keystore ~/motiv-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias motiv-app
```

Bilgileri kaydet:
- Keystore password: [ŞİFRE]
- Key password: [ŞİFRE]
- Alias: motiv-app

### 3.2 Key Properties Dosyası
`android/key.properties` oluştur:
```properties
storePassword=[KEYSTORE_PASSWORD]
keyPassword=[KEY_PASSWORD]
keyAlias=motiv-app
storeFile=/home/abdulkadir/motiv-app-key.jks
```

### 3.3 Build Configuration
`android/app/build.gradle.kts` zaten yapılandırılmış.

### 3.4 AAB Oluşturma
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Dosya konumu: `build/app/outputs/bundle/release/app-release.aab`

## 4. Test Yayını

### 4.1 İç Test Oluşturma
1. "Testing" > "Internal testing" git
2. "Create new release" tıkla
3. AAB dosyasını yükle
4. Release notes yaz:
```
İlk test sürümü:
- Rutin takibi
- Görev yönetimi
- Premium abonelik sistemi
```

### 4.2 Test Kullanıcıları
1. "Testers" sekmesine git
2. Email listesi oluştur
3. Test kullanıcılarını ekle (en az 20 kişi önerilir)

### 4.3 Test Etme
1. Test kullanıcılarına link gönder
2. En az 14 gün test et
3. Geri bildirimleri topla
4. Hataları düzelt

## 5. Üretim Yayını

### 5.1 Ön Kontroller
- [ ] RevenueCat API key eklendi
- [ ] Tüm grafikler yüklendi
- [ ] Gizlilik politikası eklendi
- [ ] İçerik derecelendirmesi tamamlandı
- [ ] Test süreci tamamlandı
- [ ] Abonelik ürünleri aktif

### 5.2 Üretim Yayını
1. "Production" > "Create new release"
2. AAB dosyasını yükle
3. Release notes yaz
4. Ülkeler seçin (Türkiye + diğerleri)
5. "Review release" tıkla
6. "Start rollout to Production" tıkla

### 5.3 İnceleme Süreci
- Google incelemesi: 1-7 gün
- Onaylandıktan sonra birkaç saat içinde yayında

## 6. Yayın Sonrası

### 6.1 RevenueCat Test
1. Uygulamayı Play Store'dan indir
2. Premium satın alma işlemini test et
3. RevenueCat dashboard'da işlemi kontrol et

### 6.2 İzleme
- RevenueCat dashboard: Abonelik metrikleri
- Google Play Console: İndirme ve kullanıcı metrikleri
- Supabase: Kullanıcı aktivitesi

### 6.3 Güncelleme Süreci
```bash
# Version güncelle: pubspec.yaml
version: 1.0.1+2  # version+buildNumber

# Build
flutter build appbundle --release

# Google Play Console'da yeni release oluştur
```

## 7. Önemli Notlar

### RevenueCat Test Modu
- Sandbox ortamında test yaparken gerçek ödeme yapılmaz
- Test kullanıcıları Google Play Console'da tanımlanmalı

### Abonelik İptali
- Kullanıcılar Google Play Store'dan iptal edebilir
- RevenueCat otomatik olarak webhook ile bilgilendirilir
- Supabase'deki premium_until otomatik güncellenir

### Geri Ödeme
- Google Play'in geri ödeme politikası geçerli
- RevenueCat webhook ile bilgilendirilir

### Fiyatlandırma Stratejisi
- İlk 1 ay: Ücretsiz (kayıt olunca otomatik)
- Yıllık: ₺100.00
- Promosyon kodları oluşturulabilir

## 8. Sorun Giderme

### "API key geçersiz" hatası
- RevenueCat dashboard'da API key'i kontrol et
- Public API key kullandığından emin ol
- Projenin doğru platformda olduğunu kontrol et

### Satın alma tamamlanmıyor
- Google Play Console'da ürün ID'lerini kontrol et
- RevenueCat'te aynı ID'lerin tanımlı olduğunu kontrol et
- Test kullanıcısı olarak eklendiğinden emin ol

### Premium durumu senkronize olmuyor
- RevenueCat webhook'larının aktif olduğunu kontrol et
- Supabase'de profiles tablosunda subscription_type ve premium_until kolonlarını kontrol et
- RevenueCat dashboard'da customer info'yu kontrol et
