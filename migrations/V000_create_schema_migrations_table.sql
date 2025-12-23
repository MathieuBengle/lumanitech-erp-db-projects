-- =============================================================================
-- Migration: V000_create_schema_migrations_table
-- Description: Create schema_migrations table for tracking migration history
-- Author: Projects API Team
-- Date: 2025-12-23
-- =============================================================================

-- Create schema_migrations table for tracking applied migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(50) PRIMARY KEY COMMENT 'Migration version (e.g., V001, V002)',
    description VARCHAR(255) NOT NULL COMMENT 'Brief description of the migration',
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the migration was applied',
    INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tracks all applied database migrations';

-- =============================================================================
-- Migration Tracking
-- =============================================================================
-- Record this migration in the schema_migrations table
INSERT INTO schema_migrations (version, description)
VALUES ('V000', 'create_schema_migrations_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
