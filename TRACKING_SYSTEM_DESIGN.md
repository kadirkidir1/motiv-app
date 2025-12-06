# MotivApp - Takip Sistemi Tasarımı

## 📊 Genel Bakış

Bu doküman, MotivApp'te rutin ve task takibi için kapsamlı bir sistem tasarımı içerir.

## 🎯 Takip Edilecek Metrikler

### 1. Rutin Takibi
- **Günlük Tamamlanma**: Her gün için tamamlandı/tamamlanmadı
- **Streak (Seri)**: Kaç gün üst üste yapıldı
- **Toplam Tamamlanma**: Toplam kaç kez yapıldı
- **Yüzde Başarı**: Son 7/30 günde yüzde kaç başarılı
- **Zaman Takibi**: Hedef süre vs gerçek süre (isTimeBased=true ise)
- **Haftalık/Aylık Özet**: Frequency'e göre periyodik başarı

### 2. Task Takibi
- **Tamamlanma Durumu**: Pending/Completed/Expired
- **Deadline Takibi**: Kalan süre, gecikme durumu
- **Tamamlanma Oranı**: Günlük/haftalık task başarı yüzdesi
- **Ortalama Tamamlanma Süresi**: Task'lar ne kadar sürede tamamlanıyor

## 🗄️ Veritabanı Yapısı

### Mevcut Tablolar
```sql
-- routines tablosu (mevcut)
CREATE TABLE routines (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  title TEXT,
  description TEXT,
  category TEXT,
  frequency TEXT, -- daily, weekly, monthly
  has_alarm BOOLEAN,
  alarm_time TIME,
  target_minutes INTEGER,
  is_time_based BOOLEAN,
  created_at TIMESTAMP,
  is_completed BOOLEAN
);

-- daily_tasks tablosu (mevcut)
CREATE TABLE daily_tasks (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  title TEXT,
  description TEXT,
  created_at TIMESTAMP,
  expires_at TIMESTAMP,
  status TEXT, -- pending, completed, expired
  add_to_calendar BOOLEAN,
  has_alarm BOOLEAN,
  alarm_time TIMESTAMP,
  deadline_type TEXT
);
```

### Yeni Tablolar (Eklenecek)

```sql
-- Rutin tamamlanma kayıtları
CREATE TABLE routine_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  routine_id UUID REFERENCES routines(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  completed_at TIMESTAMP NOT NULL,
  minutes_spent INTEGER DEFAULT 0,
  date DATE NOT NULL, -- Sadece tarih için (günlük takip)
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(routine_id, date) -- Bir rutinin günde bir kez tamamlanması
);

-- Rutin istatistikleri (cache için)
CREATE TABLE routine_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  routine_id UUID REFERENCES routines(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_completions INTEGER DEFAULT 0,
  last_completed_date DATE,
  success_rate_7d DECIMAL(5,2), -- Son 7 gün başarı yüzdesi
  success_rate_30d DECIMAL(5,2), -- Son 30 gün başarı yüzdesi
  avg_minutes_spent INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(routine_id)
);

-- Task tamamlanma kayıtları
CREATE TABLE task_completions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES daily_tasks(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  completed_at TIMESTAMP NOT NULL,
  completion_time_minutes INTEGER, -- Task'ı tamamlama süresi
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Günlük özet istatistikleri
CREATE TABLE daily_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  routines_completed INTEGER DEFAULT 0,
  routines_total INTEGER DEFAULT 0,
  tasks_completed INTEGER DEFAULT 0,
  tasks_total INTEGER DEFAULT 0,
  total_minutes_spent INTEGER DEFAULT 0,
  completion_rate DECIMAL(5,2),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, date)
);
```

## 📱 Flutter Model Güncellemeleri

### 1. RoutineCompletion Model
```dart
class RoutineCompletion {
  final String id;
  final String routineId;
  final String userId;
  final DateTime completedAt;
  final int minutesSpent;
  final DateTime date;
  final String? notes;

  RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.userId,
    required this.completedAt,
    this.minutesSpent = 0,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'routine_id': routineId,
    'user_id': userId,
    'completed_at': completedAt.toIso8601String(),
    'minutes_spent': minutesSpent,
    'date': date.toIso8601String().split('T')[0],
    'notes': notes,
  };

  factory RoutineCompletion.fromJson(Map<String, dynamic> json) {
    return RoutineCompletion(
      id: json['id'],
      routineId: json['routine_id'],
      userId: json['user_id'],
      completedAt: DateTime.parse(json['completed_at']),
      minutesSpent: json['minutes_spent'] ?? 0,
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }
}
```

