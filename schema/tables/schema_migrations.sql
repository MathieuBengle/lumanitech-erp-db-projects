-- =============================================================================
-- Table: schema_migrations
-- Description: Tracks all applied database migrations
-- =============================================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY COMMENT 'Migration version (e.g., V001, V002)',
    description VARCHAR(255) NOT NULL COMMENT 'Brief description of the migration',
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the migration was applied',
    INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tracks all applied database migrations';
