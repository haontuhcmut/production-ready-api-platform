import logging

from fastapi import FastAPI, Request
from prometheus_fastapi_instrumentator import Instrumentator

from backend.app.middleware.request_logging import RequestLoggingMiddleware

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)

logger = logging.getLogger(__name__)

app = FastAPI()

app.add_middleware(RequestLoggingMiddleware)

Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)


@app.get("/health")
async def health(request: Request):
    logger.info(
        "Health check requested request_id=%s",
        request.state.request_id,
    )
    return {"status": "ok"}


@app.get("/test-error")
async def test_error():
    raise ValueError("Example error for logging demonstration")
