import 'package:flutter/material.dart';
import '../models/motivation.dart';

class PredefinedMotivations {
  static List<Map<String, dynamic>> getMotivations(String languageCode) {
    final motivations = [
      // Manevi
      {'key': 'prayer_5', 'category': MotivationCategory.spiritual, 'icon': Icons.mosque},
      {'key': 'quran_reading', 'category': MotivationCategory.spiritual, 'icon': Icons.menu_book},
      {'key': 'prayer_dua', 'category': MotivationCategory.spiritual, 'icon': Icons.favorite},
      {'key': 'dhikr', 'category': MotivationCategory.spiritual, 'icon': Icons.circle},
      {'key': 'meditation', 'category': MotivationCategory.spiritual, 'icon': Icons.self_improvement},
      {'key': 'istighfar', 'category': MotivationCategory.spiritual, 'icon': Icons.healing},
      {'key': 'charity', 'category': MotivationCategory.spiritual, 'icon': Icons.volunteer_activism},
      
      // Eğitim
      {'key': 'english_study', 'category': MotivationCategory.education, 'icon': Icons.language},
      {'key': 'book_reading', 'category': MotivationCategory.education, 'icon': Icons.book},
      {'key': 'podcast', 'category': MotivationCategory.education, 'icon': Icons.headphones},
      {'key': 'online_course', 'category': MotivationCategory.education, 'icon': Icons.computer},
      {'key': 'writing', 'category': MotivationCategory.education, 'icon': Icons.edit},
      {'key': 'news_reading', 'category': MotivationCategory.education, 'icon': Icons.newspaper},
      {'key': 'documentary', 'category': MotivationCategory.education, 'icon': Icons.movie},
      {'key': 'skill_practice', 'category': MotivationCategory.education, 'icon': Icons.psychology},
      {'key': 'language_practice', 'category': MotivationCategory.education, 'icon': Icons.translate},
      {'key': 'research', 'category': MotivationCategory.education, 'icon': Icons.search},
      
      // Sağlık
      {'key': 'exercise', 'category': MotivationCategory.health, 'icon': Icons.fitness_center},
      {'key': 'teeth_brushing', 'category': MotivationCategory.health, 'icon': Icons.clean_hands},
      {'key': 'walking', 'category': MotivationCategory.health, 'icon': Icons.directions_walk},
      {'key': 'water_drinking', 'category': MotivationCategory.health, 'icon': Icons.local_drink},
      {'key': 'early_sleep', 'category': MotivationCategory.health, 'icon': Icons.bedtime},
      {'key': 'early_wake', 'category': MotivationCategory.health, 'icon': Icons.wb_sunny},
      {'key': 'vitamins', 'category': MotivationCategory.health, 'icon': Icons.medication},
      {'key': 'breathing', 'category': MotivationCategory.health, 'icon': Icons.air},
      {'key': 'stretching', 'category': MotivationCategory.health, 'icon': Icons.accessibility_new},
      {'key': 'healthy_eating', 'category': MotivationCategory.health, 'icon': Icons.restaurant},
      {'key': 'yoga', 'category': MotivationCategory.health, 'icon': Icons.spa},
      {'key': 'running', 'category': MotivationCategory.health, 'icon': Icons.directions_run},
      {'key': 'cycling', 'category': MotivationCategory.health, 'icon': Icons.directions_bike},
      {'key': 'swimming', 'category': MotivationCategory.health, 'icon': Icons.pool},
      
      // Ev İşleri
      {'key': 'daily_cleaning', 'category': MotivationCategory.household, 'icon': Icons.cleaning_services},
      {'key': 'trash_out', 'category': MotivationCategory.household, 'icon': Icons.delete},
      {'key': 'sweep_house', 'category': MotivationCategory.household, 'icon': Icons.home_repair_service},
      {'key': 'wash_dishes', 'category': MotivationCategory.household, 'icon': Icons.kitchen},
      {'key': 'laundry', 'category': MotivationCategory.household, 'icon': Icons.local_laundry_service},
      {'key': 'make_bed', 'category': MotivationCategory.household, 'icon': Icons.bed},
      {'key': 'vacuum_clean', 'category': MotivationCategory.household, 'icon': Icons.cleaning_services},
      {'key': 'bathroom_clean', 'category': MotivationCategory.household, 'icon': Icons.bathroom},
      {'key': 'kitchen_clean', 'category': MotivationCategory.household, 'icon': Icons.countertops},
      {'key': 'organize_closet', 'category': MotivationCategory.household, 'icon': Icons.checkroom},
      {'key': 'iron_clothes', 'category': MotivationCategory.household, 'icon': Icons.iron},
      {'key': 'grocery_shopping', 'category': MotivationCategory.household, 'icon': Icons.shopping_basket},
      
      // Kişisel Bakım
      {'key': 'shower', 'category': MotivationCategory.selfCare, 'icon': Icons.shower},
      {'key': 'skin_care', 'category': MotivationCategory.selfCare, 'icon': Icons.face},
      {'key': 'hair_care', 'category': MotivationCategory.selfCare, 'icon': Icons.content_cut},
      {'key': 'nail_care', 'category': MotivationCategory.selfCare, 'icon': Icons.back_hand},
      {'key': 'moisturize', 'category': MotivationCategory.selfCare, 'icon': Icons.spa},
      {'key': 'sunscreen', 'category': MotivationCategory.selfCare, 'icon': Icons.wb_sunny},
      
      // Sosyal
      {'key': 'family_call', 'category': MotivationCategory.social, 'icon': Icons.family_restroom},
      {'key': 'friends_chat', 'category': MotivationCategory.social, 'icon': Icons.people},
      {'key': 'visit_relatives', 'category': MotivationCategory.social, 'icon': Icons.home},
      {'key': 'help_neighbor', 'category': MotivationCategory.social, 'icon': Icons.handshake},
      {'key': 'community_service', 'category': MotivationCategory.social, 'icon': Icons.volunteer_activism},
      
      // Hobi
      {'key': 'music_listen', 'category': MotivationCategory.hobby, 'icon': Icons.music_note},
      {'key': 'photography', 'category': MotivationCategory.hobby, 'icon': Icons.camera_alt},
      {'key': 'gardening', 'category': MotivationCategory.hobby, 'icon': Icons.grass},
      {'key': 'cooking', 'category': MotivationCategory.hobby, 'icon': Icons.restaurant_menu},
      {'key': 'drawing', 'category': MotivationCategory.hobby, 'icon': Icons.brush},
      {'key': 'crafting', 'category': MotivationCategory.hobby, 'icon': Icons.build},
      {'key': 'gaming', 'category': MotivationCategory.hobby, 'icon': Icons.sports_esports},
      {'key': 'fishing', 'category': MotivationCategory.hobby, 'icon': Icons.phishing},
      
      // İş/Kariyer
      {'key': 'daily_planning', 'category': MotivationCategory.career, 'icon': Icons.schedule},
      {'key': 'email_check', 'category': MotivationCategory.career, 'icon': Icons.email},
      {'key': 'networking', 'category': MotivationCategory.career, 'icon': Icons.connect_without_contact},
      {'key': 'skill_development', 'category': MotivationCategory.career, 'icon': Icons.trending_up},
      {'key': 'project_work', 'category': MotivationCategory.career, 'icon': Icons.work},
      
      // Kişisel Gelişim
      {'key': 'pay_bills', 'category': MotivationCategory.personal, 'icon': Icons.payment},
      {'key': 'organize_room', 'category': MotivationCategory.personal, 'icon': Icons.home},
      {'key': 'tech_break', 'category': MotivationCategory.personal, 'icon': Icons.phone_android},
      {'key': 'gratitude_journal', 'category': MotivationCategory.personal, 'icon': Icons.favorite},
      {'key': 'goal_review', 'category': MotivationCategory.personal, 'icon': Icons.flag},
      {'key': 'car_maintenance', 'category': MotivationCategory.personal, 'icon': Icons.car_repair},
    ];
    
    return motivations.map((m) => {
      'title': _getTitle(m['key'] as String, languageCode),
      'description': _getDescription(m['key'] as String, languageCode),
      'category': m['category'],
      'icon': m['icon'],
    }).toList();
  }
  
