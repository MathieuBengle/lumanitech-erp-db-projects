-- =============================================================================
-- Seed Data: Development Sample Project Members
-- Description: Sample project member assignments for development and testing
-- WARNING: Do not use in production!
-- =============================================================================

-- Insert sample project members
INSERT INTO project_members (project_id, user_id, role)
VALUES
    -- PROJ-001 team
    (1, 1, 'owner'),
    (1, 2, 'manager'),
    (1, 3, 'developer'),
    (1, 4, 'developer'),
    (1, 5, 'viewer'),
    
    -- PROJ-002 team
    (2, 1, 'owner'),
    (2, 3, 'manager'),
    (2, 4, 'developer'),
    (2, 6, 'developer'),
    
    -- PROJ-003 team
    (3, 2, 'owner'),
    (3, 1, 'manager'),
    
    -- PROJ-004 team
    (4, 2, 'owner'),
    (4, 7, 'developer'),
    
    -- PROJ-005 team
    (5, 3, 'owner'),
    (5, 4, 'developer'),
    (5, 5, 'developer')
ON DUPLICATE KEY UPDATE
    role = VALUES(role);
