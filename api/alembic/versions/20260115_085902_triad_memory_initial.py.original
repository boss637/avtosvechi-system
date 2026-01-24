"""triad memory initial

Revision ID: triad_memory_initial
Revises: 
Create Date: 2026-01-15 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'triad_memory_initial'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Таблица incidents (Инциденты)
    op.create_table('incidents',
        sa.Column('id', sa.Integer(), sa.Identity(start=1, increment=1), nullable=False, comment='Уникальный идентификатор инцидента'),
        sa.Column('service_name', sa.String(length=64), nullable=False, comment='Имя сервиса (api, postgres, shell-agent)'),
        sa.Column('error_type', sa.String(length=128), nullable=False, comment='Тип ошибки (connection_refused, 500_error, timeout)'),
        sa.Column('status', sa.String(length=32), server_default='new', nullable=False, comment='Статус: new, seen, resolving, resolved'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False, comment='Дата и время создания записи'),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False, comment='Дата и время последнего обновления'),
        sa.Column('metadata', postgresql.JSONB(astext_type=sa.Text()), server_default='{}', nullable=False, comment='Дополнительные метаданные в формате JSON'),
        sa.PrimaryKeyConstraint('id', name='incidents_pkey'),
        sa.CheckConstraint("status IN ('new', 'seen', 'resolving', 'resolved')", name='incidents_status_check'),
        comment='Таблица для хранения инцидентов мониторинга'
    )
    
    # Индексы для incidents
    op.create_index('idx_incidents_service_name', 'incidents', ['service_name'], unique=False)
    op.create_index('idx_incidents_error_type', 'incidents', ['error_type'], unique=False)
    op.create_index('idx_incidents_status', 'incidents', ['status'], unique=False)
    op.create_index('idx_incidents_created_at', 'incidents', ['created_at'], unique=False)
    op.create_index('idx_incidents_service_created', 'incidents', ['service_name', 'created_at'], unique=False)
    
    # Таблица playbooks (Сценарии решения)
    op.create_table('playbooks',
        sa.Column('id', sa.Integer(), sa.Identity(start=1, increment=1), nullable=False, comment='Уникальный идентификатор сценария'),
        sa.Column('name', sa.String(length=128), nullable=False, comment='Название сценария (человекочитаемое)'),
        sa.Column('file_path', sa.String(length=512), nullable=False, comment='Путь к файлу сценария на диске'),
        sa.Column('description', sa.Text(), nullable=True, comment='Подробное описание сценария'),
        sa.Column('command_template', sa.Text(), nullable=False, comment='Шаблон команды для выполнения'),
        sa.Column('is_active', sa.Boolean(), server_default='true', nullable=False, comment='Активен ли сценарий'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False, comment='Дата создания сценария'),
        sa.PrimaryKeyConstraint('id', name='playbooks_pkey'),
        sa.UniqueConstraint('name', name='playbooks_name_unique'),
        comment='Таблица сценариев автоматического реагирования'
    )
    
    # Индексы для playbooks
    op.create_index('idx_playbooks_is_active', 'playbooks', ['is_active'], unique=False)
    
    # Таблица knowledge_base (База знаний)
    op.create_table('knowledge_base',
        sa.Column('id', sa.Integer(), sa.Identity(start=1, increment=1), nullable=False, comment='Уникальный идентификатор записи'),
        sa.Column('error_pattern', sa.String(length=512), nullable=False, comment='Регулярное выражение или шаблон ошибки'),
        sa.Column('playbook_id', sa.Integer(), nullable=True, comment='Ссылка на рекомендуемый сценарий решения'),
        sa.Column('confidence_score', sa.Float(), server_default='0.9', nullable=False, comment='Уверенность в правильности решения (0.0-1.0)'),
        sa.Column('tags', postgresql.ARRAY(sa.String(length=64)), server_default='{}', nullable=False, comment='Теги для категоризации'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False, comment='Дата создания записи'),
        sa.Column('usage_count', sa.Integer(), server_default='0', nullable=False, comment='Счетчик использования этой записи'),
        sa.ForeignKeyConstraint(['playbook_id'], ['playbooks.id'], name='knowledge_base_playbook_id_fkey', ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id', name='knowledge_base_pkey'),
        sa.CheckConstraint('confidence_score >= 0.0 AND confidence_score <= 1.0', name='knowledge_base_confidence_check'),
        comment='База знаний для связи ошибок со сценариями решения'
    )
    
    # Индексы для knowledge_base
    op.create_index('idx_knowledge_base_error_pattern', 'knowledge_base', ['error_pattern'], unique=False, postgresql_using='gin')
    op.create_index('idx_knowledge_base_playbook_id', 'knowledge_base', ['playbook_id'], unique=False)
    op.create_index('idx_knowledge_base_tags', 'knowledge_base', ['tags'], unique=False, postgresql_using='gin')
    op.create_index('idx_knowledge_base_confidence', 'knowledge_base', ['confidence_score'], unique=False)
    
    # Добавляем комментарии к колонкам
    op.execute("COMMENT ON COLUMN incidents.service_name IS 'Имя сервиса, в котором произошел инцидент';")
    op.execute("COMMENT ON COLUMN incidents.error_type IS 'Классифицированный тип ошибки для аналитики';")
    op.execute("COMMENT ON COLUMN incidents.metadata IS 'Дополнительные данные: traceback, headers, request params и т.д.';")
    
    op.execute("COMMENT ON COLUMN playbooks.command_template IS 'Шаблон команды с плейсхолдерами {service_name}, {error_type} и т.д.';")
    
    op.execute("COMMENT ON COLUMN knowledge_base.error_pattern IS 'Шаблон для сопоставления с логами/ошибками (регулярное выражение)';")
    op.execute("COMMENT ON COLUMN knowledge_base.tags IS 'Массив тегов для фильтрации и поиска';")


def downgrade() -> None:
    # Удаляем в обратном порядке с учетом foreign keys
    op.drop_index('idx_knowledge_base_confidence', table_name='knowledge_base')
    op.drop_index('idx_knowledge_base_tags', table_name='knowledge_base')
    op.drop_index('idx_knowledge_base_playbook_id', table_name='knowledge_base')
    op.drop_index('idx_knowledge_base_error_pattern', table_name='knowledge_base')
    op.drop_table('knowledge_base')
    
    op.drop_index('idx_playbooks_is_active', table_name='playbooks')
    op.drop_table('playbooks')
    
    op.drop_index('idx_incidents_service_created', table_name='incidents')
    op.drop_index('idx_incidents_created_at', table_name='incidents')
    op.drop_index('idx_incidents_status', table_name='incidents')
    op.drop_index('idx_incidents_error_type', table_name='incidents')
    op.drop_index('idx_incidents_service_name', table_name='incidents')
    op.drop_table('incidents')
