FROM python:3.13-slim

# Install ffmpeg (needed by pydub to convert audio formats)
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install uv for fast dependency resolution
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy dependency files first for caching
COPY pyproject.toml .
COPY .python-version .

# Install dependencies
RUN uv sync --no-dev

# Copy app code and model
COPY . .

# Expose port
ENV PORT=8080
EXPOSE 8080

# Run the app
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
