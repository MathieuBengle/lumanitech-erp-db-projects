-- =============================================================================
-- Seed Data: Development Sample Projects
-- Description: Sample project data for development and testing
-- WARNING: Do not use in production!
-- =============================================================================

-- Insert sample projects
INSERT INTO projects (project_code, name, description, status, priority, start_date, end_date, budget, created_by, updated_by)
VALUES
    ('PROJ-001', 'ERP System Development', 'Development of the main ERP system modules', 'active', 'critical', '2025-01-01', '2025-12-31', 500000.00, 1, 1),
    ('PROJ-002', 'Mobile App Development', 'iOS and Android mobile applications for ERP', 'active', 'high', '2025-02-01', '2025-08-31', 150000.00, 1, 1),
    ('PROJ-003', 'Database Migration', 'Migration from legacy database to new schema', 'completed', 'high', '2024-06-01', '2024-12-31', 75000.00, 2, 2),
    ('PROJ-004', 'Security Audit', 'Comprehensive security audit of all systems', 'on_hold', 'medium', '2025-03-01', '2025-05-31', 50000.00, 2, 2),
    ('PROJ-005', 'UI/UX Redesign', 'Redesign of user interface and user experience', 'draft', 'medium', NULL, NULL, 80000.00, 3, 3)
ON DUPLICATE KEY UPDATE 
    name = VALUES(name),
    description = VALUES(description),
    status = VALUES(status),
    priority = VALUES(priority),
    start_date = VALUES(start_date),
    end_date = VALUES(end_date),
    budget = VALUES(budget);
