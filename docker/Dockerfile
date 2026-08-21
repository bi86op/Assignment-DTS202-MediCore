# Stage 1 - Build dependencies and compile application
FROM python:3.11-slim AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install --no-cache-dir \
    --prefix=/install \
    -r requirements.txt

COPY app.py .

# Compile application source
RUN python -m py_compile app.py \
    && cp __pycache__/app.cpython-311.pyc /build/app.pyc

# Stage 2 - Production runtime
FROM python:3.11-slim AS production

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --no-cache-dir --upgrade \
    pip \
    setuptools \
    wheel \
    "msgpack>=1.2.1"

RUN groupadd --gid 1001 appuser \
    && useradd \
       --uid 1001 \
       --gid 1001 \
       --create-home \
       --shell /usr/sbin/nologin \
       appuser

WORKDIR /app

COPY --from=builder /install /usr/local
COPY --from=builder /build/app.pyc /app/app.pyc

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
