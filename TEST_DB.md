# Database Test Rehberi

## 1. Supabase Bağlantı Testi

### Adım 1: Uygulamayı Çalıştır
```bash
flutter run
```

### Adım 2: Logları İzle
Android Studio veya VS Code'da Debug Console'u aç ve şu logları ara:

#### Motivasyon Eklerken Görmek İstediğin Loglar:
```
📤 Syncing motivation: [başlık] (ID: [id])
📦 Data: {id: xxx, user_id: xxx, title: xxx, ...}
✅ Motivation synced successfully: [response]
```

#### Uygulama Açılışında Görmek İstediğin Loglar:
```
🔄 Starting sync from cloud for user: [user-id]
📥 Fetching motivations from cloud...
📊 Found X motivations in cloud
📦 Motivation data from cloud: {id: xxx, ...}
✅ Synced motivation: [başlık]
🎉 Sync from cloud completed successfully
```

## 2. Hata Durumları

### ❌ Kullanıcı Giriş Yapmamış
```
❌ No user logged in, skipping cloud sync
```
**Çözüm**: Önce giriş yap

### ❌ Supabase Bağlantı Hatası
```
❌ Motivation cloud sync error: [hata detayı]
Stack trace: [stack trace]
```
**Çözüm**: 
1. İnternet bağlantısını kontrol et
2. Supabase URL ve API key'i kontrol et
3. Supabase tablolarının oluşturulduğunu kontrol et

### ❌ RLS Policy Hatası
```
❌ Sync from cloud error: new row violates row-level security policy
```
**Çözüm**: `supabase_setup.sql` dosyasını Supabase SQL Editor'de çalıştır

## 3. Manuel Test Adımları

### Test 1: Yeni Motivasyon Ekle
1. ✅ Uygulamada yeni motivasyon ekle
2. ✅ Loglarda "📤 Syncing motivation" mesajını gör
3. ✅ Loglarda "✅ Motivation synced successfully" mesajını gör
4. ✅ Supabase Dashboard > Table Editor > motivations tablosunda veriyi gör

### Test 2: Uygulama Silme ve Geri Yükleme
1. ✅ Uygulamada 2-3 motivasyon ekle
2. ✅ Supabase'de verilerin olduğunu doğrula
3. ✅ Uygulamayı telefondan sil
4. ✅ Uygulamayı yeniden yükle
5. ✅ Aynı hesapla giriş yap
6. ✅ Loglarda "🔄 Starting sync from cloud" mesajını gör
7. ✅ Loglarda "📊 Found X motivations in cloud" mesajını gör
8. ✅ Loglarda "🎉 Sync from cloud completed successfully" mesajını gör
9. ✅ Ana ekranda motivasyonların geri geldiğini gör

### Test 3: Not Ekleme
1. ✅ Bir motivasyona tıkla
2. ✅ Not ekle (süre ve ruh hali ile)
3. ✅ Loglarda "📤 Syncing note" mesajını gör
4. ✅ Loglarda "✅ Note synced successfully" mesajını gör
5. ✅ Supabase'de daily_notes tablosunda veriyi gör

## 4. Supabase Dashboard Kontrolleri

### Motivations Tablosu Kontrol
1. Supabase Dashboard > Table Editor > motivations
2. Kontrol edilecekler:
   - ✅ `id` kolonu dolu mu?
   - ✅ `user_id` kolonu doğru kullanıcıya ait mi?
   - ✅ `title`, `description` doğru mu?
   - ✅ `category`, `frequency` doğru mu?
   - ✅ `targetMinutes` doğru mu?

### Daily Tasks Tablosu Kontrol
1. Supabase Dashboard > Table Editor > daily_tasks
2. Kontrol edilecekler:
   - ✅ `id` kolonu dolu mu?
   - ✅ `user_id` kolonu doğru kullanıcıya ait mi?
   - ✅ `title`, `description` doğru mu?
   - ✅ `status` doğru mu?

### Daily Notes Tablosu Kontrol
1. Supabase Dashboard > Table Editor > daily_notes
2. Kontrol edilecekler:
   - ✅ `id` kolonu dolu mu?
   - ✅ `user_id` kolonu doğru kullanıcıya ait mi?
   - ✅ `motivationId` doğru mu?
   - ✅ `note`, `mood` doğru mu?
   - ✅ `completed`, `minutesSpent` doğru mu?

## 5. Sık Karşılaşılan Sorunlar

### Sorun: Veriler cloud'a gitmiyor
**Kontrol Et**:
1. ✅ Kullanıcı giriş yapmış mı?
2. ✅ İnternet bağlantısı var mı?
3. ✅ Loglarda hata mesajı var mı?
4. ✅ Supabase API key doğru mu?

### Sorun: Veriler geri gelmiyor
**Kontrol Et**:
1. ✅ Supabase'de veriler var mı?
2. ✅ `user_id` doğru mu?
3. ✅ RLS politikaları aktif mi?
4. ✅ Loglarda "Found X items in cloud" mesajı var mı?

### Sorun: "Row violates RLS policy" hatası
**Çözüm**:
1. `supabase_setup.sql` dosyasını Supabase SQL Editor'de çalıştır
2. RLS politikalarının doğru kurulduğunu kontrol et

## 6. Debug Komutları

### Flutter Loglarını Filtrele
```bash
# Sadece DatabaseService loglarını göster
flutter logs | grep "DatabaseService"

# Sadece hata loglarını göster
flutter logs | grep "❌"

# Sadece başarılı sync loglarını göster
flutter logs | grep "✅"
```

## 7. Başarı Kriterleri

Tüm testler başarılı ise:
- ✅ Motivasyon eklendiğinde cloud'a gidiyor
- ✅ Task eklendiğinde cloud'a gidiyor
- ✅ Not eklendiğinde cloud'a gidiyor
- ✅ Uygulama silinip yüklendiğinde veriler geri geliyor
- ✅ Supabase'de tüm veriler görünüyor
- ✅ Loglarda hata mesajı yok
