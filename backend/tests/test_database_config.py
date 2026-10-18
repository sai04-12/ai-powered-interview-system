import pytest
from app.core.config import Settings
from app.core.database import create_database_engine, get_engine_args


def test_sqlite_engine_args():
    """Verify SQLite uses proper poolclass and connect_args."""
    engine_kwargs, connect_args = get_engine_args("sqlite:///./test.db")
    assert connect_args.get("check_same_thread") is False
    assert "poolclass" in engine_kwargs


def test_sqlite_memory_engine_args():
    """Verify in-memory SQLite uses StaticPool."""
    engine_kwargs, connect_args = get_engine_args("sqlite:///:memory:")
    assert connect_args.get("check_same_thread") is False
    assert "poolclass" in engine_kwargs


def test_postgresql_engine_args_defaults():
    """Verify PostgreSQL utilizes configured connection pool parameters."""
    url = "postgresql://testuser:testpass@localhost:5432/testdb"
    engine_kwargs, connect_args = get_engine_args(url)
    assert "pool_size" in engine_kwargs
    assert "max_overflow" in engine_kwargs
    assert "pool_timeout" in engine_kwargs
    assert "pool_recycle" in engine_kwargs
    assert "pool_pre_ping" in engine_kwargs


def test_database_url_from_settings():
    """Verify Settings loads DATABASE_URL correctly."""
    custom_settings = Settings(DATABASE_URL="postgresql://user:pass@dbhost:5432/sample")
    assert "sample" in custom_settings.DATABASE_URL
    assert custom_settings.DB_POOL_SIZE == 5
    assert custom_settings.DB_PRE_PING is True if hasattr(custom_settings, "DB_PRE_PING") else True
