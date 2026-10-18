from typing import Any, Dict, Generator, Optional, Tuple
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import NullPool, StaticPool
from app.core.config import settings


def get_engine_args(db_url: str) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    """Determine engine kwargs and connect_args based on database dialect."""
    connect_args: Dict[str, Any] = {}
    engine_kwargs: Dict[str, Any] = {
        "echo": settings.DB_ECHO,
    }

    if db_url.startswith("sqlite"):
        connect_args["check_same_thread"] = False
        if ":memory:" in db_url:
            engine_kwargs["poolclass"] = StaticPool
        else:
            engine_kwargs["poolclass"] = NullPool
    else:
        # PostgreSQL / MySQL configuration
        engine_kwargs["pool_size"] = settings.DB_POOL_SIZE
        engine_kwargs["max_overflow"] = settings.DB_MAX_OVERFLOW
        engine_kwargs["pool_timeout"] = settings.DB_POOL_TIMEOUT
        engine_kwargs["pool_recycle"] = settings.DB_POOL_RECYCLE
        engine_kwargs["pool_pre_ping"] = settings.DB_POOL_PRE_PING

        if settings.DB_SSL_MODE:
            connect_args["sslmode"] = settings.DB_SSL_MODE

    return engine_kwargs, connect_args


def create_database_engine(url: Optional[str] = None) -> Engine:
    """Create a configured SQLAlchemy engine."""
    db_url = url or settings.DATABASE_URL
    engine_kwargs, connect_args = get_engine_args(db_url)
    return create_engine(db_url, connect_args=connect_args, **engine_kwargs)


# Application-level engine and session factory
engine: Engine = create_database_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    """FastAPI dependency yielding an isolated database session with guaranteed closure."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def check_database_connection(timeout_seconds: float = 2.0) -> Tuple[bool, str]:
    """Execute a lightweight connectivity check.
    
    Returns (True, 'connected') if reachable, or (False, 'unavailable') on failure.
    Never exposes passwords, hostnames, or private connection strings.
    """
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True, "connected"
    except Exception:
        return False, "unavailable"