  static String _getTitle(String key, String languageCode) {
    const titles = {
      'tr': {
        // Manevi
        'prayer_5': '5 Vakit Namaz',
        'quran_reading': 'Kuran Okuma',
        'prayer_dua': 'Dua Etme',
        'dhikr': 'Tesbih Çekme',
        'meditation': 'Meditasyon',
        'istighfar': 'İstiğfar Çekme',
        'charity': 'Sadaka Verme',
        
        // Eğitim
        'english_study': 'İngilizce Çalışma',
        'book_reading': 'Kitap Okuma',
        'podcast': 'Podcast Dinle',
        'online_course': 'Online Kurs',
        'writing': 'Yazı Yazma',
        'news_reading': 'Haberler Oku',
        'documentary': 'Belgesel İzle',
        'skill_practice': 'Beceri Geliştir',
        'language_practice': 'Dil Pratiği',
        'research': 'Araştırma Yap',
        
        // Sağlık
        'exercise': 'Spor Yapma',
        'teeth_brushing': 'Diş Fırçalama',
        'walking': 'Yürüyüş',
        'water_drinking': 'Su İçme',
        'early_sleep': 'Erken Yatma',
        'early_wake': 'Erken Kalkma',
        'vitamins': 'Vitamin Alma',
        'breathing': 'Nefes Egzersizi',
        'stretching': 'Germe Egzersizi',
        'healthy_eating': 'Sağlıklı Beslenme',
        'yoga': 'Yoga',
        'running': 'Koşu',
        'cycling': 'Bisiklet',
        'swimming': 'Yüzme',
        
        // Ev İşleri
        'daily_cleaning': 'Günlük Temizlik',
        'trash_out': 'Çöp Atma',
        'sweep_house': 'Evi Süpürme',
        'wash_dishes': 'Bulaşık Yıkama',
        'laundry': 'Çamaşır Yıkama',
        'make_bed': 'Yatak Toplama',
        'vacuum_clean': 'Elektrikli Süpürge',
        'bathroom_clean': 'Banyo Temizliği',
        'kitchen_clean': 'Mutfak Temizliği',
        'organize_closet': 'Dolap Düzenleme',
        'iron_clothes': 'Ütü Yapma',
        'grocery_shopping': 'Market Alışverişi',
        
        // Kişisel Bakım
        'shower': 'Duş Alma',
        'skin_care': 'Cilt Bakımı',
        'hair_care': 'Saç Bakımı',
        'nail_care': 'Tırnak Bakımı',
        'moisturize': 'Nemlendirici Sürme',
        'sunscreen': 'Güneş Kremi',
        
        // Sosyal
        'family_call': 'Aile İle Konuşma',
        'friends_chat': 'Arkadaşlarla Sohbet',
        'visit_relatives': 'Akraba Ziyareti',
        'help_neighbor': 'Komşuya Yardım',
        'community_service': 'Toplum Hizmeti',
        
        // Hobi
        'music_listen': 'Müzik Dinleme',
        'photography': 'Fotoğraf Çekme',
        'gardening': 'Bahçe Bakımı',
        'cooking': 'Yemek Pişirme',
        'drawing': 'Resim Çizme',
        'crafting': 'El Sanatları',
        'gaming': 'Oyun Oynama',
        'fishing': 'Balık Tutma',
        
        // İş/Kariyer
        'daily_planning': 'Günlük Planlama',
        'email_check': 'E-posta Kontrolü',
        'networking': 'Ağ Kurma',
        'skill_development': 'Beceri Geliştirme',
        'project_work': 'Proje Çalışması',
        
        // Kişisel Gelişim
        'pay_bills': 'Fatura Ödeme',
        'organize_room': 'Oda Düzenleme',
        'tech_break': 'Teknoloji Molası',
        'gratitude_journal': 'Şükür Günlüğü',
        'goal_review': 'Hedef Gözden Geçirme',
        'car_maintenance': 'Araç Bakımı',
      },
      'en': {
        // Spiritual
        'prayer_5': '5 Daily Prayers',
        'quran_reading': 'Quran Reading',
        'prayer_dua': 'Prayer & Dua',
        'dhikr': 'Dhikr/Tasbih',
        'meditation': 'Meditation',
        'istighfar': 'Istighfar',
        'charity': 'Give Charity',
        
        // Education
        'english_study': 'English Study',
        'book_reading': 'Book Reading',
        'podcast': 'Listen Podcast',
        'online_course': 'Online Course',
        'writing': 'Writing',
        'news_reading': 'Read News',
        'documentary': 'Watch Documentary',
        'skill_practice': 'Skill Practice',
        'language_practice': 'Language Practice',
        'research': 'Research',
        
        // Health
        'exercise': 'Exercise',
        'teeth_brushing': 'Brush Teeth',
        'walking': 'Walking',
        'water_drinking': 'Drink Water',
        'early_sleep': 'Early Sleep',
        'early_wake': 'Early Wake',
        'vitamins': 'Take Vitamins',
        'breathing': 'Breathing Exercise',
        'stretching': 'Stretching',
        'healthy_eating': 'Healthy Eating',
        'yoga': 'Yoga',
        'running': 'Running',
        'cycling': 'Cycling',
        'swimming': 'Swimming',
        
        // Household
        'daily_cleaning': 'Daily Cleaning',
        'trash_out': 'Take Out Trash',
        'sweep_house': 'Sweep House',
        'wash_dishes': 'Wash Dishes',
        'laundry': 'Do Laundry',
        'make_bed': 'Make Bed',
        'vacuum_clean': 'Vacuum Clean',
        'bathroom_clean': 'Clean Bathroom',
        'kitchen_clean': 'Clean Kitchen',
        'organize_closet': 'Organize Closet',
        'iron_clothes': 'Iron Clothes',
        'grocery_shopping': 'Grocery Shopping',
        
        // Self Care
        'shower': 'Take Shower',
        'skin_care': 'Skin Care',
        'hair_care': 'Hair Care',
        'nail_care': 'Nail Care',
        'moisturize': 'Apply Moisturizer',
        'sunscreen': 'Apply Sunscreen',
        
        // Social
        'family_call': 'Call Family',
        'friends_chat': 'Chat with Friends',
        'visit_relatives': 'Visit Relatives',
        'help_neighbor': 'Help Neighbor',
        'community_service': 'Community Service',
        
        // Hobby
        'music_listen': 'Listen Music',
        'photography': 'Photography',
        'gardening': 'Gardening',
        'cooking': 'Cooking',
        'drawing': 'Drawing',
        'crafting': 'Crafting',
        'gaming': 'Gaming',
        'fishing': 'Fishing',
        
        // Career
        'daily_planning': 'Daily Planning',
        'email_check': 'Check Email',
        'networking': 'Networking',
        'skill_development': 'Skill Development',
        'project_work': 'Project Work',
        
        // Personal
        'pay_bills': 'Pay Bills',
        'organize_room': 'Organize Room',
        'tech_break': 'Tech Break',
        'gratitude_journal': 'Gratitude Journal',
        'goal_review': 'Review Goals',
        'car_maintenance': 'Car Maintenance',
      },
    };
    return titles[languageCode]?[key] ?? titles['en']?[key] ?? key;
  }
  
