from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from pydantic import BaseModel
import httpx
import os
from datetime import date, timedelta
from dotenv import load_dotenv
import asyncio
import math
import vertexai
from vertexai.generative_models import GenerativeModel, Content, Part

load_dotenv()

app = FastAPI()

# Dinamik CORS - gelen origin'i yansitir, credentials ile uyumludur
class DynamicCORSMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        origin = request.headers.get("origin")
        response = await call_next(request)
        if origin:
            response.headers["Access-Control-Allow-Origin"] = origin
            response.headers["Access-Control-Allow-Credentials"] = "true"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "*"
            if request.method == "OPTIONS":
                response.status_code = 204
        return response

app.add_middleware(DynamicCORSMiddleware)

@app.get("/place-photo")
async def get_place_photo(maxwidth: int = 800, photo_reference: str = ""):
    if not photo_reference or not GOOGLE_PLACES_API_KEY:
        return Response(status_code=404)

    url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth={maxwidth}&photo_reference={photo_reference}&key={GOOGLE_PLACES_API_KEY}"

    async with httpx.AsyncClient(follow_redirects=True, timeout=15.0) as client:
        resp = await client.get(url)

    content_type = resp.headers.get("content-type", "image/jpeg")
    return Response(content=resp.content, media_type=content_type)

GOOGLE_PLACES_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY", "")
# Birden fazla SerpAPI key desteği — round-robin ile sırayla kullanılır
_serpapi_keys = [k for k in [
    os.getenv("SERPAPI_KEY", ""),
    os.getenv("SERPAPI_KEY_2", ""),
    os.getenv("SERPAPI_KEY_3", ""),
] if k]
_serpapi_index = 0

def _get_serpapi_key() -> str:
    """Mevcut key'i döndürür ve bir sonraki için indexi ilerletir."""
    global _serpapi_index
    if not _serpapi_keys:
        return ""
    key = _serpapi_keys[_serpapi_index % len(_serpapi_keys)]
    _serpapi_index += 1
    return key

# Geriye dönük uyumluluk için — if SERPAPI_KEY kontrollerinde kullanılır
SERPAPI_KEY = _serpapi_keys[0] if _serpapi_keys else ""
RAPIDAPI_HOTEL_KEY = os.getenv("RAPIDAPI_HOTEL_KEY", "")
RAPIDAPI_HOTEL_HOST = os.getenv("RAPIDAPI_HOTEL_HOST", "")

# Türkiye'deki ticari havalimanları — şehir adı → IATA kodu
# Ticari uçuşu olmayan şehirler (Eskişehir/AOE, Bursa vb.) en yakın aktif havalimanına yönlenir
_CITY_TO_IATA = {
    # İstanbul
    "istanbul": "IST", "i̇stanbul": "IST", "ist": "IST", "atatürk": "IST",
    "sabiha": "SAW", "saw": "SAW", "sabiha gökçen": "SAW", "pendik": "SAW",
    # İç Anadolu
    "ankara": "ESB", "esb": "ESB", "esenboğa": "ESB",
    "konya": "KYA", "kya": "KYA",
    "kayseri": "ASR", "asr": "ASR", "erkilet": "ASR",
    "nevşehir": "NAV", "nevsehir": "NAV", "nav": "NAV", "kapadokya": "NAV",
    "eskişehir": "ESB", "eskisehir": "ESB", "aoe": "ESB",  # AOE ticari değil → Ankara
    # Ege
    "izmir": "ADB", "i̇zmir": "ADB", "adb": "ADB", "adnan menderes": "ADB",
    "bodrum": "BJV", "bjv": "BJV", "milas": "BJV",
    "dalaman": "DLM", "dlm": "DLM", "muğla": "DLM", "mugla": "DLM", "marmaris": "DLM",
    "denizli": "DNZ", "dnz": "DNZ", "çardak": "DNZ", "cardak": "DNZ",
    "balıkesir": "EDO", "balikesir": "EDO", "edo": "EDO", "koca seyit": "EDO",
    "çanakkale": "CKZ", "canakkale": "CKZ", "ckz": "CKZ",
    "isparta": "ISE", "ise": "ISE", "süleyman demirel": "ISE",
    "uşak": "USQ", "usak": "USQ", "usq": "USQ",
    "afyon": "AFY", "afe": "AFY",
    # Akdeniz
    "antalya": "AYT", "ayt": "AYT",
    "adana": "ADA", "ada": "ADA",
    "hatay": "HTY", "hty": "HTY", "antakya": "HTY",
    "kahramanmaraş": "KCM", "kahramanmaras": "KCM", "kcm": "KCM",
    "gazipaşa": "GZP", "gazipasa": "GZP", "gzp": "GZP", "alanya": "GZP",
    # Karadeniz
    "trabzon": "TZX", "tzx": "TZX",
    "samsun": "SZF", "szf": "SZF", "çarşamba": "SZF",
    "ordu": "OGU", "ogu": "OGU", "giresun": "OGU", "ordu giresun": "OGU",
    "rize": "RZV", "rzv": "RZV", "artvin": "RZV", "rize artvin": "RZV",
    "sinop": "NOP", "nop": "NOP",
    "zonguldak": "ONQ", "onq": "ONQ", "çaycuma": "ONQ",
    "amasya": "MZH", "mzh": "MZH", "merzifon": "MZH",
    "tokat": "TJK", "tjk": "TJK",
    "kastamonu": "KFS", "kfs": "KFS",
    # Doğu Anadolu
    "erzurum": "ERZ", "erz": "ERZ",
    "erzincan": "ERC", "erc": "ERC",
    "van": "VAN", "van ferit melen": "VAN",
    "malatya": "MLX", "mlx": "MLX",
    "elazığ": "EZS", "elazig": "EZS", "ezs": "EZS",
    "kars": "KSY", "ksy": "KSY",
    "ağrı": "AJI", "agri": "AJI", "aji": "AJI",
    "bingöl": "BGG", "bingol": "BGG", "bgg": "BGG",
    "muş": "MSR", "mus": "MSR", "msr": "MSR",
    "bitlis": "MSR",  # En yakın → Muş
    # Güneydoğu Anadolu
    "gaziantep": "GZT", "gzt": "GZT",
    "diyarbakır": "DIY", "diyarbakir": "DIY", "diy": "DIY",
    "mardin": "MQM", "mqm": "MQM",
    "şanlıurfa": "GNY", "sanliurfa": "GNY", "gny": "GNY", "urfa": "GNY", "gap": "GNY",
    "batman": "BAL", "bal": "BAL",
    "şırnak": "NKT", "sirnak": "NKT", "nkt": "NKT", "cizre": "NKT",
    "siirt": "SXZ", "sxz": "SXZ",
    # Trakya
    "tekirdağ": "TEQ", "tekirdag": "TEQ", "teq": "TEQ", "çorlu": "TEQ",
    "edirne": "ESB",  # Havalimanı yok → Ankara değil, İstanbul mantıklı ama ESB default
}

def _normalize_iata(city: str) -> str:
    """Şehir adını IATA koduna çevirir, zaten kod ise aynen döndürür."""
    return _CITY_TO_IATA.get(city.lower().strip(), city.upper().strip())

