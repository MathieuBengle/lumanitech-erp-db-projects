-- =============================================================================
-- Migration: V002_create_tasks_table
-- Description: Create the tasks table for project tasks
-- Author: Projects API Team
-- Date: 2025-12-21
-- =============================================================================

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    task_code VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status ENUM('todo', 'in_progress', 'review', 'done', 'blocked') NOT NULL DEFAULT 'todo',
    priority ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    assigned_to BIGINT UNSIGNED,
    estimated_hours DECIMAL(8, 2),
    actual_hours DECIMAL(8, 2),
    due_date DATE,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    UNIQUE KEY uk_project_task_code (project_id, task_code),
    INDEX idx_project_id (project_id),
    INDEX idx_status (status),
    INDEX idx_assigned_to (assigned_to),
    INDEX idx_due_date (due_date),
    CONSTRAINT fk_tasks_project FOREIGN KEY (project_id) 
        REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Project tasks table';

-- =============================================================================
-- Migration Tracking
-- =============================================================================
-- Record this migration in the schema_migrations table
INSERT INTO schema_migrations (version, description)
VALUES ('V002', 'create_tasks_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
