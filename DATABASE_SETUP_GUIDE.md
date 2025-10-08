# Database Setup ve Test Rehberi

## 1. Supabase Tablo Kurulumu

### Adım 1: Supabase Dashboard'a Git
1. https://supabase.com adresine git
2. Projenize giriş yapın (emrambokeqhcizknyudn)
3. Sol menüden "SQL Editor" seçeneğine tıklayın

### Adım 2: SQL Script'i Çalıştır
1. `supabase_setup.sql` dosyasını açın
2. Tüm içeriği kopyalayın
3. Supabase SQL Editor'e yapıştırın
4. "Run" butonuna tıklayın

Bu script şunları yapacak:
- `motivations`, `daily_tasks`, `daily_notes` tablolarını oluşturacak
- Gerekli indexleri ekleyecek
- Row Level Security (RLS) politikalarını ayarlayacak
- Her kullanıcı sadece kendi verilerini görebilecek

## 2. Mevcut Verileri Kontrol Etme

### Supabase Dashboard'dan Kontrol:
1. Sol menüden "Table Editor" seçin
2. `motivations` tablosunu seçin
3. Verileri görüntüleyin
4. Aynı şekilde `daily_tasks` ve `daily_notes` tablolarını kontrol edin

### Uygulama Loglarından Kontrol:
1. Uygulamayı çalıştırın
2. Android Studio veya VS Code'da "Debug Console" açın
3. Şu logları arayın:
   - `[DatabaseDebug]` - Cloud'daki veri sayıları
   - `[DatabaseService]` - Sync işlemleri
   - `[SplashScreen]` - Sync durumu

## 3. Test Senaryoları

### Test 1: Yeni Veri Ekleme ve Cloud Sync
1. Uygulamada yeni bir motivasyon ekleyin
2. Loglarda şunu görmelisiniz: `Syncing motivation to cloud: [başlık]`
3. Ardından: `Motivation synced successfully`
4. Supabase Table Editor'de veriyi kontrol edin

### Test 2: Uygulama Silme ve Geri Yükleme
1. Uygulamada birkaç motivasyon ve task ekleyin
2. Supabase'de verilerin olduğunu doğrulayın
3. Uygulamayı telefondan silin
4. Uygulamayı yeniden yükleyin
5. Giriş yapın (aynı hesapla)
6. Loglarda şunları görmelisiniz:
   - `User is signed in, syncing from cloud...`
   - `Found X motivations in cloud`
   - `Found Y tasks in cloud`
   - `Sync completed successfully`
7. Ana ekranda verilerinizin geri geldiğini görmelisiniz

### Test 3: Çoklu Cihaz Sync
1. Cihaz A'da veri ekleyin
2. Cihaz B'de aynı hesapla giriş yapın
3. Cihaz B'de verilerin geldiğini görün

## 4. Sorun Giderme

### Sorun: "Cloud sync error" görüyorum
**Çözüm:**
1. Supabase tablolarının doğru oluşturulduğunu kontrol edin
2. RLS politikalarının aktif olduğunu kontrol edin
3. Kullanıcının giriş yapmış olduğunu doğrulayın

### Sorun: Veriler cloud'a gitmiyor
**Çözüm:**
1. İnternet bağlantısını kontrol edin
2. Loglarda detaylı hata mesajını bulun
3. Supabase API key'in doğru olduğunu kontrol edin

### Sorun: Veriler geri gelmiyor
**Çözüm:**
1. Supabase Table Editor'de verilerin olduğunu doğrulayın
2. `user_id` kolonunun doğru kullanıcıya ait olduğunu kontrol edin
3. Loglarda `Found X items in cloud` mesajını arayın

## 5. Log Mesajları Rehberi

### Başarılı Sync Logları:
```
[DatabaseDebug] Current User: [user-id]
[DatabaseDebug] Motivations count: 3
[DatabaseService] Starting sync from cloud for user: [user-id]
[DatabaseService] Found 3 motivations in cloud
[DatabaseService] Synced motivation: Kuran Okuma
[DatabaseService] Sync from cloud completed successfully
[SplashScreen] Sync completed successfully
```

### Hata Durumu Logları:
```
[DatabaseService] Motivation cloud sync error: [hata detayı]
[DatabaseService] Sync from cloud error: [hata detayı]
```

## 6. Veritabanı Yapısı

### motivations tablosu:
- `id` (TEXT, PRIMARY KEY) - Uygulama tarafından oluşturulan UUID
- `user_id` (UUID) - Supabase auth user ID
- `title`, `description`, `category`, `frequency`
- `hasAlarm`, `alarmTime`, `targetMinutes`
- `createdAt`, `isCompleted`

### daily_tasks tablosu:
- `id` (TEXT, PRIMARY KEY)
- `user_id` (UUID)
- `title`, `description`
- `createdAt`, `expiresAt`
- `status`, `addToCalendar`

### daily_notes tablosu:
- `id` (TEXT, PRIMARY KEY)
- `user_id` (UUID)
- `motivationId` (TEXT)
- `date`, `note`, `mood`, `tags`
- `completed`, `minutesSpent`

## 7. Önemli Notlar

1. **Otomatik Sync**: Her CRUD işleminde (insert, update, delete) otomatik olarak cloud'a sync yapılır
2. **Uygulama Başlangıcı**: Kullanıcı giriş yapmışsa, uygulama başlarken cloud'dan veri çekilir
3. **Offline Çalışma**: İnternet yoksa veriler local SQLite'da saklanır, internet gelince sync olur
4. **Veri Güvenliği**: RLS politikaları sayesinde her kullanıcı sadece kendi verilerini görebilir