VERTEX_PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "project-f98e215d-48a4-40e2-8d3")
VERTEX_LOCATION = os.getenv("GOOGLE_CLOUD_LOCATION", "us-central1")
vertexai.init(project=VERTEX_PROJECT_ID, location=VERTEX_LOCATION)

# Şehirlerin koordinatları (enlem, boylam)
CITY_COORDINATES = {
    "istanbul": (41.0082, 28.9784),
    "ankara": (39.9334, 32.8597),
    "izmir": (38.4192, 27.1287),
    "antalya": (36.8841, 30.7056),
    "muğla": (37.2153, 28.3636),
    "trabzon": (41.0027, 39.7168),
    "adana": (37.0000, 35.3213),
    "nevşehir": (38.6244, 34.7239),
    "gaziantep": (37.0662, 37.3833),
    "erzurum": (39.9043, 41.2679),
    "samsun": (41.2867, 36.3300),
    "bursa": (40.1826, 29.0669),
    "konya": (37.8746, 32.4932),
    "mardin": (37.3122, 40.7351),
    "edirne": (41.6771, 26.5557),
    "çanakkale": (40.1553, 26.4142),
    "denizli": (37.7765, 29.0864),
    "lefkoşa": (35.1856, 33.3823),
    "bodrum": (37.0340, 27.4305),
    "dalaman": (36.7833, 28.7833),
    "kayseri": (38.7225, 35.4875),
    "diyarbakır": (37.9144, 40.2306),
    "van": (38.5012, 43.4072),
    "malatya": (38.3552, 38.3095),
    "hatay": (36.2021, 36.1603),
    "kahramanmaraş": (37.5858, 36.9371),
    "alanya": (36.5442, 31.9993),
    "elazığ": (38.6748, 39.2225),
    "erzincan": (39.7500, 39.5000),
    "şanlıurfa": (37.1591, 38.7969),
    "batman": (37.8812, 41.1351),
}

# IATA kodu → şehir adı (yerler için)
_IATA_TO_CITY = {
    "IST": "istanbul", "SAW": "istanbul",
    "ESB": "ankara",
    "ADB": "izmir",
    "AYT": "antalya",
    "BJV": "bodrum",
    "DLM": "dalaman",
    "TZX": "trabzon",
    "ADA": "adana",
    "GZT": "gaziantep",
    "ASR": "kayseri",
    "SZF": "samsun",
    "ERZ": "erzurum",
    "NAV": "nevşehir",
    "VAN": "van",
    "DIY": "diyarbakır",
    "MLX": "malatya",
    "KYA": "konya",
    "HTY": "hatay",
    "KCM": "kahramanmaraş",
    "GZP": "alanya",
    "DNZ": "denizli",
    "EZS": "elazığ",
    "ERC": "erzincan",
    "MQM": "mardin",
    "GNY": "şanlıurfa",
    "BAL": "batman",
}

# Turistik yer türleri (Google Places types)
TOURIST_PLACE_TYPES = [
    "tourist_attraction",
    "museum",
    "park",
    "historical_place",
    "art_gallery",
    "amusement_park",
    "zoo",
    "aquarium",
    "church",
    "mosque",
    "synagogue",
    "hindu_temple",
    "landmark",
    "natural_feature",
    "point_of_interest",
    "establishment",
]

class TravelRequest(BaseModel):
    city: str
    budget: float
    days: int

class PlaceRequest(BaseModel):
    city: str
    radius: int = 5000  # metre cinsinden, varsayılan 5km
    max_results: int = 15

from typing import Optional

class FlightSearchRequest(BaseModel):
    departure_city: str
    arrival_city: str
    departure_date: str  # YYYY-MM-DD formatında
    return_date: Optional[str] = None  # Opsiyonel, gidiş-dönüş için
    passengers: int = 1
    currency: str = "TRY"  # Türk Lirası


class HotelSearchRequest(BaseModel):
    city: str
    check_in: str  # YYYY-MM-DD
    check_out: str  # YYYY-MM-DD
    guests: int = 1
    min_rating: float = 0.0
    max_price: Optional[float] = None
    max_results: int = 50

class ItineraryRequest(BaseModel):
    departure_city: str
    arrival_city: str
    departure_date: str        # YYYY-MM-DD
    return_date: Optional[str] = None
    hotel_name: Optional[str] = None
    selected_places: list = []  # [{"name": "...", "address": "..."}]
    flight_airline: Optional[str] = None
    flight_departure_time: Optional[str] = None
    return_flight_airline: Optional[str] = None
    return_flight_departure_time: Optional[str] = None

@app.post("/generate-plan")
async def create_plan(request: TravelRequest):
    return {
        "status": "success",
        "plan": f"Harika! {request.city} için {request.days} günlük ve {request.budget} TL bütçeli efsane bir rota hazırladım!",
        "details": [
            {"item": "🏨 Konaklama", "price": request.budget * 0.4},
            {"item": "🚕 Ulaşım", "price": request.budget * 0.2},
            {"item": "📸 Gezilecek Yerler", "price": request.budget * 0.1},
            {"item": "🍔 Yeme - İçme", "price": request.budget * 0.3}
        ]
    }

@app.post("/generate-itinerary")
async def generate_itinerary(request: ItineraryRequest):
    """Gemini AI ile gün gün seyahat programı oluşturur."""
    try:
        itinerary = await _generate_itinerary_with_gemini(request)
        return {"status": "success", "itinerary": itinerary}
    except Exception as e:
        return {"status": "error", "message": str(e)}

