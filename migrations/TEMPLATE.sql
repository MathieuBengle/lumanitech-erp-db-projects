-- =============================================================================
-- Migration: V###_description
-- Description: Brief description of what this migration does
-- Author: Projects API Team
-- Date: YYYY-MM-DD
-- =============================================================================

-- Your SQL statements here
-- Use IF NOT EXISTS where possible for idempotency

-- Example: Creating a table
-- CREATE TABLE IF NOT EXISTS example_table (
--     id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
-- COMMENT='Example table description';

-- Example: Altering a table
-- ALTER TABLE existing_table 
-- ADD COLUMN IF NOT EXISTS new_column VARCHAR(255);

-- Example: Creating an index
-- CREATE INDEX IF NOT EXISTS idx_column_name ON table_name(column_name);

-- =============================================================================
-- Migration Tracking
-- =============================================================================
-- Record this migration in the schema_migrations table
INSERT INTO schema_migrations (version, description)
VALUES ('V###', 'description')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
