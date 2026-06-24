import pytest
import sys
import os
from unittest.mock import patch, AsyncMock, MagicMock

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class TestGeneratePlanBudgetLogic:
    def test_budget_split_percentages(self, client):
        response = client.post("/generate-plan", json={"city": "İstanbul", "budget": 10000, "days": 5})
        data = response.json()
        details = {item["item"]: item["price"] for item in data["details"]}
        assert details["🏨 Konaklama"] == pytest.approx(4000.0)
        assert details["🚕 Ulaşım"] == pytest.approx(2000.0)
        assert details["📸 Gezilecek Yerler"] == pytest.approx(1000.0)
        assert details["🍔 Yeme - İçme"] == pytest.approx(3000.0)

    def test_budget_split_small_amount(self, client):
        response = client.post("/generate-plan", json={"city": "Ankara", "budget": 100, "days": 1})
        data = response.json()
        total = sum(item["price"] for item in data["details"])
        assert total == pytest.approx(100.0)

    def test_budget_split_fractional_amount(self, client):
        response = client.post("/generate-plan", json={"city": "İzmir", "budget": 333.33, "days": 2})
        data = response.json()
        total = sum(item["price"] for item in data["details"])
        assert total == pytest.approx(333.33, abs=0.01)

    def test_budget_zero(self, client):
        response = client.post("/generate-plan", json={"city": "Antalya", "budget": 0, "days": 1})
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        for item in data["details"]:
            assert item["price"] == 0.0

    def test_budget_large_amount(self, client):
        response = client.post("/generate-plan", json={"city": "İstanbul", "budget": 1000000, "days": 30})
        data = response.json()
        assert data["status"] == "success"
        total = sum(item["price"] for item in data["details"])
        assert total == pytest.approx(1000000.0)

    def test_plan_message_includes_city_and_days(self, client):
        response = client.post("/generate-plan", json={"city": "Trabzon", "budget": 5000, "days": 7})
        data = response.json()
        assert "Trabzon" in data["plan"]
        assert "7" in data["plan"]
        assert "5000" in data["plan"]

    def test_plan_always_has_4_categories(self, client):
        for budget in [500, 2000, 50000]:
            response = client.post("/generate-plan", json={"city": "Bursa", "budget": budget, "days": 3})
            data = response.json()
            assert len(data["details"]) == 4

    def test_missing_budget_returns_422(self, client):
        response = client.post("/generate-plan", json={"city": "Ankara", "days": 3})
        assert response.status_code == 422

    def test_missing_city_returns_422(self, client):
        response = client.post("/generate-plan", json={"budget": 5000, "days": 3})
        assert response.status_code == 422

    def test_missing_days_returns_422(self, client):
        response = client.post("/generate-plan", json={"city": "Ankara", "budget": 5000})
        assert response.status_code == 422

    def test_negative_budget_is_accepted(self, client):
        # Pydantic float accepts negatives; uygulama bunu reddetmiyor
        response = client.post("/generate-plan", json={"city": "İstanbul", "budget": -1000, "days": 3})
        assert response.status_code == 200
        data = response.json()
        total = sum(item["price"] for item in data["details"])
        assert total == pytest.approx(-1000.0)


class TestNearbyPlacesErrorPaths:
    def test_unknown_city_returns_error_status(self, client):
        response = client.post("/nearby-places", json={"city": "xyz_bilinmeyen"})
        data = response.json()
        assert data["status"] == "error"
        assert response.status_code == 200

    def test_empty_city_string_returns_error(self, client):
        response = client.post("/nearby-places", json={"city": ""})
        data = response.json()
        assert data["status"] == "error"

    def test_places_field_present_on_error(self, client):
        response = client.post("/nearby-places", json={"city": "bilinmeyen"})
        data = response.json()
        assert "places" in data
        assert isinstance(data["places"], list)

    def test_error_message_contains_city_name(self, client):
        response = client.post("/nearby-places", json={"city": "atlantis"})
        data = response.json()
        assert "atlantis" in data["message"]

    def test_case_insensitive_known_city(self, client):
        response = client.post("/nearby-places", json={"city": "ISTANBUL"})
        data = response.json()
        assert data["status"] == "success"

    def test_city_with_whitespace(self, client):
        response = client.post("/nearby-places", json={"city": "  istanbul  "})
        data = response.json()
        assert data["status"] == "success"


