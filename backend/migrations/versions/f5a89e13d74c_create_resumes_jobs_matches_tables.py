"""create_resumes_jobs_matches_tables

Revision ID: f5a89e13d74c
Revises: 2044e270ea2d
Create Date: 2026-10-18 13:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'f5a89e13d74c'
down_revision: Union[str, Sequence[str], None] = '2044e270ea2d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema to include resumes, job_descriptions, and resume_job_matches tables."""
    # 1. resumes table
    op.create_table(
        'resumes',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('filename', sa.String(length=255), nullable=False),
        sa.Column('storage_key', sa.String(length=255), nullable=False),
        sa.Column('file_type', sa.String(length=100), nullable=False),
        sa.Column('file_size', sa.Integer(), nullable=False),
        sa.Column('extraction_status', sa.String(length=50), nullable=False),
        sa.Column('raw_text', sa.Text(), nullable=True),
        sa.Column('structured_data', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_resumes_id'), 'resumes', ['id'], unique=False)
    op.create_index(op.f('ix_resumes_user_id'), 'resumes', ['user_id'], unique=False)
    op.create_index(op.f('ix_resumes_storage_key'), 'resumes', ['storage_key'], unique=True)
    op.create_index(op.f('ix_resumes_extraction_status'), 'resumes', ['extraction_status'], unique=False)

    # 2. job_descriptions table
    op.create_table(
        'job_descriptions',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('recruiter_id', sa.String(length=36), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('company', sa.String(length=200), nullable=True),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('required_skills', sa.JSON(), nullable=False),
        sa.Column('preferred_skills', sa.JSON(), nullable=False),
        sa.Column('min_experience_years', sa.Integer(), nullable=True),
        sa.Column('education_requirements', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['recruiter_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_job_descriptions_id'), 'job_descriptions', ['id'], unique=False)
    op.create_index(op.f('ix_job_descriptions_recruiter_id'), 'job_descriptions', ['recruiter_id'], unique=False)
    op.create_index(op.f('ix_job_descriptions_title'), 'job_descriptions', ['title'], unique=False)

    # 3. resume_job_matches table
    op.create_table(
        'resume_job_matches',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('resume_id', sa.String(length=36), nullable=False),
        sa.Column('job_id', sa.String(length=36), nullable=False),
        sa.Column('overall_score', sa.Float(), nullable=False),
        sa.Column('skill_score', sa.Float(), nullable=False),
        sa.Column('experience_score', sa.Float(), nullable=False),
        sa.Column('education_score', sa.Float(), nullable=True),
        sa.Column('matched_skills', sa.JSON(), nullable=False),
        sa.Column('missing_skills', sa.JSON(), nullable=False),
        sa.Column('explanation', sa.Text(), nullable=False),
        sa.Column('limitations', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['job_id'], ['job_descriptions.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['resume_id'], ['resumes.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('resume_id', 'job_id', name='uq_resume_job_match'),
    )
    op.create_index(op.f('ix_resume_job_matches_id'), 'resume_job_matches', ['id'], unique=False)
    op.create_index(op.f('ix_resume_job_matches_job_id'), 'resume_job_matches', ['job_id'], unique=False)
    op.create_index(op.f('ix_resume_job_matches_resume_id'), 'resume_job_matches', ['resume_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema by dropping resumes, job_descriptions, and resume_job_matches."""
    op.drop_index(op.f('ix_resume_job_matches_resume_id'), table_name='resume_job_matches')
    op.drop_index(op.f('ix_resume_job_matches_job_id'), table_name='resume_job_matches')
    op.drop_index(op.f('ix_resume_job_matches_id'), table_name='resume_job_matches')
    op.drop_table('resume_job_matches')

    op.drop_index(op.f('ix_job_descriptions_title'), table_name='job_descriptions')
    op.drop_index(op.f('ix_job_descriptions_recruiter_id'), table_name='job_descriptions')
    op.drop_index(op.f('ix_job_descriptions_id'), table_name='job_descriptions')
    op.drop_table('job_descriptions')

    op.drop_index(op.f('ix_resumes_extraction_status'), table_name='resumes')
    op.drop_index(op.f('ix_resumes_storage_key'), table_name='resumes')
    op.drop_index(op.f('ix_resumes_user_id'), table_name='resumes')
    op.drop_index(op.f('ix_resumes_id'), table_name='resumes')
    op.drop_table('resumes')