async def _generate_itinerary_with_gemini(request: ItineraryRequest) -> str:
    """Kullanıcının seçimlerine göre Gemini'den gün gün program oluşturur."""

    # Kaç gün olduğunu hesapla
    try:
        dep = date.fromisoformat(request.departure_date)
        ret = date.fromisoformat(request.return_date) if request.return_date else dep
        num_days = max(1, (ret - dep).days + 1)
    except Exception:
        num_days = 1

    # Gezilecek yerleri metne çevir
    places_text = ""
    if request.selected_places:
        places_list = [p.get("name", "") for p in request.selected_places if p.get("name")]
        places_text = ", ".join(places_list)
    else:
        places_text = "kullanıcı tarafından seçilmemiş"

    # Dönüş uçuşu bilgisi
    return_flight_info = ""
    if request.return_flight_airline and request.return_flight_departure_time:
        return_flight_info = f"- Dönüş uçuşu: {request.return_flight_airline}, Kalkış saati: {request.return_flight_departure_time}"

    # Prompt oluştur
    prompt = f"""Aşağıdaki bilgilere göre {num_days} günlük detaylı bir seyahat programı oluştur.

ÖNEMLI: Sadece programı yaz. "Elbette", "Tabii ki", "Harika bir soru" gibi giriş cümleleri YAZMA. Doğrudan ## 1. Gün ile başla.

Seyahat bilgileri:
- Kalkış şehri: {request.departure_city}
- Varış şehri: {request.arrival_city}
- Gidiş tarihi: {request.departure_date}
- Dönüş tarihi: {request.return_date or "Belirtilmemiş"}
- Konaklama: {request.hotel_name or "Belirtilmemiş"}
- Gezilecek yerler: {places_text}
{f"- Gidiş uçuşu: {request.flight_airline}, Kalkış saati: {request.flight_departure_time}" if request.flight_airline else ""}
{return_flight_info}

Lütfen şu formatta gün gün program yaz:

## 1. Gün ({request.departure_date})
☀️ **Sabah:**
[aktivite ve öneriler]

🌤 **Öğle:**
[aktivite, yemek önerisi]

🌙 **Akşam:**
[aktivite, akşam yemeği önerisi]

💡 **İpuçları:** [o güne özel pratik bilgiler]

---

## 2. Gün
...

Kurallar:
- DOĞRUDAN ## 1. Gün ile başla, giriş cümlesi yazma
- Son gün (dönüş günü) için dönüş uçuşu saatini kesinlikle dikkate al; uçuştan önce yetişebilecek aktiviteler planla
- Gezilecek yerleri günlere mantıklı şekilde dağıt (coğrafi yakınlık ve ziyaret süresi göz önünde bulundur)
- Her gün için yemek önerisi ekle (yerel lezzetler)
- Ulaşım ipuçları ekle
- Varsa ziyaret saatleri, bilet ücretleri hakkında kısa bilgi ver
- Türkçe yaz"""

    model = GenerativeModel("gemini-2.5-pro")
    response = await asyncio.get_event_loop().run_in_executor(
        None,
        lambda: model.generate_content(
            prompt,
            generation_config={"temperature": 0.8, "max_output_tokens": 8192},
        )
    )
    return response.text

@app.post("/nearby-places")
async def get_nearby_places(request: PlaceRequest):
    city_lower = request.city.lower().strip()
    
    if city_lower not in CITY_COORDINATES:
        return {"status": "error", "message": f"'{request.city}' şehri bulunamadı.", "places": []}
    
    lat, lng = CITY_COORDINATES[city_lower]
    
    if not GOOGLE_PLACES_API_KEY:
        # API key yoksa mock veri döndür
        return {
            "status": "success",
            "places": _get_mock_places(request.city),
            "source": "mock"
        }
    
    try:
        places = await _fetch_places_from_google(lat, lng, request.radius, request.max_results)
        return {"status": "success", "places": places, "source": "google_places"}
    except Exception as e:
        return {"status": "error", "message": str(e), "places": []}

@app.post("/search-flights")
async def search_flights(request: FlightSearchRequest):
    """SerpAPI Google Flights kullanarak uçuş arama."""
    if not SERPAPI_KEY:
        return {"status": "error", "message": "SerpAPI anahtarı yapılandırılmamış."}
    
    try:
        flights = await _search_flights_serpapi(
            departure_city=request.departure_city,
            arrival_city=request.arrival_city,
            departure_date=request.departure_date,
            return_date=request.return_date,
            passengers=request.passengers,
            currency=request.currency
        )
        return {"status": "success", "flights": flights}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@app.post("/search-hotels")
async def search_hotels(request: HotelSearchRequest):
    """SerpAPI ile otel arama (backend proxy)."""
    if not SERPAPI_KEY:
        return {"status": "error", "message": "SerpAPI key yapılandırılmamış."}

    try:
        hotels = await _fetch_hotels_serpapi(
            city=request.city,
            check_in=request.check_in,
            check_out=request.check_out,
            guests=request.guests,
            min_rating=request.min_rating,
            max_price=request.max_price,
            max_results=request.max_results,
        )
        return {"status": "success", "hotels": hotels}
    except Exception as e:
        return {"status": "error", "message": str(e), "hotels": []}


async def _fetch_hotels_serpapi(
    city: str,
    check_in: str,
    check_out: str,
    guests: int = 1,
    min_rating: float = 0.0,
    max_price: Optional[float] = None,
    max_results: int = 50,
):
    """SerpAPI ile otel arama (Google Hotels)."""
    url = "https://serpapi.com/search.json"
    
    today = date.today()
    try:
        parsed_check_in = date.fromisoformat(check_in)
    except Exception:
        parsed_check_in = today + timedelta(days=1)
        check_in = parsed_check_in.isoformat()
    
    if parsed_check_in <= today:
        parsed_check_in = today + timedelta(days=1)
        check_in = parsed_check_in.isoformat()
    
    try:
        parsed_check_out = date.fromisoformat(check_out)
    except Exception:
        parsed_check_out = parsed_check_in + timedelta(days=1)
        check_out = parsed_check_out.isoformat()
    
    if parsed_check_out <= parsed_check_in:
        parsed_check_out = parsed_check_in + timedelta(days=1)
        check_out = parsed_check_out.isoformat()
    
    params = {
        "engine": "google_hotels",
        "q": city,
        "check_in_date": check_in,
        "check_out_date": check_out,
        "adults": guests,
        "currency": "TRY",
        "hl": "en",
        "gl": "tr",
        "api_key": _get_serpapi_key(),
    }
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()
            data = response.json()
        
        if "error" in data:
            raise Exception(f"SerpAPI hatası: {data['error']}")
        
        # SerpAPI properties listesinden otelleri çıkar
        hotels_data = data.get("properties", [])
        if not hotels_data:
            return []
        
        hotels = []
        for item in hotels_data[:max_results]:
            if not isinstance(item, dict):
                continue
            
            name = item.get("name", "")
            if not name:
                continue
            
            # Adres - SerpAPI'de doğrudan address alanı yok, birden çok alanı dene
            address = item.get("address", "")
            if not address:
                nearby = item.get("nearby_places", [])
                if isinstance(nearby, list) and nearby:
                    # nearby_places dict listesi olabilir, name alanlarını al
                    names = []
                    for p in nearby[:3]:
                        if isinstance(p, dict):
                            names.append(p.get("name", ""))
                        elif isinstance(p, str):
                            names.append(p)
                    address = ", ".join(n for n in names if n)
            if not address:
                address = item.get("description", "")
            # Eğer description varsa ve adres yoksa, description'ı adres olarak kullanma
            # çünkü description genelde "Açık büfeli otel" gibi açıklamalar içerir
            if address == item.get("description", "") and address:
                # description'ı adres olarak değil, amenities'e ekle
                address = f"{city} şehir merkezi"
            
            # Fiyat (günlük) - rate_per_night içindeki extracted_lowest
            price_val = None
            rate_per_night = item.get("rate_per_night", {})
            if isinstance(rate_per_night, dict):
                price_val = rate_per_night.get("extracted_lowest")
            
            # Rating - overall_rating (int) olarak döner
            rating_val = float(item.get("overall_rating", 0))
            
            # Review count - reviews alanı
            review_count = item.get("reviews", 0)
            if isinstance(review_count, str):
                try:
                    review_count = int("".join(ch for ch in review_count if ch.isdigit()))
                except Exception:
                    review_count = 0
            
            stars_val = int(rating_val)
            
            # Temel filtre: en az 3 yıldız ve 25 değerlendirme
            if stars_val < 3 or review_count < 25:
                continue
            
            # Ek filtreler
            if min_rating and rating_val < min_rating:
                continue
            if max_price is not None and price_val is not None and price_val > max_price:
                continue
            
            # Skor = yıldız * log10(değerlendirme sayısı + 1)
            score = stars_val * (math.log10(review_count + 1))
            
            # Resim - images listesinden ilkini al
            photo = ""
            images = item.get("images", [])
            if images and isinstance(images[0], dict):
                photo = images[0].get("original_image", "")
            
            # Konum - gps_coordinates
            lat = 0.0
            lng = 0.0
            gps = item.get("gps_coordinates", {})
            if isinstance(gps, dict):
                lat = gps.get("latitude", 0.0)
                lng = gps.get("longitude", 0.0)
            
            hotels.append({
                "id": item.get("property_token", ""),
                "name": name,
                "address": address,
                "rating": rating_val,
                "reviewCount": review_count,
                "pricePerNight": price_val,
                "imageUrl": photo,
                "latitude": lat,
                "longitude": lng,
                "amenities": item.get("amenities", []),
                "stars": stars_val,
                "score": round(score, 2),
            })
        
        # Skora göre sırala
        hotels.sort(key=lambda h: h.get("score", 0), reverse=True)
        
        return hotels[:max_results]
    except Exception as e:
        print(f"Hotel search error: {str(e)}")
        raise




