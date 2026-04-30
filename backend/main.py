from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import httpx
import os
from dotenv import load_dotenv
import asyncio

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
    "adana": (37.0000, 35.3213),
    "adiyaman": (37.7644, 38.2764),
    "afyonkarahisar": (38.7568, 30.5387),
    "ağrı": (39.7191, 43.0503),
    "amasya": (40.6499, 35.8322),
    "ankara": (39.9334, 32.8597),
    "antalya": (36.8841, 30.7056),
    "artvin": (41.1828, 41.8183),
    "aydın": (37.8560, 27.8416),
    "balıkesir": (39.6484, 27.8826),
    "bilecik": (40.1451, 29.9799),
    "bingöl": (38.8855, 40.4966),
    "bitlis": (38.4000, 42.1000),
    "bolu": (40.7359, 31.6061),
    "burdur": (37.7204, 30.2908),
    "bursa": (40.1826, 29.0669),
    "çanakkale": (40.1553, 26.4142),
    "çankırı": (40.6013, 33.6134),
    "çorum": (40.5506, 34.9556),
    "denizli": (37.7765, 29.0864),
    "diyarbakır": (37.9144, 40.2306),
    "edirne": (41.6771, 26.5557),
    "elazığ": (38.6810, 39.2264),
    "erzincan": (39.7500, 39.5000),
    "erzurum": (39.9043, 41.2679),
    "eskişehir": (39.7667, 30.5256),
    "gaziantep": (37.0662, 37.3833),
    "giresun": (40.9128, 38.3895),
    "gümüşhane": (40.4600, 39.4800),
    "hakkari": (37.5833, 43.7333),
    "hatay": (36.4018, 36.3498),
    "ığdır": (39.9208, 44.0450),
    "ısparta": (37.7648, 30.5566),
    "istanbul": (41.0082, 28.9784),
    "izmir": (38.4192, 27.1287),
    "kahramanmaraş": (37.5858, 36.9371),
    "karabük": (41.2061, 32.6200),
    "karaman": (37.1811, 33.2150),
    "kars": (40.6167, 43.1000),
    "kastamonu": (41.3887, 33.7827),
    "kayseri": (38.7312, 35.4787),
    "kırıkkale": (39.8468, 33.5153),
    "kırklareli": (41.7333, 27.2167),
    "kırşehir": (39.1461, 34.1606),
    "kocaeli": (40.7654, 29.9408),
    "konya": (37.8746, 32.4932),
    "kütahya": (39.4167, 29.9833),
    "malatya": (38.3552, 38.3095),
    "manisa": (38.6191, 27.4289),
    "mardin": (37.3122, 40.7351),
    "mersin": (36.8000, 34.6333),
    "muğla": (37.2153, 28.3636),
    "muş": (38.7433, 41.5064),
    "nevşehir": (38.6244, 34.7239),
    "niğde": (37.9667, 34.6833),
    "ordu": (40.9839, 37.8764),
    "osmaniye": (37.0742, 36.2464),
    "rize": (41.0201, 40.5234),
    "sakarya": (40.7569, 30.3781),
    "samsun": (41.2867, 36.3300),
    "siirt": (37.9333, 41.9500),
    "sinop": (42.0264, 35.1551),
    "sivas": (39.7477, 37.0179),
    "şanlıurfa": (37.1591, 38.7969),
    "şırnak": (37.5167, 42.4500),
    "tekirdağ": (40.9833, 27.5167),
    "tokat": (40.3167, 36.5500),
    "trabzon": (41.0027, 39.7168),
    "tunceli": (39.1079, 39.5401),
    "uşak": (38.6823, 29.4082),
    "van": (38.4891, 43.4089),
    "yalova": (40.6550, 29.2769),
    "yozgat": (39.8181, 34.8147),
    "zonguldak": (41.4564, 31.7987),
    "lefkoşa": (35.1856, 33.3823),
}

class TravelRequest(BaseModel):
    city: str
    budget: float
    days: int

class PlaceRequest(BaseModel):
    city: str
    radius: int = 5000
    max_results: int = 15
    filter_type: str = "all"

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
        return {"status": "error", "message": "Google Places API anahtarı bulunamadı.", "places": []}
    
    try:
        places = await _fetch_places_from_google(lat, lng, request.radius, request.max_results)
        
        # Popülerlik skoruna göre sırala (rating * userRatingsTotal)
        places.sort(key=lambda p: p.get("rating", 0) * p.get("userRatingsTotal", 0), reverse=True)
        
        # Filtreleme uygula
        if request.filter_type != "all":
            places = _filter_places(places, request.filter_type)
        
        return {"status": "success", "places": places, "source": "google_places"}
    except Exception as e:
        return {"status": "error", "message": str(e), "places": []}