### 2. RoutineStats Model
```dart
class RoutineStats {
  final String id;
  final String routineId;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final DateTime? lastCompletedDate;
  final double successRate7d;
  final double successRate30d;
  final int avgMinutesSpent;

  RoutineStats({
    required this.id,
    required this.routineId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompletions = 0,
    this.lastCompletedDate,
    this.successRate7d = 0.0,
    this.successRate30d = 0.0,
    this.avgMinutesSpent = 0,
  });

  factory RoutineStats.fromJson(Map<String, dynamic> json) {
    return RoutineStats(
      id: json['id'],
      routineId: json['routine_id'],
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      totalCompletions: json['total_completions'] ?? 0,
      lastCompletedDate: json['last_completed_date'] != null 
        ? DateTime.parse(json['last_completed_date']) 
        : null,
      successRate7d: (json['success_rate_7d'] ?? 0.0).toDouble(),
      successRate30d: (json['success_rate_30d'] ?? 0.0).toDouble(),
      avgMinutesSpent: json['avg_minutes_spent'] ?? 0,
    );
  }
}
```

### 3. DailyStats Model
```dart
class DailyStats {
  final String id;
  final String userId;
  final DateTime date;
  final int routinesCompleted;
  final int routinesTotal;
  final int tasksCompleted;
  final int tasksTotal;
  final int totalMinutesSpent;
  final double completionRate;

  DailyStats({
    required this.id,
    required this.userId,
    required this.date,
    this.routinesCompleted = 0,
    this.routinesTotal = 0,
    this.tasksCompleted = 0,
    this.tasksTotal = 0,
    this.totalMinutesSpent = 0,
    this.completionRate = 0.0,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      routinesCompleted: json['routines_completed'] ?? 0,
      routinesTotal: json['routines_total'] ?? 0,
      tasksCompleted: json['tasks_completed'] ?? 0,
      tasksTotal: json['tasks_total'] ?? 0,
      totalMinutesSpent: json['total_minutes_spent'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
    );
  }
}
```

## 🔧 Service Fonksiyonları

