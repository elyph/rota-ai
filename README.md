# Rota AI — Akıllı Seyahat Asistanı

Rota AI, yapay zeka destekli bir seyahat planlama uygulamasıdır. Kullanıcı bir şehir ve tarih aralığı girer; uygulama uçuş, otel ve gezilecek yerleri birleştirerek kişiselleştirilmiş bir seyahat planı oluşturur. Doğal dille sohbet ederek plana müdahale etmek de mümkündür.

---

## Ne Yapıyor?

- Nereden nereye, hangi tarihler arası gittiğini söylüyorsun
- Uygun uçuşları ve otelleri gerçek zamanlı olarak çekiyor
- Gemini AI ile günlük detaylı bir gezi planı oluşturuyor
- "Bütçemi 5000 TL'ye düşür" veya "müze ekle" gibi komutları anlıyor
- Yakın çevredeki popüler yerleri harita üzerinde gösteriyor

---

## Teknolojiler

| Katman | Teknoloji |
|--------|-----------|
| Frontend | Flutter (Web + Mobil) |
| Backend | Python / FastAPI |
| Yapay Zeka | Google Gemini (Vertex AI) |
| Uçuş Arama | SerpAPI — Google Flights |
| Otel Arama | SerpAPI — Google Hotels |
| Yer Bilgisi | Google Places API |

---

## Kurulum

### Gereksinimler

- Python 3.10+
- Flutter 3.x
- Google Cloud hesabı (Vertex AI için)
- SerpAPI anahtarı
- Google Places API anahtarı

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

`.env` dosyası oluştur:

```env
GOOGLE_PLACES_API_KEY=...
SERPAPI_KEY=...
SERPAPI_KEY_2=...        # isteğe bağlı, rate limit için
RAPIDAPI_HOTEL_KEY=...   # isteğe bağlı
```

Vertex AI için Google Cloud kimlik doğrulaması:

```bash
gcloud auth application-default login
```

Sunucuyu başlat:

```bash
uvicorn main:app --reload
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## API Uç Noktaları

| Yöntem | Yol | Açıklama |
|--------|-----|----------|
| POST | `/generate-plan` | Seyahat planı oluştur |
| POST | `/generate-itinerary` | Günlük program üret (Gemini) |
| POST | `/search-flights` | Uçuş ara |
| POST | `/search-hotels` | Otel ara |
| POST | `/nearby-places` | Yakın yerler |
| POST | `/chat` | Asistanla sohbet |
| POST | `/plan` | Doğal dil ile plan komutu |
| GET | `/cities` | Desteklenen şehirler |
| GET | `/popular-places` | Popüler destinasyonlar |

---

## Testler

```bash
cd backend
pytest tests/
```

Testler gerçek API'lere bağımlı olmadan çalışacak şekilde mock'lanmıştır.

---

## Proje Yapısı

```
rota-ai/
├── backend/
│   ├── main.py            # FastAPI uygulaması
│   ├── requirements.txt
│   └── tests/
└── frontend/
    ├── lib/
    │   └── main.dart      # Flutter uygulaması
    └── pubspec.yaml
```