  static Map<MotivationCategory, List<Map<String, dynamic>>> getMotivationsByCategory(String languageCode) {
    final motivations = getMotivations(languageCode);
    final Map<MotivationCategory, List<Map<String, dynamic>>> categorizedMotivations = {};
    
    for (final motivation in motivations) {
      final category = motivation['category'] as MotivationCategory;
      if (!categorizedMotivations.containsKey(category)) {
        categorizedMotivations[category] = [];
      }
      categorizedMotivations[category]!.add(motivation);
    }
    
    return categorizedMotivations;
  }
  
  static String getCategoryName(MotivationCategory category, String languageCode) {
    const categoryNames = {
      'tr': {
        MotivationCategory.spiritual: 'Manevi',
        MotivationCategory.education: 'Eğitim',
        MotivationCategory.health: 'Sağlık',
        MotivationCategory.household: 'Ev İşleri',
        MotivationCategory.selfCare: 'Kişisel Bakım',
        MotivationCategory.social: 'Sosyal',
        MotivationCategory.hobby: 'Hobi',
        MotivationCategory.career: 'İş/Kariyer',
        MotivationCategory.personal: 'Kişisel Gelişim',
      },
      'en': {
        MotivationCategory.spiritual: 'Spiritual',
        MotivationCategory.education: 'Education',
        MotivationCategory.health: 'Health',
        MotivationCategory.household: 'Household',
        MotivationCategory.selfCare: 'Self Care',
        MotivationCategory.social: 'Social',
        MotivationCategory.hobby: 'Hobby',
        MotivationCategory.career: 'Career',
        MotivationCategory.personal: 'Personal',
      },
    };
    
    return categoryNames[languageCode]?[category] ?? categoryNames['en']?[category] ?? category.toString();
  }
  
