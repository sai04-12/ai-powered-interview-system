import os
import tempfile
import pytest
from alembic import command
from alembic.config import Config
from app.models.base import Base


def test_migration_metadata_discovery():
    """Verify SQLAlchemy Base.metadata discovers registered models."""
    tables = Base.metadata.tables
    assert "system_settings" in tables
    assert "users" in tables
    assert "refresh_tokens" in tables
    
    table = tables["system_settings"]
    column_names = [col.name for col in table.columns]
    assert "id" in column_names
    assert "key" in column_names
    assert "value" in column_names
    assert "description" in column_names
    assert "created_at" in column_names
    assert "updated_at" in column_names

    user_table = tables["users"]
    user_columns = [col.name for col in user_table.columns]
    assert "id" in user_columns
    assert "email" in user_columns
    assert "hashed_password" in user_columns
    assert "role" in user_columns
    assert "is_active" in user_columns
    assert "created_at" in user_columns
    assert "updated_at" in user_columns

    token_table = tables["refresh_tokens"]
    token_columns = [col.name for col in token_table.columns]
    assert "id" in token_columns
    assert "token_hash" in token_columns
    assert "user_id" in token_columns
    assert "expires_at" in token_columns
    assert "is_revoked" in token_columns
    assert "created_at" in token_columns
    assert "replaced_by_hash" in token_columns

    assert "resumes" in tables
    resume_table = tables["resumes"]
    resume_cols = [col.name for col in resume_table.columns]
    assert "id" in resume_cols
    assert "user_id" in resume_cols
    assert "filename" in resume_cols
    assert "storage_key" in resume_cols
    assert "file_type" in resume_cols
    assert "file_size" in resume_cols
    assert "extraction_status" in resume_cols
    assert "raw_text" in resume_cols
    assert "structured_data" in resume_cols

    assert "job_descriptions" in tables
    job_table = tables["job_descriptions"]
    job_cols = [col.name for col in job_table.columns]
    assert "id" in job_cols
    assert "recruiter_id" in job_cols
    assert "title" in job_cols
    assert "company" in job_cols
    assert "description" in job_cols
    assert "required_skills" in job_cols
    assert "preferred_skills" in job_cols

    assert "resume_job_matches" in tables
    match_table = tables["resume_job_matches"]
    match_cols = [col.name for col in match_table.columns]
    assert "id" in match_cols
    assert "resume_id" in match_cols
    assert "job_id" in match_cols
    assert "overall_score" in match_cols
    assert "skill_score" in match_cols
    assert "experience_score" in match_cols


def test_alembic_upgrade_and_downgrade():
    """Verify Alembic migration upgrade to head and downgrade to base on disposable database."""
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as tmp_db:
        tmp_db_path = tmp_db.name

    try:
        sqlite_url = f"sqlite:///{tmp_db_path.replace(os.sep, '/')}"
        
        # Path to alembic.ini
        base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        ini_path = os.path.join(base_dir, "alembic.ini")
        
        alembic_cfg = Config(ini_path)
        alembic_cfg.set_main_option("sqlalchemy.url", sqlite_url)
        alembic_cfg.set_main_option("script_location", os.path.join(base_dir, "migrations"))

        # Run upgrade to head
        command.upgrade(alembic_cfg, "head")

        # Run downgrade back to base
        command.downgrade(alembic_cfg, "base")
    finally:
        if os.path.exists(tmp_db_path):
            try:
                os.remove(tmp_db_path)
            except OSError:
                pass
