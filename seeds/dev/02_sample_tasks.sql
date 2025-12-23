-- =============================================================================
-- Seed Data: Development Sample Tasks
-- Description: Sample task data for development and testing
-- WARNING: Do not use in production!
-- =============================================================================

-- Insert sample tasks for PROJ-001
INSERT INTO tasks (project_id, task_code, title, description, status, priority, assigned_to, estimated_hours, actual_hours, due_date, created_by, updated_by)
VALUES
    (1, 'TASK-001', 'Setup development environment', 'Configure development servers and tools', 'done', 'high', 1, 16.00, 18.00, '2025-01-15', 1, 1),
    (1, 'TASK-002', 'Design database schema', 'Create ER diagrams and schema design', 'done', 'critical', 2, 40.00, 42.00, '2025-01-20', 1, 1),
    (1, 'TASK-003', 'Implement authentication module', 'JWT-based authentication system', 'in_progress', 'critical', 1, 80.00, 45.00, '2025-02-15', 1, 1),
    (1, 'TASK-004', 'Create REST API endpoints', 'RESTful API for all modules', 'in_progress', 'high', 3, 120.00, 60.00, '2025-03-01', 1, 1),
    (1, 'TASK-005', 'Write unit tests', 'Comprehensive unit test coverage', 'todo', 'medium', 2, 60.00, NULL, '2025-03-15', 1, 1),
    
    -- Tasks for PROJ-002
    (2, 'TASK-001', 'Setup React Native project', 'Initialize mobile app project structure', 'done', 'high', 3, 8.00, 10.00, '2025-02-05', 1, 1),
    (2, 'TASK-002', 'Design mobile UI mockups', 'Create UI designs for all screens', 'in_progress', 'high', 4, 40.00, 25.00, '2025-02-28', 1, 1),
    (2, 'TASK-003', 'Implement login screen', 'Mobile login interface and logic', 'todo', 'high', 3, 16.00, NULL, '2025-03-10', 1, 1),
    
    -- Tasks for PROJ-003
    (3, 'TASK-001', 'Analyze legacy schema', 'Document existing database structure', 'done', 'critical', 2, 24.00, 20.00, '2024-06-15', 2, 2),
    (3, 'TASK-002', 'Create migration scripts', 'Write data migration scripts', 'done', 'critical', 2, 80.00, 95.00, '2024-09-30', 2, 2),
    (3, 'TASK-003', 'Execute migration', 'Run migration in production', 'done', 'critical', 2, 16.00, 22.00, '2024-12-15', 2, 2)
ON DUPLICATE KEY UPDATE
    title = VALUES(title),
    description = VALUES(description),
    status = VALUES(status),
    priority = VALUES(priority);