### TrackingService (Yeni)
```dart
class TrackingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Rutin tamamla
  Future<void> completeRoutine(String routineId, int minutesSpent, {String? notes}) async {
    final userId = _supabase.auth.currentUser!.id;
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    await _supabase.from('routine_completions').upsert({
      'routine_id': routineId,
      'user_id': userId,
      'completed_at': today.toIso8601String(),
      'minutes_spent': minutesSpent,
      'date': dateOnly.toIso8601String().split('T')[0],
      'notes': notes,
    });

    // İstatistikleri güncelle
    await _updateRoutineStats(routineId);
    await _updateDailyStats(dateOnly);
  }

  // Rutin tamamlanmasını geri al
  Future<void> uncompleteRoutine(String routineId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    await _supabase
      .from('routine_completions')
      .delete()
      .eq('routine_id', routineId)
      .eq('date', dateOnly.toIso8601String().split('T')[0]);

    await _updateRoutineStats(routineId);
    await _updateDailyStats(dateOnly);
  }

  // Rutin istatistiklerini getir
  Future<RoutineStats?> getRoutineStats(String routineId) async {
    final response = await _supabase
      .from('routine_stats')
      .select()
      .eq('routine_id', routineId)
      .maybeSingle();

    if (response == null) return null;
    return RoutineStats.fromJson(response);
  }

  // Streak hesapla
  Future<void> _updateRoutineStats(String routineId) async {
    final userId = _supabase.auth.currentUser!.id;
    
    // Son 30 günün tamamlanma kayıtlarını al
    final completions = await _supabase
      .from('routine_completions')
      .select('date')
      .eq('routine_id', routineId)
      .order('date', ascending: false)
      .limit(30);

    // Streak hesapla
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (var completion in completions) {
      final date = DateTime.parse(completion['date']);
      
      if (lastDate == null) {
        tempStreak = 1;
        lastDate = date;
      } else {
        final diff = lastDate.difference(date).inDays;
        if (diff == 1) {
          tempStreak++;
        } else {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 1;
        }
        lastDate = date;
      }
    }

    if (tempStreak > longestStreak) longestStreak = tempStreak;
    
    // Bugün tamamlandıysa current streak
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (completions.isNotEmpty) {
      final lastCompletedDate = DateTime.parse(completions.first['date']);
      if (lastCompletedDate.isAtSameMomentAs(todayOnly) || 
          todayOnly.difference(lastCompletedDate).inDays == 0) {
        currentStreak = tempStreak;
      }
    }

    // Başarı oranları
    final last7Days = completions.where((c) {
      final date = DateTime.parse(c['date']);
      return today.difference(date).inDays < 7;
    }).length;

    final successRate7d = (last7Days / 7 * 100).clamp(0, 100);
    final successRate30d = (completions.length / 30 * 100).clamp(0, 100);

    // Stats tablosunu güncelle
    await _supabase.from('routine_stats').upsert({
      'routine_id': routineId,
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_completions': completions.length,
      'last_completed_date': completions.isNotEmpty ? completions.first['date'] : null,
      'success_rate_7d': successRate7d,
      'success_rate_30d': successRate30d,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Günlük istatistikleri güncelle
  Future<void> _updateDailyStats(DateTime date) async {
    final userId = _supabase.auth.currentUser!.id;
    final dateStr = date.toIso8601String().split('T')[0];

    // Günün rutinlerini say
    final routinesCompleted = await _supabase
      .from('routine_completions')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('user_id', userId)
      .eq('date', dateStr);

    final routinesTotal = await _supabase
      .from('routines')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('user_id', userId)
      .eq('frequency', 'daily');

    // Günün tasklerini say
    final tasksCompleted = await _supabase
      .from('daily_tasks')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('user_id', userId)
      .eq('status', 'completed')
      .gte('completed_at', dateStr)
      .lt('completed_at', DateTime(date.year, date.month, date.day + 1).toIso8601String());

    final tasksTotal = await _supabase
      .from('daily_tasks')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('user_id', userId)
      .gte('created_at', dateStr)
      .lt('created_at', DateTime(date.year, date.month, date.day + 1).toIso8601String());

    final total = (routinesTotal.count ?? 0) + (tasksTotal.count ?? 0);
    final completed = (routinesCompleted.count ?? 0) + (tasksCompleted.count ?? 0);
    final completionRate = total > 0 ? (completed / total * 100) : 0.0;

    await _supabase.from('daily_stats').upsert({
      'user_id': userId,
      'date': dateStr,
      'routines_completed': routinesCompleted.count ?? 0,
      'routines_total': routinesTotal.count ?? 0,
      'tasks_completed': tasksCompleted.count ?? 0,
      'tasks_total': tasksTotal.count ?? 0,
      'completion_rate': completionRate,
    });
  }

  // Haftalık özet
  Future<Map<String, dynamic>> getWeeklyStats() async {
    final userId = _supabase.auth.currentUser!.id;
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));

    final stats = await _supabase
      .from('daily_stats')
      .select()
      .eq('user_id', userId)
      .gte('date', weekAgo.toIso8601String().split('T')[0])
      .order('date');

    return {
      'daily_stats': stats.map((s) => DailyStats.fromJson(s)).toList(),
      'avg_completion_rate': stats.isEmpty ? 0.0 : 
        stats.map((s) => s['completion_rate'] as double).reduce((a, b) => a + b) / stats.length,
      'total_completions': stats.isEmpty ? 0 :
        stats.map((s) => (s['routines_completed'] as int) + (s['tasks_completed'] as int)).reduce((a, b) => a + b),
    };
  }

  // Aylık özet
  Future<Map<String, dynamic>> getMonthlyStats() async {
    final userId = _supabase.auth.currentUser!.id;
    final today = DateTime.now();
    final monthAgo = today.subtract(const Duration(days: 30));

    final stats = await _supabase
      .from('daily_stats')
      .select()
      .eq('user_id', userId)
      .gte('date', monthAgo.toIso8601String().split('T')[0])
      .order('date');

    return {
      'daily_stats': stats.map((s) => DailyStats.fromJson(s)).toList(),
      'avg_completion_rate': stats.isEmpty ? 0.0 : 
        stats.map((s) => s['completion_rate'] as double).reduce((a, b) => a + b) / stats.length,
      'total_completions': stats.isEmpty ? 0 :
        stats.map((s) => (s['routines_completed'] as int) + (s['tasks_completed'] as int)).reduce((a, b) => a + b),
      'best_day': stats.isEmpty ? null : 
        stats.reduce((a, b) => (a['completion_rate'] > b['completion_rate']) ? a : b),
    };
  }
}
```

