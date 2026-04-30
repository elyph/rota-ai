import '../models/popular_place.dart';

class PopularPlacesService {
  /// Türkiye'nin popüler turistik yerlerini döndürür
  /// Gerçek uygulamada backend API'den çekilecek
  static List<PopularPlace> getPopularPlaces() {
    return [
      const PopularPlace(
        name: 'Ayasofya-i Kebir Camii',
        city: 'İstanbul',
        description: 'Bizans İmparatoru I. Justinianus tarafından yaptırılan, dünyanın en eski ve en görkemli yapılarından biri.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Hagia_Sophia_%2846785994115%29.jpg/800px-Hagia_Sophia_%2846785994115%29.jpg',
        rating: 4.8,
        latitude: 41.0086,
        longitude: 28.9802,
        category: 'Tarihi Yapı',
      ),
      const PopularPlace(
        name: 'Peri Bacaları',
        city: 'Nevşehir',
        description: 'Kapadokya\'nın eşsiz doğal oluşumları, sıcak hava balonlarıyla ünlü büyülü bir coğrafya.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/G%C3%B6reme_Balloons_%282%29.jpg/800px-G%C3%B6reme_Balloons_%282%29.jpg',
        rating: 4.9,
        latitude: 38.6437,
        longitude: 34.8285,
        category: 'Doğal Güzellik',
      ),
      const PopularPlace(
        name: 'Efes Antik Kenti',
        city: 'İzmir',
        description: 'Antik Yunan ve Roma dönemlerinin en önemli şehirlerinden biri, Celsus Kütüphanesi ile ünlü.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Library_of_Celsus_in_Ephesus.jpg/800px-Library_of_Celsus_in_Ephesus.jpg',
        rating: 4.8,
        latitude: 37.9397,
        longitude: 27.3408,
        category: 'Antik Kent',
      ),
      const PopularPlace(
        name: 'Pamukkale Travertenleri',
        city: 'Denizli',
        description: 'Beyaz traverten terasları ve antik Hierapolis kentiyle eşsiz bir doğa harikası.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Pamukkale_30.jpg/800px-Pamukkale_30.jpg',
        rating: 4.7,
        latitude: 37.9236,
        longitude: 29.1197,
        category: 'Doğal Güzellik',
      ),
      const PopularPlace(
        name: 'Sultanahmet Camii (Mavi Camii)',
        city: 'İstanbul',
        description: 'Altı minaresi ve muhteşem çinileriyle İstanbul\'un sembol yapılarından biri.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Sultan_Ahmed_Camii_%28Blue_Mosque%29.jpg/800px-Sultan_Ahmed_Camii_%28Blue_Mosque%29.jpg',
        rating: 4.7,
        latitude: 41.0054,
        longitude: 28.9768,
        category: 'Tarihi Yapı',
      ),
      const PopularPlace(
        name: 'Sumela Manastırı',
        city: 'Trabzon',
        description: 'Karadeniz\'in yeşil doğasında, kayalara oyulmuş tarihi bir manastır.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Sumela_Monastery_view.jpg/800px-Sumela_Monastery_view.jpg',
        rating: 4.6,
        latitude: 40.8300,
        longitude: 39.6650,
        category: 'Tarihi Yapı',
      ),
      const PopularPlace(
        name: 'Kaleiçi',
        city: 'Antalya',
        description: 'Dar sokakları, tarihi evleri ve limanıyla Antalya\'nın büyüleyici tarihi merkezi.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2b/Kaleici_Antalya.jpg/800px-Kaleici_Antalya.jpg',
        rating: 4.7,
        latitude: 36.8874,
        longitude: 30.7056,
        category: 'Tarihi Merkez',
      ),
      const PopularPlace(
        name: 'Nemrut Dağı',
        city: 'Adıyaman',
        description: 'Kommagene Krallığı\'na ait dev heykelleriyle ünlü, gün doğumu ve batımı eşsiz bir tepe.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Nemrut_Da%C4%9F%C4%B1_heykelleri.jpg/800px-Nemrut_Da%C4%9F%C4%B1_heykelleri.jpg',
        rating: 4.6,
        latitude: 37.9809,
        longitude: 38.7408,
        category: 'Antik Kent',
      ),
    ];
  }
}