  static String _getDescription(String key, String languageCode) {
    const descriptions = {
      'tr': {
        // Manevi
        'prayer_5': 'Günde 5 vakit namazımı kılmak',
        'quran_reading': 'Her gün Kuran-ı Kerim okumak',
        'prayer_dua': 'Düzenli dua etme alışkanlığı',
        'dhikr': 'Günlük tesbih çekme',
        'meditation': 'Zihinsel dinginlik için meditasyon',
        'istighfar': 'Günlük istiğfar çekme',
        'charity': 'Düzenli sadaka verme',
        
        // Eğitim
        'english_study': 'Düzenli İngilizce pratiği yapmak',
        'book_reading': 'Her gün kitap okuma alışkanlığı',
        'podcast': 'Eğitici podcast dinleme',
        'online_course': 'Online eğitim alma',
        'writing': 'Günlük yazı yazma',
        'news_reading': 'Güncel haberleri takip etme',
        'documentary': 'Eğitici belgesel izleme',
        'skill_practice': 'Yeni beceri geliştirme',
        'language_practice': 'Yabancı dil pratiği yapma',
        'research': 'Araştırma ve öğrenme',
        
        // Sağlık
        'exercise': 'Düzenli egzersiz yapmak',
        'teeth_brushing': 'Günde 2 kez diş fırçalamak',
        'walking': 'Günlük yürüyüş yapmak',
        'water_drinking': 'Yeterli su içme',
        'early_sleep': 'Erken yatma alışkanlığı',
        'early_wake': 'Erken kalkma rutini',
        'vitamins': 'Günlük vitamin alma',
        'breathing': 'Nefes egzersizi yapma',
        'stretching': 'Germe egzersizleri',
        'healthy_eating': 'Sağlıklı beslenme',
        'yoga': 'Yoga pratiği',
        'running': 'Düzenli koşu yapma',
        'cycling': 'Bisiklet sürme',
        'swimming': 'Yüzme egzersizi',
        
        // Ev İşleri
        'daily_cleaning': 'Günlük ev temizliği',
        'trash_out': 'Çöpleri dışarı çıkarma',
        'sweep_house': 'Evi süpürme',
        'wash_dishes': 'Bulaşık yıkama',
        'laundry': 'Çamaşır yıkama',
        'make_bed': 'Yatağı toplama',
        'vacuum_clean': 'Elektrikli süpürge ile temizlik',
        'bathroom_clean': 'Banyo temizliği yapma',
        'kitchen_clean': 'Mutfak temizliği',
        'organize_closet': 'Dolabı düzenleme',
        'iron_clothes': 'Kıyafetleri ütüleme',
        'grocery_shopping': 'Market alışverişi yapma',
        
        // Kişisel Bakım
        'shower': 'Düzenli duş alma',
        'skin_care': 'Cilt bakımı yapma',
        'hair_care': 'Saç bakımı',
        'nail_care': 'Tırnak bakımı',
        'moisturize': 'Nemlendirici kullanma',
        'sunscreen': 'Güneş kremi sürme',
        
        // Sosyal
        'family_call': 'Aile ile düzenli iletişim',
        'friends_chat': 'Arkadaşlarla sohbet etme',
        'visit_relatives': 'Akraba ziyareti yapma',
        'help_neighbor': 'Komşulara yardım etme',
        'community_service': 'Toplum hizmeti yapma',
        
        // Hobi
        'music_listen': 'Müzik dinleme',
        'photography': 'Fotoğraf çekme',
        'gardening': 'Bahçe bakımı yapma',
        'cooking': 'Yemek pişirme',
        'drawing': 'Resim çizme',
        'crafting': 'El sanatları yapma',
        'gaming': 'Oyun oynama',
        'fishing': 'Balık tutma',
        
        // İş/Kariyer
        'daily_planning': 'Günlük plan yapma',
        'email_check': 'E-postaları kontrol etme',
        'networking': 'Profesyonel ağ kurma',
        'skill_development': 'Mesleki beceri geliştirme',
        'project_work': 'Proje üzerinde çalışma',
        
        // Kişisel Gelişim
        'pay_bills': 'Faturaları ödeme',
        'organize_room': 'Odayı düzenleme',
        'tech_break': 'Teknoloji molası verme',
        'gratitude_journal': 'Şükür günlüğü tutma',
        'goal_review': 'Hedefleri gözden geçirme',
        'car_maintenance': 'Araç bakımı yapma',
      },
      'en': {
        // Spiritual
        'prayer_5': 'Perform 5 daily prayers',
        'quran_reading': 'Read Quran daily',
        'prayer_dua': 'Regular prayer and dua',
        'dhikr': 'Daily dhikr/tasbih',
        'meditation': 'Meditation for mental peace',
        'istighfar': 'Daily istighfar practice',
        'charity': 'Give regular charity',
        
        // Education
        'english_study': 'Regular English practice',
        'book_reading': 'Daily book reading habit',
        'podcast': 'Listen to educational podcasts',
        'online_course': 'Take online courses',
        'writing': 'Daily writing practice',
        'news_reading': 'Follow current news',
        'documentary': 'Watch educational documentaries',
        'skill_practice': 'Develop new skills',
        'language_practice': 'Practice foreign language',
        'research': 'Research and learning',
        
        // Health
        'exercise': 'Regular exercise routine',
        'teeth_brushing': 'Brush teeth twice daily',
        'walking': 'Daily walking routine',
        'water_drinking': 'Drink adequate water',
        'early_sleep': 'Early sleeping habit',
        'early_wake': 'Early wake up routine',
        'vitamins': 'Take daily vitamins',
        'breathing': 'Breathing exercises',
        'stretching': 'Stretching exercises',
        'healthy_eating': 'Healthy eating habits',
        'yoga': 'Yoga practice',
        'running': 'Regular running routine',
        'cycling': 'Cycling exercise',
        'swimming': 'Swimming exercise',
        
        // Household
        'daily_cleaning': 'Daily house cleaning',
        'trash_out': 'Take out trash',
        'sweep_house': 'Sweep the house',
        'wash_dishes': 'Wash dishes',
        'laundry': 'Do laundry',
        'make_bed': 'Make the bed',
        'vacuum_clean': 'Vacuum cleaning',
        'bathroom_clean': 'Clean bathroom',
        'kitchen_clean': 'Clean kitchen',
        'organize_closet': 'Organize closet',
        'iron_clothes': 'Iron clothes',
        'grocery_shopping': 'Grocery shopping',
        
        // Self Care
        'shower': 'Take regular shower',
        'skin_care': 'Skin care routine',
        'hair_care': 'Hair care',
        'nail_care': 'Nail care',
        'moisturize': 'Apply moisturizer',
        'sunscreen': 'Apply sunscreen',
        
        // Social
        'family_call': 'Regular family communication',
        'friends_chat': 'Chat with friends',
        'visit_relatives': 'Visit relatives',
        'help_neighbor': 'Help neighbors',
        'community_service': 'Community service',
        
        // Hobby
        'music_listen': 'Listen to music',
        'photography': 'Photography practice',
        'gardening': 'Gardening activities',
        'cooking': 'Cooking practice',
        'drawing': 'Drawing practice',
        'crafting': 'Crafting activities',
        'gaming': 'Gaming time',
        'fishing': 'Fishing activity',
        
        // Career
        'daily_planning': 'Daily planning',
        'email_check': 'Check emails',
        'networking': 'Professional networking',
        'skill_development': 'Professional skill development',
        'project_work': 'Work on projects',
        
        // Personal
        'pay_bills': 'Pay bills',
        'organize_room': 'Organize room',
        'tech_break': 'Technology break',
        'gratitude_journal': 'Keep gratitude journal',
        'goal_review': 'Review goals',
        'car_maintenance': 'Car maintenance',
      },
    };
    return descriptions[languageCode]?[key] ?? descriptions['en']?[key] ?? key;
  }
  
  static int getTotalMotivationsCount() {
    return getMotivations('tr').length;
  }
}