import os
import sys
from unittest.mock import MagicMock


def pytest_configure(config):
    # Test ortamında API key'leri boşalt
    os.environ["GOOGLE_PLACES_API_KEY"] = ""
    os.environ["SERPAPI_KEY"] = ""

    # Vertex AI mock'ları — modül import edilmeden önce sys.modules'a yerleştir
    mock_vi = MagicMock()
    mock_vi.init = MagicMock()
    sys.modules["vertexai"] = mock_vi

    mock_gen_models = MagicMock()
    mock_instance = MagicMock()
    mock_instance.generate_content.return_value.text = "## 1. Gün\nTest itinerary"
    mock_gen_models.GenerativeModel = MagicMock(return_value=mock_instance)
    mock_gen_models.Content = MagicMock()
    mock_gen_models.Part = MagicMock()
    sys.modules["vertexai.generative_models"] = mock_gen_models

    # main.py'yi boş key'lerle import et (cached modül)
    import main  # noqa: F401


import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from main import app
    return TestClient(app)