@app.get("/cities")
async def get_cities():
    """Desteklenen şehirlerin listesini döndürür."""
    cities = [
        {"name": "İstanbul", "key": "istanbul"},
        {"name": "Ankara", "key": "ankara"},
        {"name": "İzmir", "key": "izmir"},
        {"name": "Antalya", "key": "antalya"},
        {"name": "Muğla", "key": "muğla"},
        {"name": "Trabzon", "key": "trabzon"},
        {"name": "Adana", "key": "adana"},
        {"name": "Nevşehir", "key": "nevşehir"},
        {"name": "Gaziantep", "key": "gaziantep"},
        {"name": "Erzurum", "key": "erzurum"},
        {"name": "Samsun", "key": "samsun"},
        {"name": "Bursa", "key": "bursa"},
        {"name": "Konya", "key": "konya"},
        {"name": "Mardin", "key": "mardin"},
        {"name": "Edirne", "key": "edirne"},
        {"name": "Çanakkale", "key": "çanakkale"},
    ]
    return {"status": "success", "cities": cities}


@app.get("/popular-places")
async def get_popular_places():
    """Türkiye genelinde en yüksek skorlu turistik yerleri döndürür (Google Places API).
    Skor = rating * (1 + min(userRatingsTotal, 999999) / 1000)
    """
    if not GOOGLE_PLACES_API_KEY:
        return {"status": "success", "places": _get_popular_places_fallback(), "source": "fallback"}

    # Birden fazla şehirden en popüler yerleri çek
    target_cities = ["istanbul", "nevşehir", "antalya", "muğla", "izmir", "trabzon", "denizli", "bursa", "mardin"]

    try:
        tasks = []
        for city in target_cities:
            if city in CITY_COORDINATES:
                lat, lng = CITY_COORDINATES[city]
                tasks.append(_fetch_places_from_google(lat, lng, 20000, 10))

        results = await asyncio.gather(*tasks, return_exceptions=True)

        all_places = []
        city_names = {
            "istanbul": "İstanbul",
            "nevşehir": "Nevşehir",
            "antalya": "Antalya",
            "muğla": "Muğla",
            "izmir": "İzmir",
            "trabzon": "Trabzon",
            "denizli": "Denizli",
            "bursa": "Bursa",
            "mardin": "Mardin",
        }

        for i, result in enumerate(results):
            if isinstance(result, Exception):
                continue
            city_key = target_cities[i]
            for place in result:
                place["city"] = city_names.get(city_key, city_key.capitalize())
                all_places.append(place)

        # Skor hesapla: rating * (1 + min(userRatingsTotal, 999999) / 1000)
        def calc_score(place):
            rating = place.get("rating", 0)
            total = place.get("userRatingsTotal", 0)
            return rating * (1 + min(total, 999999) / 1000)

        # Skora göre sırala, en yüksek 15 tanesini al
        all_places.sort(key=calc_score, reverse=True)
        top_places = all_places[:15]

        return {"status": "success", "places": top_places, "source": "google_places"}
    except Exception as e:
        return {"status": "success", "places": _get_popular_places_fallback(), "source": "fallback"}


def _get_popular_places_fallback():
    """Google Places API çalışmazsa fallback veri."""
    return [
        {"id": "fb1", "name": "Kapadokya", "city": "Nevşehir", "rating": 4.9, "userRatingsTotal": 50000, "photoUrl": "", "latitude": 38.6437, "longitude": 34.8285},
        {"id": "fb2", "name": "Ayasofya Camii", "city": "İstanbul", "rating": 4.8, "userRatingsTotal": 45000, "photoUrl": "", "latitude": 41.0086, "longitude": 28.9802},
        {"id": "fb3", "name": "Pamukkale", "city": "Denizli", "rating": 4.8, "userRatingsTotal": 35000, "photoUrl": "", "latitude": 37.9236, "longitude": 29.1197},
        {"id": "fb4", "name": "Ölüdeniz", "city": "Muğla", "rating": 4.7, "userRatingsTotal": 30000, "photoUrl": "", "latitude": 36.5497, "longitude": 29.1153},
        {"id": "fb5", "name": "Efes Antik Kenti", "city": "İzmir", "rating": 4.8, "userRatingsTotal": 20000, "photoUrl": "", "latitude": 37.9397, "longitude": 27.3408},
        {"id": "fb6", "name": "Kaleiçi", "city": "Antalya", "rating": 4.7, "userRatingsTotal": 18000, "photoUrl": "", "latitude": 36.8874, "longitude": 30.7056},
        {"id": "fb7", "name": "Topkapı Sarayı", "city": "İstanbul", "rating": 4.7, "userRatingsTotal": 38000, "photoUrl": "", "latitude": 41.0115, "longitude": 28.9833},
        {"id": "fb8", "name": "Sümela Manastırı", "city": "Trabzon", "rating": 4.6, "userRatingsTotal": 12000, "photoUrl": "", "latitude": 40.6900, "longitude": 39.6567},
        {"id": "fb9", "name": "Aspendos", "city": "Antalya", "rating": 4.7, "userRatingsTotal": 10000, "photoUrl": "", "latitude": 36.9389, "longitude": 31.1719},
        {"id": "fb10", "name": "Galata Kulesi", "city": "İstanbul", "rating": 4.6, "userRatingsTotal": 22000, "photoUrl": "", "latitude": 41.0256, "longitude": 28.9741},
    ]

