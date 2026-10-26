FROM python:3.14-slim

COPY --from=ghcr.io/astral-sh/uv:0.8 /uv /uvx /bin/

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1

# Copy dependency files from repository root
COPY pyproject.toml uv.lock ./

# Install production dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

# Copy application code from the new directory
COPY backend ./backend

# Copy startup script from repository root
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

EXPOSE 8000

CMD ["./entrypoint.sh"]