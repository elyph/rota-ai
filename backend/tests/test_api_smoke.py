import pytest


class TestHealthAndCities:
    def test_get_cities_returns_list(self, client):
        response = client.get("/cities")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert isinstance(data["cities"], list)
        assert len(data["cities"]) == 16

    def test_get_cities_contains_istanbul(self, client):
        response = client.get("/cities")
        cities = response.json()["cities"]
        names = [c["name"] for c in cities]
        assert "İstanbul" in names
        assert "Ankara" in names

    def test_get_cities_keys_format(self, client):
        response = client.get("/cities")
        cities = response.json()["cities"]
        for c in cities:
            assert "name" in c
            assert "key" in c
            assert isinstance(c["key"], str)
            assert c["key"] == c["key"].lower()


class TestGeneratePlan:
    def test_generate_plan_success(self, client):
        response = client.post("/generate-plan", json={
            "city": "İstanbul",
            "budget": 10000,
            "days": 5,
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert "plan" in data
        assert "details" in data
        assert len(data["details"]) == 4

    def test_generate_plan_details_sum_equals_budget(self, client):
        response = client.post("/generate-plan", json={
            "city": "Ankara",
            "budget": 5000,
            "days": 3,
        })
        data = response.json()
        total = sum(item["price"] for item in data["details"])
        assert pytest.approx(total, 0.01) == 5000

    def test_generate_plan_details_have_categories(self, client):
        response = client.post("/generate-plan", json={
            "city": "İzmir",
            "budget": 3000,
            "days": 2,
        })
        data = response.json()
        categories = [item["item"] for item in data["details"]]
        assert len(categories) == 4


class TestNearbyPlacesWithoutKeys:
    def test_nearby_places_without_api_key_returns_mock(self, client):
        response = client.post("/nearby-places", json={
            "city": "istanbul",
            "radius": 5000,
            "max_results": 15,
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["source"] == "mock"
        assert len(data["places"]) >= 1

    def test_nearby_places_unknown_city(self, client):
        response = client.post("/nearby-places", json={"city": "mars"})
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "error"
        assert "bulunamadı" in data["message"]

    def test_nearby_places_lowercase_city_works(self, client):
        response = client.post("/nearby-places", json={"city": "istanbul"})
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"


class TestPlacePhotoWithoutKeys:
    def test_place_photo_without_reference_returns_404(self, client):
        response = client.get("/place-photo")
        assert response.status_code == 404

    def test_place_photo_with_empty_reference(self, client):
        response = client.get("/place-photo", params={"photo_reference": ""})
        assert response.status_code == 404

    def test_place_photo_without_api_key_returns_404(self, client):
        response = client.get("/place-photo", params={
            "photo_reference": "some_ref",
            "maxwidth": 400,
        })
        assert response.status_code == 404


class TestPopularPlacesWithoutKeys:
    def test_popular_places_without_api_key_returns_fallback(self, client):
        response = client.get("/popular-places")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["source"] == "fallback"
        assert len(data["places"]) == 10

    def test_popular_places_fallback_cappadocia_first(self, client):
        response = client.get("/popular-places")
        data = response.json()
        assert data["places"][0]["name"] == "Kapadokya"


class TestFlightsWithoutApiKey:
    def test_search_flights_without_key_returns_error(self, client):
        response = client.post("/search-flights", json={
            "departure_city": "İstanbul",
            "arrival_city": "Ankara",
            "departure_date": "2025-06-15",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "error"

    def test_search_flights_round_trip_without_key(self, client):
        response = client.post("/search-flights", json={
            "departure_city": "İstanbul",
            "arrival_city": "İzmir",
            "departure_date": "2025-07-01",
            "return_date": "2025-07-07",
            "passengers": 2,
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "error"


class TestHotelsWithoutApiKey:
    def test_search_hotels_without_key_returns_error(self, client):
        response = client.post("/search-hotels", json={
            "city": "Antalya",
            "check_in": "2025-06-01",
            "check_out": "2025-06-05",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "error"


class TestGenerateItinerary:
    def test_generate_itinerary_basic(self, client):
        response = client.post("/generate-itinerary", json={
            "departure_city": "İstanbul",
            "arrival_city": "Ankara",
            "departure_date": "2025-06-10",
            "return_date": "2025-06-12",
            "hotel_name": "Test Otel",
            "selected_places": [{"name": "Anıtkabir", "address": "Çankaya"}],
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert "itinerary" in data

    def test_generate_itinerary_without_return_date(self, client):
        response = client.post("/generate-itinerary", json={
            "departure_city": "İstanbul",
            "arrival_city": "İzmir",
            "departure_date": "2025-08-01",
        })
        assert response.status_code == 200
        assert response.json()["status"] == "success"


class TestChat:
    def test_chat_basic(self, client):
        response = client.post("/chat", json={
            "message": "Antalya'da nereleri gezmeliyim?",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert "response" in data

    def test_chat_with_history(self, client):
        response = client.post("/chat", json={
            "message": "Peki otel önerir misin?",
            "history": [
                {"role": "user", "content": "Nereye gitmeliyim?"},
                {"role": "assistant", "content": "Antalya güzel olur."},
            ],
        })
        assert response.status_code == 200
        assert response.json()["status"] == "success"

    def test_chat_with_user_plans(self, client):
        response = client.post("/chat", json={
            "message": "Planımı değerlendir",
            "user_plans": [
                {"title": "Antalya Gezisi", "departure_city": "İstanbul", "arrival_city": "Antalya", "departure_date": "2025-07-01"},
            ],
        })
        assert response.status_code == 200


class TestCORSMiddleware:
    def test_options_request_returns_204(self, client):
        response = client.options(
            "/cities",
            headers={"origin": "http://localhost:3000"},
        )
        assert response.status_code == 204

    def test_cors_headers_present(self, client):
        response = client.get(
            "/cities",
            headers={"origin": "http://localhost:3000"},
        )
        assert "access-control-allow-origin" in response.headers
        assert response.headers["access-control-allow-origin"] == "http://localhost:3000"

    def test_no_origin_returns_no_cors_headers(self, client):
        response = client.get("/cities")
        assert "access-control-allow-origin" not in response.headers


class TestErrorHandling:
    def test_nonexistent_endpoint_returns_404(self, client):
        response = client.get("/nonexistent")
        assert response.status_code == 404

    def test_generate_plan_invalid_json_returns_422(self, client):
        response = client.post("/generate-plan", json={})
        assert response.status_code == 422
