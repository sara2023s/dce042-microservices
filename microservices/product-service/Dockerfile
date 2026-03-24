# ── Build stage ────────────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Runtime stage ──────────────────────────────────────────────────────────────
FROM python:3.12-slim

# Non-root user for least-privilege
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .

USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "2", "app:app"]
