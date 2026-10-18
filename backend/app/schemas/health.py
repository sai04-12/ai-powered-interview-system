from datetime import datetime, timezone
from typing import Optional
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(default="healthy", description="Current service health status")
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Current server UTC timestamp"
    )
    environment: str = Field(..., description="Application execution environment")
    version: str = Field(default="1.0.0", description="API version")
    database: Optional[str] = Field(default="unconfigured", description="Database connection status")


class DatabaseHealthResponse(BaseModel):
    status: str = Field(..., description="Database readiness status ('healthy' or 'unavailable')")
    database: str = Field(..., description="Database connectivity state ('connected' or 'disconnected')")
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Current server UTC timestamp"
    )
    environment: str = Field(..., description="Application execution environment")
    latency_ms: Optional[float] = Field(default=None, description="Ping query latency in milliseconds")
    message: Optional[str] = Field(default=None, description="Diagnostic status message (sanitized)")