async def _fetch_places_from_google(lat: float, lng: float, radius: int, max_results: int):
    """Google Places API (Nearby Search) ile turistik yerleri çeker."""
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    
    params = {
        "location": f"{lat},{lng}",
        "radius": radius,
        "type": "tourist_attraction",
        "key": GOOGLE_PLACES_API_KEY,
        "language": "tr",
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)
        data = response.json()
    
    if data.get("status") != "OK" and data.get("status") != "ZERO_RESULTS":
        # İlk deneme başarısız olursa, daha geniş türlerle dene
        params.pop("type", None)
        params["keyword"] = "tourist attraction museum historical"
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params)
            data = response.json()
    
    results = data.get("results", [])[:max_results]
    
    places = []
    for place in results:
        photo_url = ""
        if "photos" in place and len(place["photos"]) > 0:
            photo_ref = place["photos"][0]["photo_reference"]
            photo_url = f"/place-photo?maxwidth=800&photo_reference={photo_ref}"
        
        places.append({
            "id": place.get("place_id", ""),
            "name": place.get("name", ""),
            "address": place.get("vicinity", ""),
            "rating": place.get("rating", 0),
            "userRatingsTotal": place.get("user_ratings_total", 0),
            "types": place.get("types", []),
            "photoUrl": photo_url,
            "latitude": place["geometry"]["location"]["lat"] if "geometry" in place else 0,
            "longitude": place["geometry"]["location"]["lng"] if "geometry" in place else 0,
            "priceLevel": place.get("price_level", 0),
            "openNow": place.get("opening_hours", {}).get("open_now") if "opening_hours" in place else None,
        })
    
    return places

async def _search_flights_serpapi(
    departure_city: str,
    arrival_city: str,
    departure_date: str,
    return_date: str = None,
    passengers: int = 1,
    currency: str = "TRY"
):
    """SerpAPI Google Flights ile uçuş arama."""
    
    url = "https://serpapi.com/search.json"
    
    params = {
        "engine": "google_flights",
        "departure_id": departure_city,
        "arrival_id": arrival_city,
        "outbound_date": departure_date,
        "currency": currency,
        "hl": "tr",
        "gl": "tr",
        "type": "2",  # One way
        "adults": passengers,
        "api_key": _get_serpapi_key(),
    }
    
    if return_date:
        params["type"] = "1"  # Round trip
        params["return_date"] = return_date
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            if "error" in data:
                print(f"SerpAPI hatası: {data['error']}")
                return []
            
            # best_flights ve other_flights birleştir
            all_flights = []
            all_flights.extend(data.get("best_flights", []))
            all_flights.extend(data.get("other_flights", []))
            
            # Uçuşları formatla
            flights = []
            for flight_group in all_flights[:15]:
                flight_segments = flight_group.get("flights", [])
                if not flight_segments:
                    continue
                
                first_segment = flight_segments[0]
                last_segment = flight_segments[-1]
                
                # Havayolu bilgisi
                airline = first_segment.get("airline", "Bilinmeyen")
                flight_number = first_segment.get("flight_number", "")
                
                # Kalkış/varış saatleri
                dep_time = first_segment.get("departure_airport", {}).get("time", "")
                arr_time = last_segment.get("arrival_airport", {}).get("time", "")
                
                # Sadece saat kısmını al
                dep_time_short = dep_time.split(" ")[-1] if " " in dep_time else dep_time
                arr_time_short = arr_time.split(" ")[-1] if " " in arr_time else arr_time
                
                # Süre
                total_duration = flight_group.get("total_duration", 0)
                hours = total_duration // 60
                mins = total_duration % 60
                duration_str = f"{hours}s {mins}dk"
                
                # Aktarma sayısı
                stops = len(flight_group.get("layovers", []))
                
                # Fiyat
                price = flight_group.get("price", 0)
                
                flights.append({
                    "id": flight_number,
                    "airline": airline,
                    "departure_time": dep_time_short,
                    "arrival_time": arr_time_short,
                    "duration": duration_str,
                    "stops": stops,
                    "price": price,
                    "currency": currency,
                    "departure_city": departure_city,
                    "arrival_city": arrival_city,
                    "departure_date": departure_date,
                    "return_date": return_date,
                    "flight_number": flight_number,
                    "airline_logo": first_segment.get("airline_logo", ""),
                })
            
            return flights
            
    except Exception as e:
        print(f"SerpAPI hatası: {str(e)}")
        return []

