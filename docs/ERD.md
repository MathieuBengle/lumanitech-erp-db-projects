# Entity Relationship Diagram

## Overview

This document describes the relationships between tables in the Lumanitech ERP Projects database.

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────┐
│                  projects                    │
├─────────────────────────────────────────────┤
│ PK  id                BIGINT UNSIGNED       │
│ UNQ project_code      VARCHAR(50)           │
│     name              VARCHAR(255)          │
│     description       TEXT                  │
│     status            ENUM                  │
│     priority          ENUM                  │
│     start_date        DATE                  │
│     end_date          DATE                  │
│     budget            DECIMAL(15,2)         │
│     created_at        TIMESTAMP             │
│     updated_at        TIMESTAMP             │
│     created_by        BIGINT UNSIGNED       │
│     updated_by        BIGINT UNSIGNED       │
└─────────────────────────────────────────────┘
        │                              │
        │ 1                            │ 1
        │                              │
        │ *                            │ *
        ▼                              ▼
┌───────────────────────┐    ┌─────────────────────────┐
│       tasks           │    │   project_members       │
├───────────────────────┤    ├─────────────────────────┤
│ PK  id                │    │ PK  id                  │
│ FK  project_id        │    │ FK  project_id          │
│ UNQ task_code         │    │     user_id             │
│     title             │    │     role                │
│     description       │    │     joined_at           │
│     status            │    │     created_at          │
│     priority          │    │     updated_at          │
│     assigned_to       │    │                         │
│     estimated_hours   │    │ UNQ (project_id,        │
│     actual_hours      │    │      user_id)           │
│     due_date          │    └─────────────────────────┘
│     completed_at      │
│     created_at        │
│     updated_at        │
│     created_by        │
│     updated_by        │
└───────────────────────┘

Legend:
PK  = Primary Key
FK  = Foreign Key
UNQ = Unique Constraint
*   = Many (in one-to-many relationship)
1   = One (in one-to-many relationship)
```

## Relationships

### projects → tasks (One-to-Many)

- **Type**: One-to-Many
- **Cardinality**: One project can have many tasks
- **Foreign Key**: `tasks.project_id` → `projects.id`
- **On Delete**: CASCADE (deleting a project deletes all its tasks)
- **Business Logic**: 
  - Tasks cannot exist without a project
  - Each task belongs to exactly one project
  - Tasks inherit context from their parent project

### projects → project_members (One-to-Many)

- **Type**: One-to-Many
- **Cardinality**: One project can have many members
- **Foreign Key**: `project_members.project_id` → `projects.id`
- **On Delete**: CASCADE (deleting a project removes all member assignments)
- **Constraints**: Unique constraint on (project_id, user_id) prevents duplicate assignments
- **Business Logic**:
  - A user can be assigned to multiple projects
  - A user can be assigned to a project only once
  - Each assignment has a specific role

## External References

The following fields reference entities in other services/databases:

### User References

- `projects.created_by` → User service
- `projects.updated_by` → User service
- `tasks.assigned_to` → User service
- `tasks.created_by` → User service
- `tasks.updated_by` → User service
- `project_members.user_id` → User service

**Note**: These are logical foreign keys, not enforced by database constraints. The Projects API is responsible for validating user IDs before writing to the database.

## Cascade Behaviors

### Deleting a Project

When a project is deleted:
1. All tasks associated with the project are automatically deleted (CASCADE)
2. All project member assignments are automatically deleted (CASCADE)

```sql
-- Example: Deleting project with id=1 will:
DELETE FROM projects WHERE id = 1;

