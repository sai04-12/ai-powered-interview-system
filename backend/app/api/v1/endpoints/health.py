import time
from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.core import database
from app.schemas.health import DatabaseHealthResponse, HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse, tags=["Health"])
def get_health() -> HealthResponse:
    """Return application operational health status and metadata (liveness probe)."""
    return HealthResponse(
        status="healthy",
        environment=settings.ENVIRONMENT,
        version="1.0.0",
        database="ready"
    )


@router.get(
    "/health/database",
    response_model=DatabaseHealthResponse,
    responses={
        status.HTTP_200_OK: {"model": DatabaseHealthResponse, "description": "Database is reachable"},
        status.HTTP_503_SERVICE_UNAVAILABLE: {"model": DatabaseHealthResponse, "description": "Database is unreachable"},
    },
    tags=["Health"]
)
def get_database_health():
    """Database readiness probe executing a lightweight query.
    
    Returns HTTP 200 if database responds, or HTTP 503 if unreachable.
    Never exposes credentials, passwords, or connection strings.
    """
    start_time = time.perf_counter()
    is_connected, _ = database.check_database_connection(timeout_seconds=2.0)
    latency_ms = round((time.perf_counter() - start_time) * 1000, 2)

    if is_connected:
        return DatabaseHealthResponse(
            status="healthy",
            database="connected",
            environment=settings.ENVIRONMENT,
            latency_ms=latency_ms,
            message="Database connection verified successfully"
        )

    # Database is unavailable
    content = DatabaseHealthResponse(
        status="unavailable",
        database="disconnected",
        environment=settings.ENVIRONMENT,
        latency_ms=latency_ms,
        message="Database service is currently unreachable"
    ).model_dump(mode="json")

    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content=content
    )