def _get_mock_places(city: str) -> list:
    """API key yoksa gösterilecek örnek veriler."""
    mock_data = {
        "istanbul": [
            {"id": "1", "name": "Ayasofya Camii", "address": "Sultanahmet, Fatih", "rating": 4.8, "userRatingsTotal": 45000, "types": ["tourist_attraction", "mosque", "historical_place"], "photoUrl": "", "latitude": 41.0086, "longitude": 28.9802, "priceLevel": 0, "openNow": True},
            {"id": "2", "name": "Topkapı Sarayı", "address": "Sultanahmet, Fatih", "rating": 4.7, "userRatingsTotal": 38000, "types": ["tourist_attraction", "museum", "historical_place"], "photoUrl": "", "latitude": 41.0115, "longitude": 28.9833, "priceLevel": 2, "openNow": True},
            {"id": "3", "name": "Sultanahmet Camii (Mavi Camii)", "address": "Sultanahmet, Fatih", "rating": 4.7, "userRatingsTotal": 32000, "types": ["tourist_attraction", "mosque", "historical_place"], "photoUrl": "", "latitude": 41.0054, "longitude": 28.9768, "priceLevel": 0, "openNow": True},
            {"id": "4", "name": "Kapalıçarşı", "address": "Beyazıt, Fatih", "rating": 4.4, "userRatingsTotal": 28000, "types": ["tourist_attraction", "shopping_mall"], "photoUrl": "", "latitude": 41.0107, "longitude": 28.9680, "priceLevel": 2, "openNow": True},
            {"id": "5", "name": "Yerebatan Sarnıcı", "address": "Sultanahmet, Fatih", "rating": 4.6, "userRatingsTotal": 25000, "types": ["tourist_attraction", "historical_place"], "photoUrl": "", "latitude": 41.0084, "longitude": 28.9779, "priceLevel": 2, "openNow": True},
            {"id": "6", "name": "Galata Kulesi", "address": "Beyoğlu", "rating": 4.6, "userRatingsTotal": 22000, "types": ["tourist_attraction", "historical_place", "landmark"], "photoUrl": "", "latitude": 41.0256, "longitude": 28.9741, "priceLevel": 2, "openNow": True},
            {"id": "7", "name": "Dolmabahçe Sarayı", "address": "Beşiktaş", "rating": 4.7, "userRatingsTotal": 18000, "types": ["tourist_attraction", "museum", "historical_place"], "photoUrl": "", "latitude": 41.0392, "longitude": 29.0001, "priceLevel": 2, "openNow": True},
            {"id": "8", "name": "İstanbul Modern Sanat Müzesi", "address": "Karaköy, Beyoğlu", "rating": 4.5, "userRatingsTotal": 8000, "types": ["tourist_attraction", "museum", "art_gallery"], "photoUrl": "", "latitude": 41.0269, "longitude": 28.9861, "priceLevel": 2, "openNow": True},
        ],
        "ankara": [
            {"id": "a1", "name": "Anıtkabir", "address": "Çankaya", "rating": 4.9, "userRatingsTotal": 35000, "types": ["tourist_attraction", "historical_place", "museum"], "photoUrl": "", "latitude": 39.9255, "longitude": 32.8370, "priceLevel": 0, "openNow": True},
            {"id": "a2", "name": "Anadolu Medeniyetleri Müzesi", "address": "Ulus, Altındağ", "rating": 4.7, "userRatingsTotal": 12000, "types": ["tourist_attraction", "museum"], "photoUrl": "", "latitude": 39.9385, "longitude": 32.8619, "priceLevel": 2, "openNow": True},
            {"id": "a3", "name": "Kocatepe Camii", "address": "Kocatepe, Çankaya", "rating": 4.7, "userRatingsTotal": 10000, "types": ["tourist_attraction", "mosque"], "photoUrl": "", "latitude": 39.9167, "longitude": 32.8600, "priceLevel": 0, "openNow": True},
            {"id": "a4", "name": "Atakule", "address": "Çankaya", "rating": 4.3, "userRatingsTotal": 15000, "types": ["tourist_attraction", "landmark"], "photoUrl": "", "latitude": 39.8898, "longitude": 32.8642, "priceLevel": 1, "openNow": True},
            {"id": "a5", "name": "Gençlik Parkı", "address": "Ulus, Altındağ", "rating": 4.2, "userRatingsTotal": 18000, "types": ["park", "tourist_attraction"], "photoUrl": "", "latitude": 39.9417, "longitude": 32.8517, "priceLevel": 0, "openNow": True},
        ],
        "izmir": [
            {"id": "i1", "name": "Kordon Boyu", "address": "Alsancak, Konak", "rating": 4.7, "userRatingsTotal": 25000, "types": ["tourist_attraction", "natural_feature"], "photoUrl": "", "latitude": 38.4342, "longitude": 27.1425, "priceLevel": 0, "openNow": True},
            {"id": "i2", "name": "Efes Antik Kenti", "address": "Selçuk", "rating": 4.8, "userRatingsTotal": 20000, "types": ["tourist_attraction", "historical_place"], "photoUrl": "", "latitude": 37.9397, "longitude": 27.3408, "priceLevel": 2, "openNow": True},
            {"id": "i3", "name": "Kemeraltı Çarşısı", "address": "Konak", "rating": 4.4, "userRatingsTotal": 12000, "types": ["tourist_attraction", "shopping_mall"], "photoUrl": "", "latitude": 38.4189, "longitude": 27.1286, "priceLevel": 1, "openNow": True},
            {"id": "i4", "name": "Saat Kulesi", "address": "Konak Meydanı", "rating": 4.5, "userRatingsTotal": 14000, "types": ["tourist_attraction", "landmark"], "photoUrl": "", "latitude": 38.4189, "longitude": 27.1286, "priceLevel": 0, "openNow": True},
            {"id": "i5", "name": "Şirince Köyü", "address": "Selçuk", "rating": 4.5, "userRatingsTotal": 9000, "types": ["tourist_attraction"], "photoUrl": "", "latitude": 37.9414, "longitude": 27.4333, "priceLevel": 1, "openNow": True},
        ],
        "antalya": [
            {"id": "an1", "name": "Kaleiçi", "address": "Muratpaşa", "rating": 4.7, "userRatingsTotal": 18000, "types": ["tourist_attraction", "historical_place"], "photoUrl": "", "latitude": 36.8874, "longitude": 30.7056, "priceLevel": 1, "openNow": True},
            {"id": "an2", "name": "Düden Şelalesi", "address": "Düdenbaşı", "rating": 4.5, "userRatingsTotal": 15000, "types": ["tourist_attraction", "natural_feature", "park"], "photoUrl": "", "latitude": 36.9450, "longitude": 30.7950, "priceLevel": 1, "openNow": True},
            {"id": "an3", "name": "Olympos Teleferik", "address": "Kemer", "rating": 4.6, "userRatingsTotal": 11000, "types": ["tourist_attraction"], "photoUrl": "", "latitude": 36.5369, "longitude": 30.5617, "priceLevel": 3, "openNow": True},
            {"id": "an4", "name": "Antalya Müzesi", "address": "Konyaaltı", "rating": 4.7, "userRatingsTotal": 8000, "types": ["tourist_attraction", "museum"], "photoUrl": "", "latitude": 36.8869, "longitude": 30.6794, "priceLevel": 2, "openNow": True},
            {"id": "an5", "name": "Konyaaltı Plajı", "address": "Konyaaltı", "rating": 4.5, "userRatingsTotal": 12000, "types": ["tourist_attraction", "natural_feature"], "photoUrl": "", "latitude": 36.8600, "longitude": 30.6400, "priceLevel": 0, "openNow": True},
        ],
    }
    
    # Şehir mock data'da yoksa genel bir yanıt döndür
    if city.lower() not in mock_data:
        return [
            {"id": "gen1", "name": f"{city} Şehir Merkezi", "address": f"{city} Merkez", "rating": 4.3, "userRatingsTotal": 5000, "types": ["tourist_attraction"], "photoUrl": "", "latitude": 0, "longitude": 0, "priceLevel": 0, "openNow": True},
            {"id": "gen2", "name": f"{city} Müzesi", "address": f"{city} Merkez", "rating": 4.2, "userRatingsTotal": 3000, "types": ["tourist_attraction", "museum"], "photoUrl": "", "latitude": 0, "longitude": 0, "priceLevel": 1, "openNow": True},
        ]
    
    return mock_data[city.lower()]

class ChatRequest(BaseModel):
    message: str
    history: list = []  # Önceki mesajlar [{role, content}]
    user_plans: list = []  # Kullanıcının mevcut planları (context için)

@app.post("/chat")
async def chat(request: ChatRequest):
    """Gemini AI ile seyahat asistanı chatbot."""
    try:
        response = await _chat_with_gemini(
            message=request.message,
            history=request.history,
            user_plans=request.user_plans,
        )
        return {"status": "success", "response": response}
    except Exception as e:
        return {"status": "error", "message": str(e)}

