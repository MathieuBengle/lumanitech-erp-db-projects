-- =============================================================================
-- Lumanitech ERP - Projects Database Schema
-- =============================================================================
-- Description: Complete database schema for the Projects module
-- Version: Current state after all migrations
-- Last Updated: 2025-12-21
-- Owner: Projects API Team
-- =============================================================================

-- Database Configuration
-- This schema assumes MySQL 8.0+ with utf8mb4 character set

-- =============================================================================
-- PROJECTS TABLE
-- =============================================================================
-- Stores main project information
CREATE TABLE IF NOT EXISTS projects (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status ENUM('draft', 'active', 'on_hold', 'completed', 'cancelled') NOT NULL DEFAULT 'draft',
    priority ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    start_date DATE,
    end_date DATE,
    budget DECIMAL(15, 2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED,
    updated_by BIGINT UNSIGNED,
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_dates (start_date, end_date),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Main projects table';

-- =============================================================================
-- TASKS TABLE
-- =============================================================================
-- Stores individual tasks within projects
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
-- PROJECT_MEMBERS TABLE
-- =============================================================================
-- Tracks project team members and their roles
CREATE TABLE IF NOT EXISTS project_members (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    role ENUM('owner', 'manager', 'developer', 'viewer') NOT NULL DEFAULT 'viewer',
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_project_user (project_id, user_id),
    INDEX idx_project_id (project_id),
    INDEX idx_user_id (user_id),
    INDEX idx_role (role),
    CONSTRAINT fk_project_members_project FOREIGN KEY (project_id) 
        REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Project team members table';

-- =============================================================================
-- NOTES
-- =============================================================================
-- This schema represents the current state of the database.
-- All changes should be made through versioned migration scripts.
-- See /migrations folder for the complete migration history.
-- =============================================================================
