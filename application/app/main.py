import os
import time

from fastapi import FastAPI, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

APP_NAME = os.getenv("APP_NAME", "kubeforge-api")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

REQUEST_COUNT = Counter(
    "kubeforge_http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)

REQUEST_LATENCY = Histogram(
    "kubeforge_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["endpoint"],
)

app = FastAPI(
    title="KubeForge API",
    description="A cloud-native DevSecOps platform demonstration API",
    version=APP_VERSION,
)


@app.middleware("http")
async def record_metrics(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)

    REQUEST_COUNT.labels(
        request.method,
        request.url.path,
        str(response.status_code),
    ).inc()

    REQUEST_LATENCY.labels(request.url.path).observe(
        time.perf_counter() - start
    )
    return response


@app.get("/")
def root():
    return {
        "application": APP_NAME,
        "version": APP_VERSION,
        "status": "running",
        "platform": "KubeForge",
    }


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/ready")
def readiness():
    return {"status": "ready"}


@app.get("/metrics")
def metrics():
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST,
    )
