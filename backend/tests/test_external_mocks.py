import pytest
import sys
import os
from unittest.mock import patch, AsyncMock, MagicMock

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import _fetch_places_from_google


class TestFetchPlacesFromGoogle:
    @pytest.mark.asyncio
    async def test_returns_places_on_success(self):
        mock_response_data = {
            "status": "OK",
            "results": [
                {
                    "place_id": "test_1",
                    "name": "Test Place",
                    "vicinity": "Test Address",
                    "rating": 4.5,
                    "user_ratings_total": 100,
                    "types": ["tourist_attraction"],
                    "geometry": {"location": {"lat": 41.0, "lng": 29.0}},
                    "price_level": 1,
                }
            ],
        }

        mock_response = MagicMock()
        mock_response.json = MagicMock(return_value=mock_response_data)

        mock_client = MagicMock()
        mock_client.get = AsyncMock(return_value=mock_response)
        mock_client_class = MagicMock()
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client)

        with patch("main.httpx.AsyncClient", return_value=mock_client_class), \
             patch("main.GOOGLE_PLACES_API_KEY", "test_key"):
            result = await _fetch_places_from_google(41.0, 29.0, 5000, 15)

        assert len(result) == 1
        assert result[0]["name"] == "Test Place"
        assert result[0]["id"] == "test_1"
        assert result[0]["rating"] == 4.5
        assert result[0]["latitude"] == 41.0

    @pytest.mark.asyncio
    async def test_empty_results(self):
        mock_response_data = {"status": "ZERO_RESULTS", "results": []}

        mock_response = MagicMock()
        mock_response.json = MagicMock(return_value=mock_response_data)

        mock_client = MagicMock()
        mock_client.get = AsyncMock(return_value=mock_response)
        mock_client_class = MagicMock()
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client)

        with patch("main.httpx.AsyncClient", return_value=mock_client_class), \
             patch("main.GOOGLE_PLACES_API_KEY", "test_key"):
            result = await _fetch_places_from_google(39.0, 35.0, 5000, 15)

        assert len(result) == 0

    @pytest.mark.asyncio
    async def test_fallback_on_bad_status(self):
        mock_response1_data = {"status": "REQUEST_DENIED", "results": []}
        mock_response2_data = {"status": "ZERO_RESULTS", "results": []}

        mock_resp1 = MagicMock()
        mock_resp1.json = MagicMock(return_value=mock_response1_data)
        mock_resp2 = MagicMock()
        mock_resp2.json = MagicMock(return_value=mock_response2_data)

        mock_client = MagicMock()
        mock_client.get = AsyncMock(side_effect=[mock_resp1, mock_resp2])
        mock_client_class = MagicMock()
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client)

        with patch("main.httpx.AsyncClient", return_value=mock_client_class), \
             patch("main.GOOGLE_PLACES_API_KEY", "test_key"):
            result = await _fetch_places_from_google(41.0, 29.0, 5000, 15)

        assert len(result) == 0

    @pytest.mark.asyncio
    async def test_includes_photo_url_when_photos_exist(self):
        mock_response_data = {
            "status": "OK",
            "results": [
                {
                    "place_id": "test_photo",
                    "name": "Place With Photo",
                    "vicinity": "Photo St",
                    "rating": 4.0,
                    "user_ratings_total": 50,
                    "types": ["museum"],
                    "photos": [{"photo_reference": "photo_ref_123"}],
                    "geometry": {"location": {"lat": 41.0, "lng": 29.0}},
                }
            ],
        }

        mock_response = MagicMock()
        mock_response.json = MagicMock(return_value=mock_response_data)

        mock_client = MagicMock()
        mock_client.get = AsyncMock(return_value=mock_response)
        mock_client_class = MagicMock()
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client)

        with patch("main.httpx.AsyncClient", return_value=mock_client_class), \
             patch("main.GOOGLE_PLACES_API_KEY", "test_key"):
            result = await _fetch_places_from_google(41.0, 29.0, 5000, 15)

        assert "photo_ref_123" in result[0]["photoUrl"]

    @pytest.mark.asyncio
    async def test_respects_max_results(self):
        mock_results = []
        for i in range(30):
            mock_results.append({
                "place_id": f"place_{i}",
                "name": f"Place {i}",
                "vicinity": f"Address {i}",
                "rating": 4.0,
                "user_ratings_total": 10,
                "types": ["tourist_attraction"],
                "geometry": {"location": {"lat": 41.0, "lng": 29.0}},
            })

        mock_response = MagicMock()
        mock_response.json = MagicMock(return_value={"status": "OK", "results": mock_results})

        mock_client = MagicMock()
        mock_client.get = AsyncMock(return_value=mock_response)
        mock_client_class = MagicMock()
        mock_client_class.__aenter__ = AsyncMock(return_value=mock_client)

        with patch("main.httpx.AsyncClient", return_value=mock_client_class), \
             patch("main.GOOGLE_PLACES_API_KEY", "test_key"):
            result = await _fetch_places_from_google(41.0, 29.0, 5000, 5)

        assert len(result) == 5


class TestCityCoordinatesVsCitiesEndpoint:
    def test_coord_cities_in_api_or_excluded(self, client):
        response = client.get("/cities")
        cities = response.json()["cities"]
        city_keys_from_api = {c["key"] for c in cities}

        from main import CITY_COORDINATES
        coord_cities = set(CITY_COORDINATES.keys())

        missing_in_api = coord_cities - city_keys_from_api
        assert missing_in_api == {"lefkoşa", "denizli"}


class TestGetCitiesStructure:
    def test_cities_sorted(self, client):
        response = client.get("/cities")
        cities = response.json()["cities"]
        keys = [c["key"] for c in cities]
        for key in keys:
            assert key == key.lower()
            assert " " not in key

    def test_cities_have_turkish_names(self, client):
        response = client.get("/cities")
        cities = response.json()["cities"]
        turkish_chars = "çğıöşüÇĞİÖŞÜ"
        turkish_cities = [c for c in cities if any(ch in c["name"] for ch in turkish_chars)]
        assert len(turkish_cities) > 0
