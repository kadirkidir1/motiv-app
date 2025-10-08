class LocationService {
  static const Map<String, List<String>> _countries = {
    'Türkiye': [
      'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana', 'Konya', 
      'Şanlıurfa', 'Gaziantep', 'Kocaeli', 'Mersin', 'Diyarbakır', 'Hatay',
      'Manisa', 'Kayseri', 'Samsun', 'Balıkesir', 'Kahramanmaraş', 'Van',
      'Aydın', 'Denizli', 'Sakarya', 'Muğla', 'Eskişehir', 'Tekirdağ',
      'Trabzon', 'Elazığ', 'Malatya', 'Erzurum', 'Sivas'
    ],
    'Almanya': [
      'Berlin', 'Hamburg', 'Münih', 'Köln', 'Frankfurt', 'Stuttgart',
      'Düsseldorf', 'Dortmund', 'Essen', 'Leipzig', 'Bremen', 'Dresden',
      'Hannover', 'Nürnberg', 'Duisburg', 'Bochum', 'Wuppertal'
    ],
    'Fransa': [
      'Paris', 'Marsilya', 'Lyon', 'Toulouse', 'Nice', 'Nantes',
      'Strasbourg', 'Montpellier', 'Bordeaux', 'Lille', 'Rennes'
    ],
    'İngiltere': [
      'London', 'Birmingham', 'Manchester', 'Glasgow', 'Liverpool',
      'Leeds', 'Sheffield', 'Edinburgh', 'Bristol', 'Cardiff'
    ],
    'ABD': [
      'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
      'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'
    ],
    'Kanada': [
      'Toronto', 'Montreal', 'Vancouver', 'Calgary', 'Edmonton',
      'Ottawa', 'Winnipeg', 'Quebec City', 'Hamilton', 'Kitchener'
    ],
    'Avustralya': [
      'Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide',
      'Gold Coast', 'Newcastle', 'Canberra', 'Sunshine Coast'
    ],
    'Hollanda': [
      'Amsterdam', 'Rotterdam', 'The Hague', 'Utrecht', 'Eindhoven',
      'Tilburg', 'Groningen', 'Almere', 'Breda', 'Nijmegen'
    ],
    'Belçika': [
      'Brussels', 'Antwerp', 'Ghent', 'Charleroi', 'Liège',
      'Bruges', 'Namur', 'Leuven', 'Mons', 'Aalst'
    ],
    'İsviçre': [
      'Zurich', 'Geneva', 'Basel', 'Bern', 'Lausanne',
      'Winterthur', 'Lucerne', 'St. Gallen', 'Lugano'
    ],
    'Avusturya': [
      'Vienna', 'Graz', 'Linz', 'Salzburg', 'Innsbruck',
      'Klagenfurt', 'Villach', 'Wels', 'Sankt Pölten'
    ],
    'İtalya': [
      'Rome', 'Milan', 'Naples', 'Turin', 'Palermo',
      'Genoa', 'Bologna', 'Florence', 'Bari', 'Catania'
    ],
    'İspanya': [
      'Madrid', 'Barcelona', 'Valencia', 'Seville', 'Zaragoza',
      'Málaga', 'Murcia', 'Palma', 'Las Palmas', 'Bilbao'
    ],
  };

  static List<String> getCountries() {
    return _countries.keys.toList()..sort();
  }

  static List<String> getCities(String country) {
    return _countries[country] ?? [];
  }

  static bool isValidCountry(String country) {
    return _countries.containsKey(country);
  }

  static bool isValidCity(String country, String city) {
    final cities = _countries[country];
    return cities != null && cities.contains(city);
  }
}