## 📊 UI Bileşenleri

### 1. Streak Widget
```dart
class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakWidget({
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStreakItem('🔥 Güncel Seri', currentStreak),
            _buildStreakItem('🏆 En Uzun Seri', longestStreak),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(String label, int value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12)),
        SizedBox(height: 4),
        Text('$value gün', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
```

### 2. Progress Chart Widget (Güncelleme)
```dart
class ProgressChart extends StatelessWidget {
  final List<DailyStats> stats;
  final String period; // 'week' or 'month'

  const ProgressChart({
    required this.stats,
    this.period = 'week',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İlerleme Grafiği', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: stats.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.completionRate,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Completion Rate Widget
```dart
class CompletionRateWidget extends StatelessWidget {
  final double rate7d;
  final double rate30d;

  const CompletionRateWidget({
    required this.rate7d,
    required this.rate30d,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Başarı Oranı', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRateCircle('7 Gün', rate7d, Colors.blue),
                _buildRateCircle('30 Gün', rate30d, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCircle(String label, double rate, Color color) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 50,
          lineWidth: 8,
          percent: rate / 100,
          center: Text('${rate.toStringAsFixed(0)}%', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          progressColor: color,
        ),
        SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
```

## 🎨 Ekran Önerileri

### 1. Dashboard Screen Güncellemesi
- Günlük özet kartı (bugünkü tamamlanma oranı)
- Aktif streak göstergesi
- Haftalık progress chart
- Hızlı eylem butonları

### 2. Routine Detail Screen Güncellemesi
- Rutin başlığı ve açıklama
- Streak widget
- Son 30 günlük takvim görünümü (tamamlanan günler işaretli)
- Başarı oranı widget
- Tamamlanma geçmişi listesi
- Zaman bazlı rutinler için ortalama süre

### 3. Yeni: Statistics Screen
- Genel istatistikler
- Kategori bazlı başarı oranları
- En başarılı rutinler
- Aylık/yıllık karşılaştırma
- Motivasyon mesajları

## 📦 Gerekli Paketler

```yaml
dependencies:
  fl_chart: ^0.68.0  # Grafik çizimi için
  percent_indicator: ^4.2.3  # Yüzde göstergeleri için
  intl: ^0.19.0  # Tarih formatlama
  table_calendar: ^3.1.2  # Takvim görünümü
```

## 🚀 Uygulama Adımları

### Faz 1: Veritabanı Kurulumu
1. Yeni tabloları oluştur
2. RLS politikalarını ayarla
3. Trigger'ları ekle (otomatik istatistik güncelleme için)

### Faz 2: Model ve Service
1. Yeni model sınıflarını ekle
2. TrackingService'i oluştur
3. Mevcut DatabaseService'i güncelle

### Faz 3: UI Güncellemeleri
1. Widget'ları oluştur
2. Mevcut ekranları güncelle
3. Yeni Statistics ekranını ekle

### Faz 4: Test ve Optimizasyon
1. Performans testleri
2. Cache stratejisi
3. Offline desteği

## 💡 Best Practices

1. **Cache Kullanımı**: İstatistikleri cache'le, her seferinde hesaplama
2. **Batch Updates**: Günlük istatistikleri toplu güncelle
3. **Background Sync**: Offline tamamlamaları senkronize et
4. **Optimistic UI**: Kullanıcıya anında geri bildirim ver
5. **Analytics**: Kullanıcı davranışlarını takip et

## 🔒 Güvenlik

- RLS politikaları ile kullanıcı verilerini koru
- Sadece kendi verilerine erişim
- Trigger'lar ile veri tutarlılığı

## 📈 Gelecek Geliştirmeler

- Arkadaşlarla karşılaştırma
- Liderlik tablosu
- Rozet sistemi
- Haftalık/aylık raporlar (PDF export)
- AI destekli öneriler
- Sosyal paylaşım
