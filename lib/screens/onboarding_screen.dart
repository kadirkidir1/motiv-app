import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _languageCode = 'tr';

  List<OnboardingPage> get _pages => [
    OnboardingPage(
      icon: Icons.waving_hand,
      title: 'Hoş geldin!',
      titleEn: 'Welcome!',
      titleDe: 'Willkommen!',
      titleFr: 'Bienvenue!',
      titleIt: 'Benvenuto!',
      description: 'Küçük adımlar... büyük değişimleri başlatır.\n\nArtık hedeflerin için rastgele günler değil, planlı bir yolculuk var.\n\nHazırsan, seni en iyi versiyonuna taşıyacak bu yolculuğa başlayalım 💪',
      descriptionEn: 'Small steps... start big changes.\n\nNo more random days for your goals, now you have a planned journey.\n\nIf you\'re ready, let\'s start this journey to your best version 💪',
      descriptionDe: 'Kleine Schritte... starten große Veränderungen.\n\nKeine zufälligen Tage mehr für deine Ziele, jetzt hast du eine geplante Reise.\n\nWenn du bereit bist, lass uns diese Reise zu deiner besten Version beginnen 💪',
      descriptionFr: 'Petits pas... déclenchent de grands changements.\n\nPlus de jours aléatoires pour vos objectifs, vous avez maintenant un voyage planifié.\n\nSi vous êtes prêt, commençons ce voyage vers votre meilleure version 💪',
      descriptionIt: 'Piccoli passi... iniziano grandi cambiamenti.\n\nNiente più giorni casuali per i tuoi obiettivi, ora hai un viaggio pianificato.\n\nSe sei pronto, iniziamo questo viaggio verso la tua versione migliore 💪',
      gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    OnboardingPage(
      icon: Icons.refresh,
      title: 'Rutinlerini Yeniden Tanımla',
      titleEn: 'Redefine Your Routines',
      titleDe: 'Definiere deine Routinen neu',
      titleFr: 'Redéfinissez vos routines',
      titleIt: 'Ridefinisci le tue routine',
      description: 'Başarılı insanlar, motivasyonu değil sistemi korur.\n\nHer sabah aynı saatte kalkmak, her gün 10 dakika okumak...\nKüçük alışkanlıklar birikir, seni sen yapar.\n\nKendi rutinlerini senin için tasarlayalım mı?',
      descriptionEn: 'Successful people protect the system, not motivation.\n\nWaking up at the same time every morning, reading 10 minutes daily...\nSmall habits accumulate, they make you who you are.\n\nShall we design your own routines for you?',
      descriptionDe: 'Erfolgreiche Menschen schützen das System, nicht die Motivation.\n\nJeden Morgen zur gleichen Zeit aufwachen, täglich 10 Minuten lesen...\nKleine Gewohnheiten sammeln sich an, sie machen dich aus.\n\nSollen wir deine eigenen Routinen für dich entwerfen?',
      descriptionFr: 'Les personnes qui réussissent protègent le système, pas la motivation.\n\nSe réveiller à la même heure chaque matin, lire 10 minutes par jour...\nLes petites habitudes s\'accumulent, elles font de vous ce que vous êtes.\n\nDevons-nous concevoir vos propres routines pour vous?',
      descriptionIt: 'Le persone di successo proteggono il sistema, non la motivazione.\n\nSvegliarsi alla stessa ora ogni mattina, leggere 10 minuti al giorno...\nLe piccole abitudini si accumulano, ti rendono quello che sei.\n\nProghettiamo le tue routine per te?',
      gradient: const [Color(0xFFf093fb), Color(0xFFF5576c)],
    ),
    OnboardingPage(
      icon: Icons.notifications_active,
      title: 'Hatırlat, Takip Et, Ödüllendir',
      titleEn: 'Remind, Track, Reward',
      titleDe: 'Erinnern, Verfolgen, Belohnen',
      titleFr: 'Rappeler, Suivre, Récompenser',
      titleIt: 'Ricorda, Traccia, Premia',
      description: 'Hayat meşgul olabilir ama hedeflerini unutmamalısın.\n\nBildirimlerle seni nazikçe dürteceğiz 😉\nTamamladığın her görev seni bir adım daha ileri taşıyacak.\n\nBaşarılarını kutlamayı unutma 🎉',
      descriptionEn: 'Life can be busy but you shouldn\'t forget your goals.\n\nWe\'ll gently nudge you with notifications 😉\nEvery task you complete will take you one step further.\n\nDon\'t forget to celebrate your achievements 🎉',
      descriptionDe: 'Das Leben kann beschäftigt sein, aber du solltest deine Ziele nicht vergessen.\n\nWir werden dich sanft mit Benachrichtigungen anstupsen 😉\nJede Aufgabe, die du erledigst, bringt dich einen Schritt weiter.\n\nVergiss nicht, deine Erfolge zu feiern 🎉',
      descriptionFr: 'La vie peut être occupée mais vous ne devez pas oublier vos objectifs.\n\nNous vous pousserons doucement avec des notifications 😉\nChaque tâche que vous accomplissez vous fera avancer d\'un pas.\n\nN\'oubliez pas de célébrer vos réussites 🎉',
      descriptionIt: 'La vita può essere impegnativa ma non dovresti dimenticare i tuoi obiettivi.\n\nTi daremo una spinta gentile con le notifiche 😉\nOgni compito che completi ti porterà un passo avanti.\n\nNon dimenticare di celebrare i tuoi successi 🎉',
      gradient: const [Color(0xFFa8edea), Color(0xFF43cea2)],
    ),
    OnboardingPage(
      icon: Icons.calendar_today,
      title: 'Zamanı Gör, İlerlemeyi Hisset',
      titleEn: 'See Time, Feel Progress',
      titleDe: 'Sehe Zeit, Fühle Fortschritt',
      titleFr: 'Voir le temps, Ressentir les progrès',
      titleIt: 'Vedi il tempo, Senti il progresso',
      description: 'Takviminde artık sadece tarihler değil, ilerlemen olacak.\n\nGünlük, haftalık ve aylık hedeflerini net şekilde görebileceksin.\n\nÇünkü gelişim, görünür olunca motive eder.',
      descriptionEn: 'Your calendar will now have your progress, not just dates.\n\nYou\'ll be able to see your daily, weekly and monthly goals clearly.\n\nBecause progress motivates when it\'s visible.',
      descriptionDe: 'Dein Kalender wird jetzt deinen Fortschritt haben, nicht nur Daten.\n\nDu wirst deine täglichen, wöchentlichen und monatlichen Ziele klar sehen können.\n\nDenn Fortschritt motiviert, wenn er sichtbar ist.',
      descriptionFr: 'Votre calendrier aura maintenant vos progrès, pas seulement des dates.\n\nVous pourrez voir clairement vos objectifs quotidiens, hebdomadaires et mensuels.\n\nParce que les progrès motivent quand ils sont visibles.',
      descriptionIt: 'Il tuo calendario avrà ora i tuoi progressi, non solo le date.\n\nPotrai vedere chiaramente i tuoi obiettivi giornalieri, settimanali e mensili.\n\nPerché il progresso motiva quando è visibile.',
      gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
    OnboardingPage(
      icon: Icons.rocket_launch,
      title: 'Bugün Başla',
      titleEn: 'Start Today',
      titleDe: 'Beginne heute',
      titleFr: 'Commencez aujourd\'hui',
      titleIt: 'Inizia oggi',
      description: 'Başlamak için mükemmel zamanı bekleme.\nMükemmel zaman şimdi.\n\nBu uygulama senin rehberin, ama gücü veren sensin 💫\n\nKüçük bir adım bile yeter.',
      descriptionEn: 'Don\'t wait for the perfect time to start.\nThe perfect time is now.\n\nThis app is your guide, but you give the power 💫\n\nEven a small step is enough.',
      descriptionDe: 'Warte nicht auf den perfekten Zeitpunkt zum Starten.\nDer perfekte Zeitpunkt ist jetzt.\n\nDiese App ist dein Führer, aber du gibst die Kraft 💫\n\nSelbst ein kleiner Schritt reicht.',
      descriptionFr: 'N\'attendez pas le moment parfait pour commencer.\nLe moment parfait est maintenant.\n\nCette application est votre guide, mais vous donnez le pouvoir 💫\n\nMême un petit pas suffit.',
      descriptionIt: 'Non aspettare il momento perfetto per iniziare.\nIl momento perfetto è adesso.\n\nQuesta app è la tua guida, ma tu dai il potere 💫\n\nAnche un piccolo passo è sufficiente.',
      gradient: const [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          Positioned(
            top: 50,
            right: 20,
            child: PopupMenuButton<String>(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _languageCode == 'tr' ? '🇹🇷' :
                      _languageCode == 'en' ? '🇬🇧' :
                      _languageCode == 'de' ? '🇩🇪' :
                      _languageCode == 'fr' ? '🇫🇷' : '🇮🇹',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _languageCode.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              onSelected: (value) {
                setState(() {
                  _languageCode = value;
                });
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
                PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
                PopupMenuItem(value: 'de', child: Text('🇩🇪 Deutsch')),
                PopupMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                PopupMenuItem(value: 'it', child: Text('🇮🇹 Italiano')),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      _languageCode == 'tr' ? 'Geri' : 
                      _languageCode == 'de' ? 'Zurück' :
                      _languageCode == 'fr' ? 'Retour' :
                      _languageCode == 'it' ? 'Indietro' : 'Back',
                      style: const TextStyle(fontSize: 16, color: Colors.white)
                    ),
                  )
                else
                  const SizedBox(width: 80),
                if (_currentPage < _pages.length - 1)
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      _languageCode == 'tr' ? 'Geç' :
                      _languageCode == 'de' ? 'Überspringen' :
                      _languageCode == 'fr' ? 'Passer' :
                      _languageCode == 'it' ? 'Salta' : 'Skip',
                      style: const TextStyle(fontSize: 16, color: Colors.white)
                    ),
                  )
                else
                  const SizedBox(width: 80),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _currentPage == _pages.length - 1
                  ? ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _languageCode == 'tr' ? 'Başlayalım!' :
                        _languageCode == 'de' ? 'Los geht\'s!' :
                        _languageCode == 'fr' ? 'Commençons!' :
                        _languageCode == 'it' ? 'Iniziamo!' : 'Let\'s Start!',
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _languageCode == 'tr' ? 'İleri' :
                        _languageCode == 'de' ? 'Weiter' :
                        _languageCode == 'fr' ? 'Suivant' :
                        _languageCode == 'it' ? 'Avanti' : 'Next',
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    String title;
    String description;
    
    switch (_languageCode) {
      case 'tr':
        title = page.title;
        description = page.description;
        break;
      case 'de':
        title = page.titleDe;
        description = page.descriptionDe;
        break;
      case 'fr':
        title = page.titleFr;
        description = page.descriptionFr;
        break;
      case 'it':
        title = page.titleIt;
        description = page.descriptionIt;
        break;
      default:
        title = page.titleEn;
        description = page.descriptionEn;
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page.icon,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String titleEn;
  final String titleDe;
  final String titleFr;
  final String titleIt;
  final String description;
  final String descriptionEn;
  final String descriptionDe;
  final String descriptionFr;
  final String descriptionIt;
  final List<Color> gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.titleEn,
    required this.titleDe,
    required this.titleFr,
    required this.titleIt,
    required this.description,
    required this.descriptionEn,
    required this.descriptionDe,
    required this.descriptionFr,
    required this.descriptionIt,
    required this.gradient,
  });
}
