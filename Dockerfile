FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml README.md manim-test.py start.sh prepare-fonts.sh ./

RUN ./prepare-fonts.sh

RUN pip install --no-cache-dir .

EXPOSE 8000

CMD ["./start.sh"]
