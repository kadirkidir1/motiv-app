import 'dart:math';

class MotivationQuote {
  final String quoteTr;
  final String quoteEn;
  final String author;

  MotivationQuote({
    required this.quoteTr,
    required this.quoteEn,
    required this.author,
  });

  String getQuote(String languageCode) {
    return languageCode == 'en' ? quoteEn : quoteTr;
  }
}

class MotivationQuotes {
  static final List<MotivationQuote> _quotes = [
    MotivationQuote(
      quoteTr: "Başarı, küçük çabaların günlük olarak tekrarlanmasıdır. Her gün attığın küçük adımlar, zaman içinde büyük değişiklikler yaratacaktır.",
      quoteEn: "Success is the sum of small efforts repeated day in and day out. Every small step you take daily will create great changes over time.",
      author: "Robert Collier",
    ),
    MotivationQuote(
      quoteTr: "Alışkanlıklarımız kaderimizi şekillendirir. Tekrar ettiğimiz eylemler bizi oluşturur, bu yüzden mükemmellik bir eylem değil, alışkanlıktır.",
      quoteEn: "We are what we repeatedly do. Excellence, then, is not an act, but a habit. Our repeated actions shape our destiny.",
      author: "Aristotle",
    ),
    MotivationQuote(
      quoteTr: "Hayatın %10'u sana olanlardan, %90'ı bunlara verdiğin tepkilerden oluşur. Kontrol edebileceğin şey tepkilerindir.",
      quoteEn: "Life is 10% what happens to you and 90% how you react to it. What you can control is your response.",
      author: "Charles Swindoll",
    ),
    MotivationQuote(
      quoteTr: "Başarı, hazırlık ile fırsatın buluştuğu andır. Şansla karşılaştığında hazır olmak gerekir.",
      quoteEn: "Success is where preparation and opportunity meet. You need to be ready when you encounter luck.",
      author: "Seneca",
    ),
    MotivationQuote(
      quoteTr: "Düşen kalkmayandır, kalkan düşmeyendir. Asil olan düşmemek değil, her düştüğünde ayakta kalabilmektir.",
      quoteEn: "The one who falls and gets up is stronger than the one who never tried. What matters is not falling, but getting up every time you fall.",
      author: "Rumi",
    ),
    MotivationQuote(
      quoteTr: "Sabır, bütün kapıların anahtarıdır. Acı verir ama meyvesi en tatlısıdır. Sabretmek, zaferden daha büyük bir erdemdir.",
      quoteEn: "Patience is the key to all doors. It hurts but its fruit is the sweetest. Being patient is a greater virtue than victory.",
      author: "Ali ibn Abi Talib",
    ),
    MotivationQuote(
      quoteTr: "Büyük işler, büyük planlarla değil, küçük adımlarla başarılır. Her büyük yolculuk tek bir adımla başlar.",
      quoteEn: "Great things are done by a series of small things brought together. Every great journey begins with a single step.",
      author: "Lao Tzu",
    ),
    MotivationQuote(
      quoteTr: "Disiplin, özgürlük ile kölelik arasındaki köprüdür. Disiplinli olmak, istediğin hayatı yaşamanın yoludur.",
      quoteEn: "Discipline is the bridge between goals and accomplishment. Being disciplined is the way to live the life you want.",
      author: "Jocko Willink",
    ),
    MotivationQuote(
      quoteTr: "Motivasyon seni başlatır, alışkanlık seni devam ettirir. Günlük rutinlerin, geleceğini belirler.",
      quoteEn: "Motivation gets you started, habit keeps you going. Your daily routines determine your future.",
      author: "Jim Ryun",
    ),
    MotivationQuote(
      quoteTr: "Küçük değişiklikler, büyük sonuçlar doğurur. Bugün attığın küçük adım, yarın büyük bir fark yaratabilir.",
      quoteEn: "Small changes produce big results. The small step you take today can make a big difference tomorrow.",
      author: "James Clear",
    ),
  ];

  static MotivationQuote getRandomQuote() {
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }

  static MotivationQuote getDailyQuote() {
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final random = Random(seed);
    return _quotes[random.nextInt(_quotes.length)];
  }

  static List<MotivationQuote> getAllQuotes() {
    return List.from(_quotes);
  }

  static MotivationQuote getQuoteByCategory(String category) {
    return getRandomQuote();
  }
}