import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app

base_url = "http://127.0.0.1:8000"


@pytest.mark.asyncio
async def test_health_check_async():
    transport = ASGITransport(app)
    async with AsyncClient(transport=transport, base_url=base_url) as client:
        response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
