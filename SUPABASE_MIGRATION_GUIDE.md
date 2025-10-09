# Supabase Migration Guide

## Değişiklikler

### 1. Tablo İsimleri
- `motivations` → `routines`

### 2. Kolon İsimleri
- `daily_notes.motivationId` → `daily_notes.routineId`

### 3. Yeni Kolonlar (daily_tasks)
- `hasAlarm` (INTEGER)
- `alarmTime` (TEXT)
- `deadlineType` (TEXT)

## Mevcut Veritabanını Güncelleme

Eğer **mevcut bir Supabase veritabanın varsa**, aşağıdaki adımları takip et:

1. Supabase Dashboard'a git
2. SQL Editor'ü aç
3. `supabase_migration.sql` dosyasının içeriğini kopyala ve çalıştır

Bu işlem:
- Mevcut `motivations` tablosunu `routines` olarak yeniden adlandırır
- Mevcut verileri korur
- Yeni kolonları ekler

## Yeni Kurulum

Eğer **yeni bir Supabase projesi kuruyorsan**:

1. Supabase Dashboard'a git
2. SQL Editor'ü aç
3. `supabase_setup.sql` dosyasının içeriğini kopyala ve çalıştır

Bu işlem tüm tabloları, indexleri ve RLS policy'lerini oluşturur.

## Önemli Notlar

⚠️ Migration işleminden önce **mutlaka yedek al**!

✅ Migration sonrası uygulamayı test et ve sync işleminin düzgün çalıştığından emin ol.