class TestFlightsErrorPaths:
    def test_search_flights_missing_departure_city(self, client):
        response = client.post("/search-flights", json={
            "arrival_city": "Ankara",
            "departure_date": "2025-06-15",
        })
        assert response.status_code == 422

    def test_search_flights_missing_arrival_city(self, client):
        response = client.post("/search-flights", json={
            "departure_city": "İstanbul",
            "departure_date": "2025-06-15",
        })
        assert response.status_code == 422

    def test_search_flights_missing_date(self, client):
        response = client.post("/search-flights", json={
            "departure_city": "İstanbul",
            "arrival_city": "Ankara",
        })
        assert response.status_code == 422

    def test_search_flights_without_api_key_returns_error_not_500(self, client):
        response = client.post("/search-flights", json={
            "departure_city": "İstanbul",
            "arrival_city": "Ankara",
            "departure_date": "2025-06-15",
        })
        assert response.status_code == 200
        assert response.json()["status"] == "error"

    def test_search_flights_response_has_no_flights_key_on_error(self, client):
        response = client.post("/search-flights", json={
            "departure_city": "İstanbul",
            "arrival_city": "Ankara",
            "departure_date": "2025-06-15",
        })
        data = response.json()
        # error durumunda flights key bulunmamalı
        assert "message" in data


