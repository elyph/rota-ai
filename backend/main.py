from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import httpx
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

GOOGLE_PLACES_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY", "")

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
    "lefkoşa": (35.1856, 33.3823),
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
    filter_type: str = "all"  # all, tourist, food, nature, historical, shopping, entertainment

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

@app.post("/nearby-places")
async def get_nearby_places(request: PlaceRequest):
    city_lower = request.city.lower().strip()
    
    if city_lower not in CITY_COORDINATES:
        return {"status": "error", "message": f"'{request.city}' şehri bulunamadı.", "places": []}
    
    lat, lng = CITY_COORDINATES[city_lower]
    
    if not GOOGLE_PLACES_API_KEY:
        # API key yoksa mock veri döndür
        places = _get_mock_places(request.city)
        # Filtreleme uygula
        if request.filter_type != "all":
            places = _filter_places(places, request.filter_type)
        return {
            "status": "success",
            "places": places,
            "source": "mock"
        }
    
    try:
        places = await _fetch_places_from_google(lat, lng, request.radius, request.max_results)
        return {"status": "success", "places": places, "source": "google_places"}
    except Exception as e:
        return {"status": "error", "message": str(e), "places": []}

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
            photo_url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference={photo_ref}&key={GOOGLE_PLACES_API_KEY}"
        
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

def _filter_places(places: list, filter_type: str) -> list:
    """Yerleri filtre türüne göre filtreler."""
    filter_map = {
        "tourist": {
            "types": ["tourist_attraction", "museum", "art_gallery", "landmark"],
            "label": "Turistik"
        },
        "food": {
            "types": ["restaurant", "cafe", "bakery", "bar", "meal_takeaway", "food"],
            "label": "Yeme-İçme"
        },
        "nature": {
            "types": ["park", "natural_feature", "campground", "beach"],
            "label": "Doğal"
        },
        "historical": {
            "types": ["historical_place", "museum", "church", "mosque", "synagogue", "hindu_temple", "landmark"],
            "label": "Tarihi"
        },
        "shopping": {
            "types": ["shopping_mall", "store", "clothing_store", "electronics_store", "book_store"],
            "label": "Alışveriş"
        },
        "entertainment": {
            "types": ["amusement_park", "zoo", "aquarium", "night_club", "casino", "bowling_alley", "movie_theater"],
            "label": "Eğlence"
        },
    }
    
    if filter_type not in filter_map:
        return places
    
    allowed_types = filter_map[filter_type]["types"]
    filtered = []
    
    for place in places:
        place_types = place.get("types", [])
        # Eğer yerin türlerinden biri allowed_types içinde varsa ekle
        if any(t in allowed_types for t in place_types):
            filtered.append(place)
    
    return filtered

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