-- Automatically delete from:
-- - tasks WHERE project_id = 1
-- - project_members WHERE project_id = 1
```

### No Cascade on User Deletion

User deletions are handled by the User service. When a user is deleted:
- The Projects API should be notified (via event or API call)
- Application logic should handle cleanup or reassignment
- Fields like `assigned_to`, `created_by`, etc. may be set to NULL or a system user ID
- Alternatively, historical records may be preserved with deleted user IDs

## Indexing Strategy

### projects table

- **Primary Index**: `id` (clustered)
- **Unique Index**: `project_code` (for fast lookup by business key)
- **Secondary Indexes**:
  - `status` - frequent filtering by project status
  - `priority` - filtering by priority
  - `(start_date, end_date)` - date range queries
  - `created_at` - temporal queries and sorting

### tasks table

- **Primary Index**: `id` (clustered)
- **Unique Index**: `(project_id, task_code)` - ensures task codes are unique within projects
- **Secondary Indexes**:
  - `project_id` - joining with projects, filtering by project
  - `status` - filtering by task status
  - `assigned_to` - finding tasks by assignee
  - `due_date` - finding upcoming or overdue tasks

### project_members table

- **Primary Index**: `id` (clustered)
- **Unique Index**: `(project_id, user_id)` - prevents duplicate assignments
- **Secondary Indexes**:
  - `project_id` - finding all members of a project
  - `user_id` - finding all projects for a user
  - `role` - filtering by role

## Common Query Patterns

### Get all tasks for a project

```sql
SELECT t.* 
FROM tasks t
WHERE t.project_id = ?
ORDER BY t.status, t.priority DESC;

-- Uses: idx_project_id
```

### Get all active projects with task counts

```sql
SELECT p.*, COUNT(t.id) as task_count
FROM projects p
LEFT JOIN tasks t ON p.id = t.project_id
WHERE p.status = 'active'
GROUP BY p.id;

-- Uses: idx_status on projects, idx_project_id on tasks
```

### Get all projects for a user

```sql
SELECT p.*
FROM projects p
INNER JOIN project_members pm ON p.id = pm.project_id
WHERE pm.user_id = ?;

-- Uses: idx_user_id on project_members
```

### Get overdue tasks

```sql
SELECT t.*, p.name as project_name
FROM tasks t
INNER JOIN projects p ON t.project_id = p.id
WHERE t.due_date < CURDATE()
  AND t.status NOT IN ('done', 'cancelled');

-- Uses: idx_due_date on tasks
```

### Get team members for a project

```sql
SELECT pm.*
FROM project_members pm
WHERE pm.project_id = ?
ORDER BY pm.role;

-- Uses: idx_project_id on project_members
```

## Future Enhancements

Potential schema additions to consider:

### Task Dependencies
- Table: `task_dependencies`
- Track which tasks depend on others
- Enable critical path analysis

### Project Comments/Notes
- Table: `project_comments`
- Allow team discussions on projects
- Audit trail of communications

### Task Attachments
- Table: `task_attachments`
- Link documents/files to tasks
- File metadata and references

### Time Tracking
- Table: `time_entries`
- Detailed time logging per task
- More granular than `actual_hours`

### Project Tags/Categories
- Table: `project_tags`, `tags`
- Flexible categorization
- Better filtering and organization

### Audit Log
- Table: `audit_log`
- Complete change history
- Compliance and troubleshooting

## Database Normalization

The current schema is in **Third Normal Form (3NF)**:

1. **1NF**: All columns contain atomic values
2. **2NF**: No partial dependencies (all non-key columns depend on the entire primary key)
3. **3NF**: No transitive dependencies (all non-key columns depend only on the primary key)

### Denormalization Considerations

Currently, there is minimal denormalization. Potential candidates for denormalization if performance requires:

- **Task count** on projects table (if frequently queried)
- **Cached project status** based on task completion (if computation is expensive)

These should only be added if profiling shows significant performance issues.

## Referential Integrity

### Enforced by Database

- tasks.project_id → projects.id (CASCADE on delete)
- project_members.project_id → projects.id (CASCADE on delete)

### Enforced by Application

- User ID references (created_by, updated_by, assigned_to, user_id)
  - Validated by Projects API
  - Coordinated with User service
  - No database-level constraints

## Schema Evolution

### Adding New Relationships

When adding new tables or relationships:

1. Create a migration in `/migrations`
2. Update this ERD document
3. Update `/docs/DATA_DICTIONARY.md`
4. Update `/schema/complete_schema.sql`
5. Consider impact on existing queries and indexes

### Modifying Relationships

When changing relationships:

1. Create a migration (never modify existing migrations)
2. Consider data migration needs
3. Update all documentation
4. Test with existing data
5. Plan for application code changes

---

Last Updated: 2025-12-21
Schema Version: V003
