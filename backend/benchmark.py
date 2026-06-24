import sys
import os
import time
from fastapi.testclient import TestClient

# Add current directory to path to import main
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from main import app
except Exception as e:
    print(f"Error importing main.py: {e}")
    sys.exit(1)

client = TestClient(app)

def run_benchmark():
    print("=" * 60)
    print("ROTA AI - BACKEND ENDPOINT PERFORMANCE BENCHMARK")
    print("=" * 60)
    print("Starting tests... Please wait as some APIs make live network requests.\n")

    endpoints = [
        {
            "name": "/cities (Desteklenen Şehirler)",
            "method": "GET",
            "url": "/cities",
            "payload": None
        },
        {
            "name": "/popular-places (Popüler Yerler - Google Places)",
            "method": "GET",
            "url": "/popular-places",
            "payload": None
        },
        {
            "name": "/nearby-places (Yakın Gezilecek Yerler - İstanbul)",
            "method": "POST",
            "url": "/nearby-places",
            "payload": {
                "city": "istanbul",
                "radius": 5000,
                "max_results": 15
            }
        },
        {
            "name": "/search-flights (Uçuş Arama - SerpAPI)",
            "method": "POST",
            "url": "/search-flights",
            "payload": {
                "departure_city": "IST",
                "arrival_city": "ESB",
                "departure_date": "2026-07-01",
                "passengers": 1
            }
        },
        {
            "name": "/search-hotels (Otel Arama - SerpAPI)",
            "method": "POST",
            "url": "/search-hotels",
            "payload": {
                "city": "Antalya",
                "check_in": "2026-07-01",
                "check_out": "2026-07-05",
                "guests": 1,
                "max_results": 10
            }
        },
        {
            "name": "/chat (Yapay Zeka Chat Asistanı - Gemini)",
            "method": "POST",
            "url": "/chat",
            "payload": {
                "message": "Antalya seyahati için kısa bir ipucu ver.",
                "history": []
            }
        },
        {
            "name": "/generate-itinerary (Detaylı Plan Oluşturma - Gemini)",
            "method": "POST",
            "url": "/generate-itinerary",
            "payload": {
                "departure_city": "İstanbul",
                "arrival_city": "Ankara",
                "departure_date": "2026-07-01",
                "return_date": "2026-07-03",
                "hotel_name": "Divan Ankara",
                "selected_places": [{"name": "Anıtkabir", "address": "Çankaya"}]
            }
        }
    ]

    results = []

    for ep in endpoints:
        print(f"Testing: {ep['name']} ...")
        durations = []
        status_ok = True
        error_msg = ""
        
        # Run 3 times to get an average
        for i in range(3):
            start_time = time.perf_counter()
            try:
                if ep["method"] == "GET":
                    response = client.get(ep["url"])
                else:
                    response = client.post(ep["url"], json=ep["payload"])
                
                end_time = time.perf_counter()
                elapsed = end_time - start_time
                durations.append(elapsed)
                
                if response.status_code != 200:
                    status_ok = False
                    error_msg = f"HTTP {response.status_code}: {response.text[:100]}"
                else:
                    data = response.json()
                    if data.get("status") == "error":
                        # Some endpoints return 200 with {"status": "error"}
                        status_ok = False
                        error_msg = data.get("message", "API returned status: error")[:100]
            except Exception as ex:
                status_ok = False
                error_msg = str(ex)[:100]
                break
        
        if status_ok and durations:
            avg_time = sum(durations) / len(durations)
            results.append({
                "name": ep["name"],
                "status": "SUCCESS",
                "avg_time": f"{avg_time:.3f} s",
                "details": f"Runs: {[f'{d:.3f}s' for d in durations]}"
            })
        else:
            results.append({
                "name": ep["name"],
                "status": "FAILED / MOCKED",
                "avg_time": "N/A",
                "details": error_msg or "Failed to execute"
            })
            
    print("\n" + "=" * 60)
    print("BENCHMARK RESULTS SUMMARY")
    print("=" * 60)
    print(f"{'Endpoint':<45} | {'Status':<10} | {'Avg Time':<10}")
    print("-" * 71)
    for r in results:
        print(f"{r['name'][:44]:<45} | {r['status']:<10} | {r['avg_time']:<10}")
        if r['status'] != "SUCCESS":
            print(f"  └─ Note: {r['details']}")
    print("=" * 71)
    print("\nUse the SUCCESSFUL live values above for your Poster's 'Tablo 1' section.")
    print("If an endpoint failed (e.g. SerpAPI rate limit or Vertex AI credential error),")
    print("it might fall back or return an error. You can run this under your local environment.")

if __name__ == "__main__":
    run_benchmark()
