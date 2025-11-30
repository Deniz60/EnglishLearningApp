# 📚 English Learning App

Flutter ile geliştirilmiş, oyunlaştırılmış İngilizce kelime öğrenme uygulaması.

## 🚀 Özellikler

- 📖 **3,151 Kelime** - A1, A2, B1, B2 seviyeleri
- 🎮 **Oyunlaştırılmış Öğrenme** - Çoktan seçmeli ve kelime eşleştirme
- ❤️ **Can Sistemi** - 5 can, saatlik yenilenme
- 🏆 **Liderlik Tablosu** - Diğer kullanıcılarla yarış
- 🔊 **Sesli Telaffuz** - Text-to-Speech ile doğru telaffuz
- 🧠 **Akıllı Tekrar** - Spaced Repetition (SM-2 algoritması)
- ⭐ **Favoriler** - Kelime kaydetme ve kategorileme
- 🔍 **Arama** - Anlık kelime arama
- 💎 **Premium Sistem** - Sınırsız can ve özellikler
- 🌙 **Dark/Light Tema** - Göz dostu temalar
- ☁️ **Bulut Senkronizasyon** - Supabase ile veri yedekleme

## 📱 Ekran Görüntüleri

[Ekran görüntüleri eklenecek]

## 🛠️ Teknolojiler

- **Flutter** 3.x
- **Supabase** - Authentication & Database
- **Hive** - Local Storage
- **Provider** - State Management
- **flutter_tts** - Text-to-Speech
- **flutter_animate** - Animasyonlar

## 📦 Kurulum

### Gereksinimler
- Flutter 3.0+
- Dart 3.0+
- Supabase hesabı

### Adımlar

1. **Repoyu klonla:**
```bash
git clone https://github.com/KULLANICI/EnglishLearningApp.git
cd EnglishLearningApp
```

2. **Bağımlılıkları yükle:**
```bash
flutter pub get
```

3. **Environment dosyasını oluştur:**
```bash
cp lib/env/env.example.dart lib/env/env.dart
```

4. **Supabase bilgilerini gir:**
`lib/env/env.dart` dosyasını aç ve kendi Supabase URL ve API Key bilgilerini gir.

5. **Çalıştır:**
```bash
flutter run
```

## 🗄️ Supabase Kurulumu

### Gerekli Tablolar

```sql
-- Kelimeler tablosu
CREATE TABLE words (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  english TEXT NOT NULL,
  turkish TEXT NOT NULL,
  level TEXT NOT NULL,
  category TEXT,
  example_sentence TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Kullanıcı ayarları
CREATE TABLE user_settings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  lesson_progress JSONB DEFAULT '{}',
  lives INT DEFAULT 5,
  total_score INT DEFAULT 0,
  streak INT DEFAULT 0,
  is_premium BOOLEAN DEFAULT FALSE,
  full_name TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Liderlik tablosu
CREATE TABLE leaderboard (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) UNIQUE,
  username TEXT,
  score INT DEFAULT 0,
  words_learned INT DEFAULT 0,
  streak INT DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Favoriler
CREATE TABLE favorites (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  word_id TEXT NOT NULL,
  category TEXT DEFAULT 'Tümü',
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Row Level Security (RLS)

```sql
-- Kullanıcılar sadece kendi verilerine erişebilir
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own data" ON user_settings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD own favorites" ON favorites
  FOR ALL USING (auth.uid() = user_id);
```

## 📂 Proje Yapısı

```
lib/
├── main.dart              # Uygulama giriş noktası
├── env/
│   └── env.dart           # Supabase yapılandırması (gizli)
├── models/                # Veri modelleri
├── providers/             # State management
├── screens/               # Ekranlar
│   └── games/             # Oyun ekranları
├── services/              # API ve servisler
├── utils/                 # Yardımcı fonksiyonlar
└── widgets/               # Yeniden kullanılabilir widget'lar
```

## 🔧 APK Oluşturma

```bash
flutter build apk --release
```

APK dosyası: `build/app/outputs/flutter-apk/app-release.apk`

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

MIT License - Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 👨‍💻 Geliştirici

**Deniz Yürekli**

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!
