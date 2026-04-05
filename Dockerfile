FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    git \
    libcairo2-dev \
    libffi-dev \
    libpango1.0-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml README.md manim-test.py render_app.py start.sh prepare-fonts.sh ./

RUN ./prepare-fonts.sh

RUN pip install --no-cache-dir .

EXPOSE 8000

CMD ["./start.sh"]