async def _fetch_places_from_google(lat: float, lng: float, radius: int, max_results: int):
    """Google Places API'den tüm kategorilerdeki yerleri çeker ve popülerlik skoruna göre sıralar."""
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    
    # Tüm kategorilerde ara
    search_types = [
        "tourist_attraction",
        "museum",
        "park",
        "restaurant",
        "shopping_mall",
        "amusement_park",
        "night_club",
        "art_gallery",
        "landmark",
        "natural_feature",
        "mosque",
        "church",
        "historical_place",
        "cafe",
        "bar",
    ]
    
    all_places = []
    seen_ids = set()
    
    async with httpx.AsyncClient() as client:
        for search_type in search_types:
            params = {
                "location": f"{lat},{lng}",
                "radius": radius,
                "type": search_type,
                "key": GOOGLE_PLACES_API_KEY,
                "language": "tr",
            }
            
            try:
                response = await client.get(url, params=params)
                data = response.json()
                
                if data.get("status") == "OK":
                    for place in data.get("results", []):
                        place_id = place.get("place_id", "")
                        if place_id and place_id not in seen_ids:
                            seen_ids.add(place_id)
                            
                            photo_url = ""
                            if "photos" in place and len(place["photos"]) > 0:
                                photo_ref = place["photos"][0]["photo_reference"]
                                photo_url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference={photo_ref}&key={GOOGLE_PLACES_API_KEY}"
                            
                            all_places.append({
                                "id": place_id,
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
            except:
                pass
    
    # Popülerlik skoruna göre sırala (rating * userRatingsTotal)
    all_places.sort(key=lambda p: p.get("rating", 0) * p.get("userRatingsTotal", 0), reverse=True)
    
    return all_places[:max_results]

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
    generic_types = {"tourist_attraction", "point_of_interest", "establishment", "lodging"}
    
    filtered = []
    
    for place in places:
        place_types = place.get("types", [])
        place_type_set = set(place_types)
        specific_types = place_type_set - generic_types
        
        if not specific_types:
            continue
        
        if any(t in allowed_types for t in specific_types):
            filtered.append(place)
    
    return filtered

@app.get("/cities")
async def get_cities():
    """Tüm Türkiye şehirlerinin listesini döndürür."""
    cities = [
        {"name": "Adana", "key": "adana"},
        {"name": "Adıyaman", "key": "adiyaman"},
        {"name": "Afyonkarahisar", "key": "afyonkarahisar"},
        {"name": "Ağrı", "key": "ağrı"},
        {"name": "Amasya", "key": "amasya"},
        {"name": "Ankara", "key": "ankara"},
        {"name": "Antalya", "key": "antalya"},
        {"name": "Artvin", "key": "artvin"},
        {"name": "Aydın", "key": "aydın"},
        {"name": "Balıkesir", "key": "balıkesir"},
        {"name": "Bilecik", "key": "bilecik"},
        {"name": "Bingöl", "key": "bingöl"},
        {"name": "Bitlis", "key": "bitlis"},
        {"name": "Bolu", "key": "bolu"},
        {"name": "Burdur", "key": "burdur"},
        {"name": "Bursa", "key": "bursa"},
        {"name": "Çanakkale", "key": "çanakkale"},
        {"name": "Çankırı", "key": "çankırı"},
        {"name": "Çorum", "key": "çorum"},
        {"name": "Denizli", "key": "denizli"},
        {"name": "Diyarbakır", "key": "diyarbakır"},
        {"name": "Edirne", "key": "edirne"},
        {"name": "Elazığ", "key": "elazığ"},
        {"name": "Erzincan", "key": "erzincan"},
        {"name": "Erzurum", "key": "erzurum"},
        {"name": "Eskişehir", "key": "eskişehir"},
        {"name": "Gaziantep", "key": "gaziantep"},
        {"name": "Giresun", "key": "giresun"},
        {"name": "Gümüşhane", "key": "gümüşhane"},
        {"name": "Hakkari", "key": "hakkari"},
        {"name": "Hatay", "key": "hatay"},
        {"name": "Iğdır", "key": "ığdır"},
        {"name": "Isparta", "key": "ısparta"},
        {"name": "İstanbul", "key": "istanbul"},
        {"name": "İzmir", "key": "izmir"},
        {"name": "Kahramanmaraş", "key": "kahramanmaraş"},
        {"name": "Karabük", "key": "karabük"},
        {"name": "Karaman", "key": "karaman"},
        {"name": "Kars", "key": "kars"},
        {"name": "Kastamonu", "key": "kastamonu"},
        {"name": "Kayseri", "key": "kayseri"},
        {"name": "Kırıkkale", "key": "kırıkkale"},
        {"name": "Kırklareli", "key": "kırklareli"},
        {"name": "Kırşehir", "key": "kırşehir"},
        {"name": "Kocaeli", "key": "kocaeli"},
        {"name": "Konya", "key": "konya"},
        {"name": "Kütahya", "key": "kütahya"},
        {"name": "Malatya", "key": "malatya"},
        {"name": "Manisa", "key": "manisa"},
        {"name": "Mardin", "key": "mardin"},
        {"name": "Mersin", "key": "mersin"},
        {"name": "Muğla", "key": "muğla"},
        {"name": "Muş", "key": "muş"},
        {"name": "Nevşehir", "key": "nevşehir"},
        {"name": "Niğde", "key": "niğde"},
        {"name": "Ordu", "key": "ordu"},
        {"name": "Osmaniye", "key": "osmaniye"},
        {"name": "Rize", "key": "rize"},
        {"name": "Sakarya", "key": "sakarya"},
        {"name": "Samsun", "key": "samsun"},
        {"name": "Siirt", "key": "siirt"},
        {"name": "Sinop", "key": "sinop"},
        {"name": "Sivas", "key": "sivas"},
        {"name": "Şanlıurfa", "key": "şanlıurfa"},
        {"name": "Şırnak", "key": "şırnak"},
        {"name": "Tekirdağ", "key": "tekirdağ"},
        {"name": "Tokat", "key": "tokat"},
        {"name": "Trabzon", "key": "trabzon"},
        {"name": "Tunceli", "key": "tunceli"},
        {"name": "Uşak", "key": "uşak"},
        {"name": "Van", "key": "van"},
        {"name": "Yalova", "key": "yalova"},
        {"name": "Yozgat", "key": "yozgat"},
        {"name": "Zonguldak", "key": "zonguldak"},
    ]
    return {"status": "success", "cities": cities}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