class TestHotelsErrorPaths:
    def test_search_hotels_missing_city(self, client):
        response = client.post("/search-hotels", json={
            "check_in": "2025-06-01",
            "check_out": "2025-06-05",
        })
        assert response.status_code == 422

    def test_search_hotels_missing_check_in(self, client):
        response = client.post("/search-hotels", json={
            "city": "Antalya",
            "check_out": "2025-06-05",
        })
        assert response.status_code == 422

    def test_search_hotels_without_api_key_not_500(self, client):
        response = client.post("/search-hotels", json={
            "city": "İstanbul",
            "check_in": "2025-06-01",
            "check_out": "2025-06-05",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "error"


class TestGenerateItineraryEdgeCases:
    def test_itinerary_one_day_trip(self, client):
        response = client.post("/generate-itinerary", json={
            "departure_city": "İstanbul",
            "arrival_city": "Ankara",
            "departure_date": "2025-06-10",
        })
        assert response.status_code == 200
        assert response.json()["status"] == "success"

    def test_itinerary_with_all_optional_fields(self, client):
        response = client.post("/generate-itinerary", json={
            "departure_city": "İstanbul",
            "arrival_city": "Antalya",
            "departure_date": "2025-07-01",
            "return_date": "2025-07-05",
            "hotel_name": "Rixos Premium",
            "selected_places": [
                {"name": "Kaleiçi", "address": "Muratpaşa"},
                {"name": "Düden Şelalesi", "address": "Düdenbaşı"},
            ],
            "flight_airline": "THY",
            "flight_departure_time": "08:00",
            "return_flight_airline": "Pegasus",
            "return_flight_departure_time": "22:00",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert "itinerary" in data

    def test_itinerary_missing_departure_city_returns_422(self, client):
        response = client.post("/generate-itinerary", json={
            "arrival_city": "Ankara",
            "departure_date": "2025-06-10",
        })
        assert response.status_code == 422

    def test_itinerary_response_contains_gemini_mock_text(self, client):
        response = client.post("/generate-itinerary", json={
            "departure_city": "İstanbul",
            "arrival_city": "Ankara",
            "departure_date": "2025-06-10",
        })
        data = response.json()
        # conftest'te mock "## 1. Gün\nTest itinerary" döndürüyor
        assert "1. Gün" in data["itinerary"]


class TestChatErrorPaths:
    def test_chat_empty_message(self, client):
        response = client.post("/chat", json={"message": ""})
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"

    def test_chat_missing_message_returns_422(self, client):
        response = client.post("/chat", json={})
        assert response.status_code == 422

    def test_chat_very_long_message(self, client):
        long_message = "Antalya " * 500
        response = client.post("/chat", json={"message": long_message})
        assert response.status_code == 200

    def test_chat_history_with_invalid_role_still_works(self, client):
        response = client.post("/chat", json={
            "message": "Merhaba",
            "history": [
                {"role": "unknown_role", "content": "test"},
            ],
        })
        assert response.status_code == 200

    def test_chat_with_max_history_items(self, client):
        history = [{"role": "user" if i % 2 == 0 else "assistant", "content": f"msg {i}"} for i in range(20)]
        response = client.post("/chat", json={"message": "Son soru", "history": history})
        assert response.status_code == 200
        assert response.json()["status"] == "success"


class TestFetchPlacesFromGoogleErrorPaths:
    @pytest.mark.asyncio
    async def test_network_exception_propagates(self):
        mock_client = MagicMock()
        mock_client.get = AsyncMock(side_effect=Exception("Connection refused"))
        mock_client_class = MagicMock()
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client)

        from main import _fetch_places_from_google
        with patch("main.httpx.AsyncClient", return_value=mock_client_class), \
             patch("main.GOOGLE_PLACES_API_KEY", "test_key"):
            with pytest.raises(Exception, match="Connection refused"):
                await _fetch_places_from_google(41.0, 29.0, 5000, 15)

    @pytest.mark.asyncio
    async def test_missing_geometry_defaults_to_zero(self):
        mock_response_data = {
            "status": "OK",
            "results": [
                {
                    "place_id": "no_geom",
                    "name": "No Geometry Place",
                    "vicinity": "Addr",
                    "rating": 4.0,
                    "user_ratings_total": 10,
                    "types": ["tourist_attraction"],
                    # geometry anahtarı yok
                },
            ],
        }
        mock_response = MagicMock()
        mock_response.json = MagicMock(return_value=mock_response_data)
        mock_client = MagicMock()
        mock_client.get = AsyncMock(return_value=mock_response)
        mock_client_class = MagicMock()
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client)

        from main import _fetch_places_from_google
        with patch("main.httpx.AsyncClient", return_value=mock_client_class), \
             patch("main.GOOGLE_PLACES_API_KEY", "test_key"):
            result = await _fetch_places_from_google(41.0, 29.0, 5000, 15)

        assert result[0]["latitude"] == 0
        assert result[0]["longitude"] == 0

    @pytest.mark.asyncio
    async def test_openNow_none_when_no_opening_hours(self):
        mock_response_data = {
            "status": "OK",
            "results": [
                {
                    "place_id": "p1",
                    "name": "Place",
                    "vicinity": "Addr",
                    "rating": 4.0,
                    "user_ratings_total": 10,
                    "types": ["tourist_attraction"],
                    "geometry": {"location": {"lat": 41.0, "lng": 29.0}},
                    # opening_hours yok
                },
            ],
        }
        mock_response = MagicMock()
        mock_response.json = MagicMock(return_value=mock_response_data)
        mock_client = MagicMock()
        mock_client.get = AsyncMock(return_value=mock_response)
        mock_client_class = MagicMock()
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client_class)
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client)

        from main import _fetch_places_from_google
        with patch("main.httpx.AsyncClient", return_value=mock_client_class), \
             patch("main.GOOGLE_PLACES_API_KEY", "test_key"):
            result = await _fetch_places_from_google(41.0, 29.0, 5000, 15)

        assert result[0]["openNow"] is None
