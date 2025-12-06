# MotivApp - Takip Sistemi Sorun Analizi

## 🔍 Tespit Edilen Sorunlar

### 1. **Tamamlanma Takibi Eksikliği**
**Sorun**: 
- `routines` tablosunda sadece `isCompleted` boolean var
- Bu sadece "şu an tamamlandı mı" bilgisini tutuyor
- Geçmiş tamamlanma kayıtları yok
- Hangi gün tamamlandı bilgisi yok

**Sonuç**:
- Streak hesaplanamıyor
- Geçmiş performans görülemiyor
- Yüzde başarı hesaplanamıyor

### 2. **daily_notes Tablosu Yanlış Kullanılıyor**
**Mevcut Durum**:
```sql
CREATE TABLE daily_notes (
  id TEXT PRIMARY KEY,
  routineId TEXT NOT NULL,
  date TEXT NOT NULL,
  note TEXT NOT NULL,
  mood INTEGER NOT NULL,
  tags TEXT,
  completed INTEGER NOT NULL DEFAULT 0,  -- ❌ Bu aslında tamamlanma kaydı
  minutesSpent INTEGER NOT NULL DEFAULT 0
);
```

**Sorun**:
- `daily_notes` hem not hem de tamamlanma kaydı olarak kullanılıyor
- Not yazmak zorunlu değil ama tamamlanma kaydı tutulmalı
- Karışık bir yapı

### 3. **Veritabanı Senkronizasyon Sorunları**
**Kod İncelemesi**:
```dart
// database_service.dart içinde
static Future<void> insertDailyNote(DailyNote note, bool completed, int minutesSpent) async {
  final db = await database;
  await db.insert('daily_notes', _noteToMap(note, completed, minutesSpent));
  _syncNoteToCloud(note, completed, minutesSpent);
}
```

**Sorunlar**:
- `completed` ve `minutesSpent` parametreleri DailyNote modeline ait değil
- Her not ekleme işleminde tamamlanma durumu da ekleniyor
- Tamamlanma kaydı ile not ayrı tutulmalı

### 4. **Task Tamamlanma Takibi Yok**
**Mevcut Durum**:
```dart
class DailyTask {
  final TaskStatus status; // pending, completed, expired
  // ...
}
```

**Sorun**:
- Task'ın ne zaman tamamlandığı kaydedilmiyor
- Tamamlanma süresi tutulmuyor
- Geçmiş task performansı görülemiyor

### 5. **İstatistik Hesaplama Yok**
**Sorun**:
- Her seferinde tüm kayıtlar üzerinden hesaplama yapılıyor
- Cache mekanizması yok
- Performans sorunu olabilir

## 🎯 Çözüm Önerileri

### Çözüm 1: Tamamlanma Kayıtları Tablosu Ekle

```sql
-- Rutin tamamlanma kayıtları
CREATE TABLE routine_completions (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id TEXT REFERENCES routines(id) ON DELETE CASCADE,
  date DATE NOT NULL,  -- Sadece tarih (2024-12-05)
  completed_at TIMESTAMP NOT NULL,  -- Tam tarih-saat
  minutes_spent INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(routine_id, date)  -- Günde bir kez
);

-- Task tamamlanma kayıtları
CREATE TABLE task_completions (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  task_id TEXT REFERENCES daily_tasks(id) ON DELETE CASCADE,
  completed_at TIMESTAMP NOT NULL,
  completion_time_minutes INTEGER,  -- Tamamlama süresi
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Çözüm 2: daily_notes Tablosunu Düzelt

```sql
-- daily_notes sadece not için kullanılmalı
ALTER TABLE daily_notes DROP COLUMN completed;
ALTER TABLE daily_notes DROP COLUMN minutesSpent;

