import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import (
    _get_mock_places,
    _get_popular_places_fallback,
    CITY_COORDINATES,
)


class TestCityCoordinates:
    def test_all_cities_have_valid_coordinates(self):
        for city, (lat, lng) in CITY_COORDINATES.items():
            assert -90 <= lat <= 90, f"{city}: geçersiz enlem {lat}"
            assert -180 <= lng <= 180, f"{city}: geçersiz boylam {lng}"

    def test_major_cities_present(self):
        assert "istanbul" in CITY_COORDINATES
        assert "ankara" in CITY_COORDINATES
        assert "izmir" in CITY_COORDINATES
        assert "antalya" in CITY_COORDINATES

    def test_total_city_count(self):
        assert len(CITY_COORDINATES) == 18

    def test_istanbul_coordinates(self):
        lat, lng = CITY_COORDINATES["istanbul"]
        assert pytest.approx(lat, 0.01) == 41.0082
        assert pytest.approx(lng, 0.01) == 28.9784

    def test_ankara_coordinates(self):
        lat, lng = CITY_COORDINATES["ankara"]
        assert pytest.approx(lat, 0.01) == 39.9334
        assert pytest.approx(lng, 0.01) == 32.8597


class TestGetMockPlaces:
    def test_istanbul_returns_8_places(self):
        places = _get_mock_places("istanbul")
        assert len(places) == 8

    def test_ankara_returns_5_places(self):
        places = _get_mock_places("ankara")
        assert len(places) == 5

    def test_izmir_returns_5_places(self):
        places = _get_mock_places("izmir")
        assert len(places) == 5

    def test_antalya_returns_5_places(self):
        places = _get_mock_places("antalya")
        assert len(places) == 5

    def test_unknown_city_returns_generic_2_places(self):
        places = _get_mock_places("bilinmeyensehir")
        assert len(places) == 2
        assert "Merkez" in places[0]["name"] or "Müzesi" in places[1]["name"]

    def test_turkish_uppercase_i_handling(self):
        # Python'da İSTANBUL.lower() → i̇stanbul (combining dot), istanbul != i̇stanbul
        places = _get_mock_places("İSTANBUL")
        assert len(places) == 2  # generic fallback


    def test_each_place_has_required_fields(self):
        places = _get_mock_places("istanbul")
        required = ["id", "name", "address", "rating", "userRatingsTotal", "types"]
        for place in places:
            for field in required:
                assert field in place, f"'{field}' eksik: {place['name']}"

    def test_rating_within_valid_range(self):
        places = _get_mock_places("istanbul")
        for place in places:
            assert 0 <= place["rating"] <= 5, f"Geçersiz rating: {place['rating']}"


class TestGetPopularPlacesFallback:
    def test_returns_10_places(self):
        places = _get_popular_places_fallback()
        assert len(places) == 10

    def test_each_place_has_required_fields(self):
        places = _get_popular_places_fallback()
        required = ["id", "name", "city", "rating", "userRatingsTotal"]
        for place in places:
            for field in required:
                assert field in place, f"'{field}' eksik: {place.get('name')}"

    def test_all_ratings_are_valid(self):
        places = _get_popular_places_fallback()
        for place in places:
            assert 0 <= place["rating"] <= 5

    def test_cappadocia_is_first_and_highest_rated(self):
        places = _get_popular_places_fallback()
        assert places[0]["name"] == "Kapadokya"
        assert places[0]["rating"] == 4.9

    def test_places_have_unique_ids(self):
        places = _get_popular_places_fallback()
        ids = [p["id"] for p in places]
        assert len(ids) == len(set(ids)), "Tüm ID'ler benzersiz olmalı"

    def test_all_have_lat_lng(self):
        places = _get_popular_places_fallback()
        for place in places:
            assert "latitude" in place
            assert "longitude" in place
            assert -90 <= place["latitude"] <= 90
            assert -180 <= place["longitude"] <= 180
