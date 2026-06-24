import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import (
    TravelRequest,
    PlaceRequest,
    FlightSearchRequest,
    HotelSearchRequest,
    ItineraryRequest,
    ChatRequest,
)


class TestTravelRequest:
    def test_valid_request(self):
        req = TravelRequest(city="İstanbul", budget=5000.0, days=3)
        assert req.city == "İstanbul"
        assert req.budget == 5000.0
        assert req.days == 3

    def test_zero_budget(self):
        req = TravelRequest(city="Ankara", budget=0.0, days=1)
        assert req.budget == 0.0

    def test_missing_days_field_raises_validation_error(self):
        with pytest.raises(Exception):
            TravelRequest(city="İzmir", budget=1000.0)


class TestPlaceRequest:
    def test_default_values(self):
        req = PlaceRequest(city="istanbul")
        assert req.radius == 5000
        assert req.max_results == 15

    def test_custom_values(self):
        req = PlaceRequest(city="antalya", radius=10000, max_results=20)
        assert req.radius == 10000
        assert req.max_results == 20

    def test_zero_radius(self):
        req = PlaceRequest(city="ankara", radius=0)
        assert req.radius == 0


class TestFlightSearchRequest:
    def test_one_way_flight(self):
        req = FlightSearchRequest(
            departure_city="İstanbul",
            arrival_city="Ankara",
            departure_date="2025-06-15",
        )
        assert req.return_date is None
        assert req.passengers == 1
        assert req.currency == "TRY"

    def test_round_trip_flight(self):
        req = FlightSearchRequest(
            departure_city="İstanbul",
            arrival_city="İzmir",
            departure_date="2025-07-01",
            return_date="2025-07-07",
            passengers=2,
            currency="USD",
        )
        assert req.return_date == "2025-07-07"
        assert req.passengers == 2
        assert req.currency == "USD"


class TestHotelSearchRequest:
    def test_default_values(self):
        req = HotelSearchRequest(
            city="Antalya",
            check_in="2025-06-01",
            check_out="2025-06-05",
        )
        assert req.guests == 1
        assert req.min_rating == 0.0
        assert req.max_price is None

    def test_with_filters(self):
        req = HotelSearchRequest(
            city="İstanbul",
            check_in="2025-08-01",
            check_out="2025-08-03",
            guests=3,
            min_rating=4.0,
            max_price=2000.0,
        )
        assert req.guests == 3
        assert req.min_rating == 4.0
        assert req.max_price == 2000.0


class TestItineraryRequest:
    def test_minimal_request(self):
        req = ItineraryRequest(
            departure_city="İstanbul",
            arrival_city="Ankara",
            departure_date="2025-06-10",
        )
        assert req.return_date is None
        assert req.hotel_name is None
        assert req.selected_places == []

    def test_full_request(self):
        req = ItineraryRequest(
            departure_city="İstanbul",
            arrival_city="Antalya",
            departure_date="2025-07-01",
            return_date="2025-07-05",
            hotel_name="Rixos Premium",
            selected_places=[{"name": "Kaleiçi", "address": "Muratpaşa"}],
            flight_airline="THY",
            flight_departure_time="08:00",
            return_flight_airline="Pegasus",
            return_flight_departure_time="22:00",
        )
        assert req.return_date == "2025-07-05"
        assert req.hotel_name == "Rixos Premium"
        assert len(req.selected_places) == 1
        assert req.selected_places[0]["name"] == "Kaleiçi"
        assert req.flight_airline == "THY"


class TestChatRequest:
    def test_simple_message(self):
        req = ChatRequest(message="Merhaba")
        assert req.message == "Merhaba"
        assert req.history == []
        assert req.user_plans == []

    def test_with_history(self):
        history = [
            {"role": "user", "content": "Nereye gitmeliyim?"},
            {"role": "assistant", "content": "Antalya güzel olur."},
        ]
        req = ChatRequest(message="Peki otel?", history=history)
        assert len(req.history) == 2
        assert req.history[0]["role"] == "user"

    def test_with_user_plans(self):
        plans = [
            {"title": "Antalya Gezisi", "departure_city": "İstanbul", "arrival_city": "Antalya"},
        ]
        req = ChatRequest(message="Planımı incele", user_plans=plans)
        assert len(req.user_plans) == 1
