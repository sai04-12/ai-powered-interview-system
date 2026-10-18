import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from app.models.base import Base
from app.models.system import SystemSetting


@pytest.fixture
def in_memory_db():
    """Create a temporary in-memory database with tables initialized."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    yield TestingSessionLocal
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


def test_session_crud_and_commit(in_memory_db):
    """Verify session can create, commit, query, and delete SystemSetting records."""
    session: Session = in_memory_db()
    try:
        setting = SystemSetting(
            key="platform.maintenance_mode",
            value="false",
            description="Global maintenance mode flag"
        )
        session.add(setting)
        session.commit()

        # Query back
        retrieved = session.query(SystemSetting).filter_by(key="platform.maintenance_mode").first()
        assert retrieved is not None
        assert retrieved.value == "false"
        assert retrieved.id is not None
        assert retrieved.created_at is not None
        assert retrieved.updated_at is not None
    finally:
        session.close()


def test_session_rollback_on_error(in_memory_db):
    """Verify session rolls back uncommitted changes properly on exception."""
    session: Session = in_memory_db()
    try:
        setting = SystemSetting(
            key="test.rollback_key",
            value="transient"
        )
        session.add(setting)
        session.flush()

        # Simulate rollback
        session.rollback()

        # Verify not present in database
        result = session.query(SystemSetting).filter_by(key="test.rollback_key").first()
        assert result is None
    finally:
        session.close()


def test_get_db_generator_cleanup(monkeypatch, in_memory_db):
    """Verify get_db generator yields a session and ensures close is called."""
    from app.core import database

    monkeypatch.setattr(database, "SessionLocal", in_memory_db)
    gen = database.get_db()
    session = next(gen)
    assert isinstance(session, Session)

    # Exhaust the generator to trigger the finally block
    with pytest.raises(StopIteration):
        next(gen)
