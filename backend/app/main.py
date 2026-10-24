import logging

from fastapi import FastAPI

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)

logger = logging.getLogger(__name__)

app = FastAPI()


@app.get("/health")
async def health():
    logger.info("Health check requested")
    return {"status": "ok"}


@app.get("/test-error")
async def test_error():
    try:
        raise ValueError("Example error for logging demonstration")
    except ValueError:
        logger.exception("Example application error")
        raise
