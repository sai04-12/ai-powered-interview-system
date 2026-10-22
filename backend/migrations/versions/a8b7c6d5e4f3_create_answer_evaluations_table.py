"""create_answer_evaluations_table

Revision ID: a8b7c6d5e4f3
Revises: c7b8e1925a3d
Create Date: 2026-10-22 10:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a8b7c6d5e4f3'
down_revision: Union[str, Sequence[str], None] = 'c7b8e1925a3d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema to include answer_evaluations table."""
    op.create_table(
        'answer_evaluations',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('session_id', sa.String(length=36), nullable=False),
        sa.Column('answer_id', sa.String(length=36), nullable=False),
        sa.Column('question_id', sa.String(length=36), nullable=False),
        sa.Column('answer_revision', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('rubric_version', sa.String(length=20), nullable=False),
        sa.Column('overall_score', sa.Float(), nullable=True),
        sa.Column('normalized_score', sa.Float(), nullable=True),
        sa.Column('criteria_scores', sa.JSON(), nullable=False),
        sa.Column('evidence_excerpts', sa.JSON(), nullable=False),
        sa.Column('strengths', sa.JSON(), nullable=False),
        sa.Column('improvement_areas', sa.JSON(), nullable=False),
        sa.Column('evaluator_type', sa.String(length=50), nullable=False),
        sa.Column('provider_metadata', sa.JSON(), nullable=True),
        sa.Column('evaluation_limitations', sa.Text(), nullable=True),
        sa.Column('feedback_summary', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['answer_id'], ['interview_answers.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['question_id'], ['interview_questions.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['session_id'], ['interview_sessions.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('answer_id', 'answer_revision', 'rubric_version', name='uq_answer_eval_revision_rubric'),
    )
    op.create_index(op.f('ix_answer_evaluations_id'), 'answer_evaluations', ['id'], unique=False)
    op.create_index(op.f('ix_answer_evaluations_session_id'), 'answer_evaluations', ['session_id'], unique=False)
    op.create_index(op.f('ix_answer_evaluations_answer_id'), 'answer_evaluations', ['answer_id'], unique=False)
    op.create_index(op.f('ix_answer_evaluations_question_id'), 'answer_evaluations', ['question_id'], unique=False)
    op.create_index(op.f('ix_answer_evaluations_status'), 'answer_evaluations', ['status'], unique=False)
    op.create_index(op.f('ix_answer_evaluations_is_active'), 'answer_evaluations', ['is_active'], unique=False)


def downgrade() -> None:
    """Downgrade schema by dropping answer_evaluations table."""
    op.drop_index(op.f('ix_answer_evaluations_is_active'), table_name='answer_evaluations')
    op.drop_index(op.f('ix_answer_evaluations_status'), table_name='answer_evaluations')
    op.drop_index(op.f('ix_answer_evaluations_question_id'), table_name='answer_evaluations')
    op.drop_index(op.f('ix_answer_evaluations_answer_id'), table_name='answer_evaluations')
    op.drop_index(op.f('ix_answer_evaluations_session_id'), table_name='answer_evaluations')
    op.drop_index(op.f('ix_answer_evaluations_id'), table_name='answer_evaluations')
    op.drop_table('answer_evaluations')