-- Veya yeni tablo oluştur
CREATE TABLE routine_notes (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id TEXT REFERENCES routines(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  note TEXT NOT NULL,
  mood INTEGER,
  tags TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Çözüm 3: Model Güncellemeleri

```dart
// Yeni model: RoutineCompletion
class RoutineCompletion {
  final String id;
  final String routineId;
  final DateTime date;  // Sadece tarih
  final DateTime completedAt;  // Tam tarih-saat
  final int minutesSpent;

  RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.date,
    required this.completedAt,
    this.minutesSpent = 0,
  });
}

// DailyNote'u düzelt
class DailyNote {
  final String id;
  final String routineId;
  final DateTime date;
  final String note;
  final int mood;
  final List<String> tags;
  // completed ve minutesSpent kaldırıldı

  DailyNote({
    required this.id,
    required this.routineId,
    required this.date,
    required this.note,
    this.mood = 3,
    this.tags = const [],
  });
}
```

### Çözüm 4: Service Fonksiyonları

```dart
class TrackingService {
  // Rutin tamamla
  static Future<void> completeRoutine(
    String routineId, 
    {int minutesSpent = 0}
  ) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    
    final completion = RoutineCompletion(
      id: uuid.v4(),
      routineId: routineId,
      date: dateOnly,
      completedAt: today,
      minutesSpent: minutesSpent,
    );
    
    // Local'e kaydet
    await _insertCompletion(completion);
    
    // Cloud'a senkronize et
    await _syncCompletionToCloud(completion);
  }
  
  // Rutin tamamlanmasını geri al
  static Future<void> uncompleteRoutine(
    String routineId, 
    DateTime date
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Local'den sil
    await _deleteCompletion(routineId, dateOnly);
    
    // Cloud'dan sil
    await _deleteCompletionFromCloud(routineId, dateOnly);
  }
  
  // Bugün tamamlandı mı?
  static Future<bool> isCompletedToday(String routineId) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    
    final db = await database;
    final result = await db.query(
      'routine_completions',
      where: 'routine_id = ? AND date = ?',
      whereArgs: [routineId, dateOnly.toIso8601String().split('T')[0]],
    );
    
    return result.isNotEmpty;
  }
  
  // Streak hesapla
  static Future<int> calculateStreak(String routineId) async {
    final db = await database;
    final completions = await db.query(
      'routine_completions',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'date DESC',
      limit: 365,
    );
    
    if (completions.isEmpty) return 0;
    
    int streak = 0;
    DateTime? lastDate;
    
    for (var completion in completions) {
      final date = DateTime.parse(completion['date'] as String);
      
      if (lastDate == null) {
        // İlk kayıt
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        
        // Bugün veya dün tamamlanmışsa streak başlar
        final diff = todayOnly.difference(date).inDays;
        if (diff <= 1) {
          streak = 1;
          lastDate = date;
        } else {
          break; // Streak yok
        }
      } else {
        // Ardışık mı kontrol et
        final diff = lastDate.difference(date).inDays;
        if (diff == 1) {
          streak++;
          lastDate = date;
        } else {
          break; // Streak kırıldı
        }
      }
    }
    
    return streak;
  }
  
  // Başarı oranı hesapla
  static Future<double> calculateSuccessRate(
    String routineId, 
    int days
  ) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    final completions = await db.query(
      'routine_completions',
      where: 'routine_id = ? AND date >= ?',
      whereArgs: [
        routineId, 
        startDate.toIso8601String().split('T')[0]
      ],
    );
    
    return (completions.length / days * 100).clamp(0, 100);
  }
}
```

## 📋 Uygulama Planı

### Adım 1: Veritabanı Güncellemesi
1. `routine_completions` tablosu ekle
2. `task_completions` tablosu ekle
3. `daily_notes` tablosunu düzelt veya yeni `routine_notes` oluştur
4. RLS politikalarını ekle

### Adım 2: Model Güncellemesi
1. `RoutineCompletion` model ekle
2. `TaskCompletion` model ekle
3. `DailyNote` modelini düzelt

### Adım 3: Service Güncellemesi
1. `TrackingService` oluştur
2. `DatabaseService`'i güncelle
3. Senkronizasyon fonksiyonlarını düzelt

### Adım 4: UI Güncellemesi
1. Tamamlama butonlarını güncelle
2. Streak göstergesi ekle
3. İstatistik ekranları ekle

## 🚨 Kritik Noktalar

1. **Veri Kaybı Riski**: Mevcut `daily_notes` tablosundaki `completed` verileri migrate edilmeli
2. **Geriye Dönük Uyumluluk**: Eski kullanıcıların verileri korunmalı
3. **Senkronizasyon**: Local ve cloud verileri tutarlı olmalı

## 📝 Migration Script

```sql
-- Mevcut daily_notes'taki tamamlanma kayıtlarını routine_completions'a taşı
INSERT INTO routine_completions (id, user_id, routine_id, date, completed_at, minutes_spent)
SELECT 
  id,
  user_id,
  routine_id,
  date::DATE,
  date::TIMESTAMP,
  minutes_spent
FROM daily_notes
WHERE completed = 1;

-- daily_notes'tan completed ve minutesSpent kolonlarını kaldır
ALTER TABLE daily_notes DROP COLUMN completed;
ALTER TABLE daily_notes DROP COLUMN minutes_spent;
```

## ✅ Beklenen Sonuçlar

1. ✅ Günlük tamamlanma takibi çalışacak
2. ✅ Streak doğru hesaplanacak
3. ✅ Başarı yüzdeleri görülebilecek
4. ✅ Geçmiş performans analiz edilebilecek
5. ✅ Not tutma ve tamamlanma ayrı olacak