async def _chat_with_gemini(message: str, history: list, user_plans: list) -> str:
    """Gemini API ile chat."""

    # System prompt
    system_prompt = """Sen "Rota AI" adlı yapay zeka destekli seyahat planlama uygulamasının asistanısın.
Türkiye'deki seyahat planlaması konusunda uzmanlaşmış bir yapay zekasın.

Görevlerin:
- Kullanıcılara şehir ve destinasyon önerisi yapmak (bütçe, mevsim, ilgi alanına göre)
- Gün gün seyahat programı oluşturmak
- Restoran, kafe, aktivite önerileri vermek
- Ulaşım tavsiyeleri (havaalanı transferi, şehir içi ulaşım)
- Yerel kültür, yemek ve gezi ipuçları
- Mevcut seyahat planlarını analiz edip iyileştirme önerileri sunmak

Kuralların:
- Her zaman Türkçe yanıt ver
- Kısa ve öz cevaplar ver, gereksiz uzatma
- Emoji kullan ama abartma
- Fiyat bilgisi verirken TL cinsinden ver
- Güvenilir ve güncel bilgi ver
- Kullanıcının mevcut planları varsa onları dikkate al"""

    # Kullanıcının planlarını context'e ekle
    context = ""
    if user_plans:
        context = "\n\nKullanıcının mevcut seyahat planları:\n"
        for plan in user_plans[:3]:  # Max 3 plan
            context += f"- {plan.get('title', '')}: {plan.get('departure_city', '')} → {plan.get('arrival_city', '')}, Tarih: {plan.get('departure_date', '')}\n"

    # Mesaj geçmişini oluştur
    contents = []
    for msg in history[-10:]:  # Son 10 mesaj
        role = "user" if msg.get("role") == "user" else "model"
        contents.append(Content(role=role, parts=[Part.from_text(msg.get("content", ""))]))
    contents.append(Content(role="user", parts=[Part.from_text(message)]))

    model = GenerativeModel(
        "gemini-2.5-pro",
        system_instruction=system_prompt + context,
    )
    response = await asyncio.get_event_loop().run_in_executor(
        None,
        lambda: model.generate_content(
            contents,
            generation_config={"temperature": 0.7, "max_output_tokens": 8192},
        )
    )

    if not response.text:
        return "Üzgünüm, şu an yanıt oluşturamadım. Tekrar dener misin?"
    return response.text

class PlanCommandRequest(BaseModel):
    message: str  # "/plan Ankara'dan İstanbul'a 20-25 Temmuz" gibi
    history: list = []
    user_plans: list = []

@app.post("/plan")
async def plan_command(request: PlanCommandRequest):
    """/plan komutu: Gemini parametreleri çıkarır, SerpAPI'den uçuş+otel çeker."""
    try:
        # 1. Gemini ile parametreleri çıkar
        params = await _extract_plan_params(request.message, request.history)

        if params.get("missing"):
            # Eksik bilgi varsa düz chat yanıtı döndür
            return {
                "status": "need_info",
                "response": params["missing_message"],
            }

        departure_city = _normalize_iata(params["departure_city"])
        arrival_city = _normalize_iata(params["arrival_city"])
        departure_date = params["departure_date"]
        return_date = params.get("return_date")
        budget = params.get("budget")  # TL cinsinden, None ise sınırsız

        # 2. SerpAPI: uçuşlar (1 kredi gidiş, 1 kredi dönüş = 2 kredi toplam round-trip)
        flights = []
        return_flights = []
        if SERPAPI_KEY:
            try:
                flights = await _search_flights_serpapi(
                    departure_city=departure_city,
                    arrival_city=arrival_city,
                    departure_date=departure_date,
                    return_date=return_date,
                    passengers=1,
                    currency="TRY",
                )
                if return_date:
                    return_flights = await _search_flights_serpapi(
                        departure_city=arrival_city,
                        arrival_city=departure_city,
                        departure_date=return_date,
                        passengers=1,
                        currency="TRY",
                    )
            except Exception:
                pass

        # 3. Google Places: gezilecek yerler (kredi harcanmaz)
        places = []
        if GOOGLE_PLACES_API_KEY:
            try:
                city_name = _IATA_TO_CITY.get(arrival_city.upper(), arrival_city.lower())
                coords = CITY_COORDINATES.get(city_name)
                if coords:
                    lat, lng = coords
                    raw_places = await _fetch_places_from_google(lat, lng, radius=5000, max_results=20)
                    # Filtrele: min 3.0 puan + 25 değerlendirme
                    filtered = [
                        p for p in raw_places
                        if (p.get("rating") or 0) >= 3.0
                        and (p.get("userRatingsTotal") or 0) >= 25
                    ]
                    # Sırala: puan * log10(değerlendirme + 1) — büyükten küçüğe
                    filtered.sort(
                        key=lambda p: (p.get("rating") or 0) * math.log10((p.get("userRatingsTotal") or 0) + 1),
                        reverse=True,
                    )
                    places = filtered
            except Exception:
                pass

        # 4. SerpAPI: oteller (1 kredi)
        # Google Hotels IATA kodu anlamaz, şehir adı lazım
        hotel_city = _IATA_TO_CITY.get(arrival_city.upper(), arrival_city)
        hotels = []
        if SERPAPI_KEY and return_date:
            try:
                hotels = await _fetch_hotels_serpapi(
                    city=hotel_city,
                    check_in=departure_date,
                    check_out=return_date,
                    guests=1,
                    max_results=15,
                )
            except Exception:
                pass

        # 4. Geceleme sayısını hesapla
        nights = 1
        if return_date and departure_date:
            try:
                nights = (date.fromisoformat(return_date) - date.fromisoformat(departure_date)).days or 1
            except Exception:
                nights = 1

        # 5. Bütçeye göre en uygun seçimi belirle
        def _pick_cheapest_within(items, key, max_val):
            """Bütçeye sığan en ucuz seçeneği döndürür. Sığan yoksa None."""
            if not items:
                return None
            candidates = [x for x in items if (x.get(key) or 0) > 0]
            if max_val is not None:
                candidates = [x for x in candidates if (x.get(key) or 0) <= float(max_val)]
            if not candidates:
                return None
            return min(candidates, key=lambda x: x.get(key) or 0)

        if budget:
            remaining = float(budget)
            # Uçuşları ucuzdan pahalıya sırala
            flights_sorted = sorted(flights, key=lambda x: x.get("price") or 9999999)
            return_sorted = sorted(return_flights, key=lambda x: x.get("price") or 9999999)
            hotels_sorted = sorted(hotels, key=lambda x: x.get("pricePerNight") or 9999999)

            best_flight = _pick_cheapest_within(flights_sorted, "price", remaining)
            remaining -= (best_flight.get("price") or 0) if best_flight else 0

            best_return = _pick_cheapest_within(return_sorted, "price", remaining)
            remaining -= (best_return.get("price") or 0) if best_return else 0

            hotel_budget_per_night = remaining / nights if nights > 0 else remaining
            best_hotel = _pick_cheapest_within(hotels_sorted, "pricePerNight", hotel_budget_per_night)
        else:
            best_flight = flights[0] if flights else None
            best_return = return_flights[0] if return_flights else None
            best_hotel = hotels[0] if hotels else None

        # Toplam maliyet hesapla
        total_cost = (
            (best_flight.get("price") or 0 if best_flight else 0)
            + (best_return.get("price") or 0 if best_return else 0)
            + ((best_hotel.get("pricePerNight") or 0) * nights if best_hotel else 0)
        )

        summary = await _generate_plan_summary(
            departure_city=departure_city,
            arrival_city=arrival_city,
            departure_date=departure_date,
            return_date=return_date,
            best_flight=best_flight,
            best_return=best_return,
            best_hotel=best_hotel,
            budget=budget,
            total_cost=total_cost,
            nights=nights,
        )

        return {
            "status": "success",
            "response": summary,
            "plan_data": {
                "departure_city": departure_city,
                "arrival_city": arrival_city,
                "departure_date": departure_date,
                "return_date": return_date,
                "budget": budget,
                "total_cost": total_cost,
                "nights": nights,
                "best_flight": best_flight,
                "best_return_flight": best_return,
                "best_hotel": best_hotel,
                "all_flights": flights[:10],
                "all_return_flights": return_flights[:10],
                "all_hotels": hotels[:10],
                "all_places": places[:15],
            },
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}


async def _extract_plan_params(message: str, history: list) -> dict:
    """Gemini ile /plan mesajından seyahat parametrelerini çıkarır."""
    today_str = date.today().isoformat()

    system_prompt = f"""Sen bir seyahat planlama asistanısın. Kullanıcının mesajından seyahat bilgilerini çıkar.

Bugünün tarihi: {today_str}

JSON formatında yanıt ver, başka hiçbir şey yazma:
{{
  "departure_city": "IATA kodu veya şehir adı (örn: IST, Ankara)",
  "arrival_city": "IATA kodu veya şehir adı (örn: SAW, İstanbul)",
  "departure_date": "YYYY-MM-DD",
  "return_date": "YYYY-MM-DD veya null",
  "budget": null,
  "missing": false,
  "missing_message": ""
}}

"budget" alanı: kullanıcı bütçe belirttiyse sayısal TL değeri (örn: 3000), belirtmediyse null.
Bütçe örnekleri: "3000 TL", "3bin", "5000 lira", "bütçem 2500" → sayıya çevir.

Eğer kalkış şehri, varış şehri veya tarih eksikse:
{{
  "missing": true,
  "missing_message": "Hangi bilgilerin eksik olduğunu nazikçe Türkçe sor"
}}

Türkiye IATA kodları — sadece bunları kullan:
IST=İstanbul Atatürk, SAW=İstanbul Sabiha, ESB=Ankara, ADB=İzmir, AYT=Antalya,
TZX=Trabzon, ADA=Adana, BJV=Bodrum, DLM=Dalaman/Muğla, GZT=Gaziantep,
ASR=Kayseri, SZF=Samsun, ERZ=Erzurum, NAV=Nevşehir/Kapadokya, VAN=Van,
DIY=Diyarbakır, MLX=Malatya, KYA=Konya, MSR=Muş, AJI=Ağrı, NKT=Şırnak,
KCM=Kahramanmaraş, HTY=Hatay, GZP=Gazipaşa/Alanya, DNZ=Denizli, EDO=Balıkesir,
EZS=Elazığ, ERC=Erzincan, MQM=Mardin, GNY=Şanlıurfa/GAP, BAL=Batman,
OGU=Ordu-Giresun, RZV=Rize-Artvin, ISE=Isparta, CKZ=Çanakkale,
MZH=Amasya-Merzifon, TJK=Tokat, KFS=Kastamonu, KSY=Kars, BGG=Bingöl,
SXZ=Siirt, TEQ=Tekirdağ-Çorlu, ONQ=Zonguldak, USQ=Uşak, NOP=Sinop

ÖNEMLİ: Havalimanı olmayan şehirler için (Bursa, Kocaeli, Sakarya, Eskişehir vb.)
"missing: true" döndür ve kullanıcıya en yakın havalimanını belirt."""

    contents = []
    for msg in history[-6:]:
        role = "user" if msg.get("role") == "user" else "model"
        contents.append(Content(role=role, parts=[Part.from_text(msg.get("content", ""))]))
    contents.append(Content(role="user", parts=[Part.from_text(message)]))

    model = GenerativeModel("gemini-2.5-pro", system_instruction=system_prompt)
    response = await asyncio.get_event_loop().run_in_executor(
        None,
        lambda: model.generate_content(
            contents,
            generation_config={"temperature": 0.1, "max_output_tokens": 2048},
        ),
    )

    import json, re
    raw = response.text.strip()
    # Markdown kod bloğu varsa temizle
    raw = re.sub(r"^```[a-z]*\n?", "", raw)
    raw = re.sub(r"\n?```$", "", raw)
    raw = raw.strip()

    # { ile başlayan kısmı bul
    start = raw.find("{")
    if start == -1:
        return {"missing": True, "missing_message": "Anlayamadım, lütfen tekrar dener misin?"}
    raw = raw[start:]

    # Eksik kapanış parantezi varsa tamamla
    open_count = raw.count("{") - raw.count("}")
    if open_count > 0:
        # Yarım kalan son key-value'yu temizle: son virgül veya yarım satırı at
        raw = re.sub(r',\s*"[^"]*"\s*:?\s*[^,}\n]*$', "", raw, flags=re.DOTALL)
        raw = raw.rstrip().rstrip(",")
        raw += "}" * open_count

    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"missing": True, "missing_message": "Anlayamadım, lütfen tekrar dener misin?"}


async def _generate_plan_summary(
    departure_city: str,
    arrival_city: str,
    departure_date: str,
    return_date,
    best_flight,
    best_return,
    best_hotel,
    budget=None,
    total_cost=0,
    nights=1,
) -> str:
    """Gemini ile bulunan uçuş+otel için Türkçe özet üretir."""
    flight_info = ""
    if best_flight:
        flight_info += f"Gidiş uçuşu: {best_flight.get('airline','')}, {best_flight.get('departure_time','')} - {best_flight.get('arrival_time','')}, {best_flight.get('price','')} TL\n"
    if best_return:
        flight_info += f"Dönüş uçuşu: {best_return.get('airline','')}, {best_return.get('departure_time','')} - {best_return.get('arrival_time','')}, {best_return.get('price','')} TL\n"
    hotel_info = ""
    if best_hotel:
        hotel_info = f"Otel: {best_hotel.get('name','')}, {best_hotel.get('stars','')}⭐, gece {best_hotel.get('pricePerNight') or '?'} TL ({nights} gece = {(best_hotel.get('pricePerNight') or 0)*nights} TL)\n"

    if not flight_info and not hotel_info:
        return f"✈️ {departure_city} → {arrival_city} için {departure_date} tarihli uçuş ve otel araması yapıldı ancak sonuç bulunamadı. Tarihleri veya şehirleri değiştirerek tekrar deneyebilirsin."

    budget_info = ""
    if budget:
        fits = total_cost <= budget
        budget_info = f"\nKullanıcının bütçesi: {budget} TL\nToplam tahmini maliyet: {total_cost} TL\nBütçeye {'✅ sığıyor' if fits else '❌ sığmıyor'}"

    prompt = f"""Kullanıcı {departure_city}'dan {arrival_city}'a {departure_date} tarihli seyahat planı istedi.
{'Dönüş tarihi: ' + return_date + ' (' + str(nights) + ' gece)' if return_date else 'Tek yön'}

Bulunan en iyi seçenekler:
{flight_info}{hotel_info}{budget_info}

Bunu kısa, samimi ve Türkçe olarak özetle. 2-3 cümle yeterli. Fiyatları ve toplam maliyeti belirt.
{'Bütçeye sığıp sığmadığını açıkça belirt.' if budget else ''}
Sonuna "Planı kaydetmek ister misin?" diye sor."""

    model = GenerativeModel("gemini-2.5-pro")
    response = await asyncio.get_event_loop().run_in_executor(
        None,
        lambda: model.generate_content(
            prompt,
            generation_config={"temperature": 0.7, "max_output_tokens": 512},
        ),
    )
    return response.text.strip()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8004)
