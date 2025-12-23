# Database Schema Documentation

## Overview

This document describes the database schema for the **Lumanitech ERP Projects** module.

**Database Name:** `lumanitech_erp_projects`

**Character Set:** `utf8mb4`

**Collation:** `utf8mb4_unicode_ci`

**MySQL Version:** 8.0+

## Schema Organization

The schema is organized into the following directories:

```
schema/
├── 01_create_database.sql    # Database creation
├── tables/                    # Table definitions
│   ├── schema_migrations.sql
│   ├── projects.sql
│   ├── tasks.sql
│   └── project_members.sql
├── views/                     # Views (if any)
├── procedures/                # Stored procedures (if any)
├── functions/                 # Functions (if any)
├── triggers/                  # Triggers (if any)
└── indexes/                   # Additional indexes (if any)
```

## Tables

### schema_migrations

Tracks all applied database migrations.

**Purpose:** Migration version control and tracking

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| version | VARCHAR(50) | PRIMARY KEY | Migration version (e.g., V001, V002) |
| description | VARCHAR(255) | NOT NULL | Brief description of the migration |
| applied_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | When the migration was applied |

**Indexes:**
- PRIMARY KEY on `version`
- INDEX on `applied_at`

**Related Migrations:**
- V000_create_schema_migrations_table.sql

---

### projects

Main projects table storing project information.

**Purpose:** Core entity for project management

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PRIMARY KEY, AUTO_INCREMENT | Unique project identifier |
| project_code | VARCHAR(50) | NOT NULL, UNIQUE | Human-readable project code |
| name | VARCHAR(255) | NOT NULL | Project name |
| description | TEXT | NULL | Detailed project description |
| status | ENUM | NOT NULL, DEFAULT 'draft' | Current status: draft, active, on_hold, completed, cancelled |
| priority | ENUM | NOT NULL, DEFAULT 'medium' | Priority level: low, medium, high, critical |
| start_date | DATE | NULL | Planned or actual start date |
| end_date | DATE | NULL | Planned or actual end date |
| budget | DECIMAL(15,2) | NULL | Project budget |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| created_by | BIGINT UNSIGNED | NULL | User ID who created the project |
| updated_by | BIGINT UNSIGNED | NULL | User ID who last updated the project |

**Indexes:**
- PRIMARY KEY on `id`
- UNIQUE INDEX on `project_code`
- INDEX on `status`
- INDEX on `priority`
- INDEX on `(start_date, end_date)`
- INDEX on `created_at`

**Business Rules:**
- `project_code` must be unique across all projects
- `end_date` should be >= `start_date` (enforced at application level)
- User IDs (`created_by`, `updated_by`) reference users in the user service (external to this database)

**Related Migrations:**
- V001_create_projects_table.sql

---

### tasks

Stores individual tasks within projects.

**Purpose:** Track work items and deliverables within a project

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PRIMARY KEY, AUTO_INCREMENT | Unique task identifier |
| project_id | BIGINT UNSIGNED | NOT NULL, FK to projects.id | Associated project |
| task_code | VARCHAR(50) | NOT NULL | Task code (unique within project) |
| title | VARCHAR(255) | NOT NULL | Task title |
| description | TEXT | NULL | Detailed task description |
| status | ENUM | NOT NULL, DEFAULT 'todo' | Current status: todo, in_progress, review, done, blocked |
| priority | ENUM | NOT NULL, DEFAULT 'medium' | Priority level: low, medium, high, critical |
| assigned_to | BIGINT UNSIGNED | NULL | User ID assigned to the task |
| estimated_hours | DECIMAL(8,2) | NULL | Estimated work hours |
| actual_hours | DECIMAL(8,2) | NULL | Actual work hours |
| due_date | DATE | NULL | Task due date |
| completed_at | TIMESTAMP | NULL | When the task was completed |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |
| created_by | BIGINT UNSIGNED | NULL | User ID who created the task |
| updated_by | BIGINT UNSIGNED | NULL | User ID who last updated the task |

**Indexes:**
- PRIMARY KEY on `id`
- UNIQUE INDEX on `(project_id, task_code)`
- INDEX on `project_id`
- INDEX on `status`
- INDEX on `assigned_to`
- INDEX on `due_date`

**Foreign Keys:**
- `project_id` → `projects.id` (ON DELETE CASCADE)

**Business Rules:**
- `task_code` must be unique within a project (enforced by unique constraint)
- Tasks are deleted when their parent project is deleted (CASCADE)
- User IDs reference users in the user service (external to this database)

**Related Migrations:**
- V002_create_tasks_table.sql

---

### project_members

Tracks team members assigned to projects and their roles.

**Purpose:** Manage project team membership and access control

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PRIMARY KEY, AUTO_INCREMENT | Unique membership identifier |
| project_id | BIGINT UNSIGNED | NOT NULL, FK to projects.id | Associated project |
| user_id | BIGINT UNSIGNED | NOT NULL | User ID of the team member |
| role | ENUM | NOT NULL, DEFAULT 'viewer' | Role: owner, manager, developer, viewer |
| joined_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | When the member joined |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE | Last update timestamp |

**Indexes:**
- PRIMARY KEY on `id`
- UNIQUE INDEX on `(project_id, user_id)`
- INDEX on `project_id`
- INDEX on `user_id`
- INDEX on `role`

**Foreign Keys:**
- `project_id` → `projects.id` (ON DELETE CASCADE)

**Business Rules:**
- Each user can only be a member of a project once (enforced by unique constraint)
- Memberships are deleted when their parent project is deleted (CASCADE)
- User IDs reference users in the user service (external to this database)
- Role hierarchy and permissions are enforced at the application level

**Related Migrations:**
- V003_create_project_members_table.sql

---

## Relationships

### Entity Relationship Diagram

```
projects
    ├─── tasks (1:N, CASCADE DELETE)
    └─── project_members (1:N, CASCADE DELETE)
```

### Relationship Details

1. **projects → tasks**
   - Type: One-to-Many
   - Foreign Key: `tasks.project_id` → `projects.id`
   - Delete Rule: CASCADE (deleting a project deletes all its tasks)

2. **projects → project_members**
   - Type: One-to-Many
   - Foreign Key: `project_members.project_id` → `projects.id`
   - Delete Rule: CASCADE (deleting a project deletes all memberships)

## External References

The following fields reference entities in other services:

- `projects.created_by` → User service
- `projects.updated_by` → User service
- `tasks.assigned_to` → User service
- `tasks.created_by` → User service
- `tasks.updated_by` → User service
- `project_members.user_id` → User service

**Note:** These are logical references only. No foreign key constraints exist to external databases.

## Data Types

### ENUM Values

**project status:**
- `draft` - Project is being planned
- `active` - Project is in progress
- `on_hold` - Project is temporarily paused
- `completed` - Project has finished successfully
- `cancelled` - Project was cancelled

**project/task priority:**
- `low` - Low priority
- `medium` - Medium priority (default)
- `high` - High priority
- `critical` - Critical priority

**task status:**
- `todo` - Task not started
- `in_progress` - Task being worked on
- `review` - Task under review
- `done` - Task completed
- `blocked` - Task is blocked

**project_member role:**
- `owner` - Project owner (full control)
- `manager` - Project manager (can manage team and tasks)
- `developer` - Project developer (can work on tasks)
- `viewer` - Project viewer (read-only access)

## Indexes Strategy

### Primary Indexes
- All tables have an `id` PRIMARY KEY for efficient lookups
- Unique business keys (`project_code`, composite keys) for data integrity

### Secondary Indexes
- Status columns for filtering (`projects.status`, `tasks.status`)
- Foreign keys for join performance (`tasks.project_id`, `project_members.project_id`)
- Assignment tracking (`tasks.assigned_to`)
- Date-based queries (`tasks.due_date`, `projects.created_at`)
- Priority filtering (`projects.priority`, `tasks.priority`)

## Character Set & Collation

- **Character Set:** `utf8mb4` - Full Unicode support including emojis
- **Collation:** `utf8mb4_unicode_ci` - Case-insensitive Unicode collation
- **Engine:** InnoDB - ACID compliance, foreign key support, row-level locking

## Migration History

To view all applied migrations:

```sql
SELECT version, description, applied_at
FROM schema_migrations
ORDER BY version;
```

## Schema Updates

All schema changes must be made through versioned migrations. See [migration-strategy.md](migration-strategy.md) for details.

**Never modify:**
- Schema files directly in production
- Existing migration files
- The database schema manually

**Always:**
- Create new migration files for changes
- Test migrations on development databases first
- Document breaking changes

## See Also

- [migration-strategy.md](migration-strategy.md) - Migration guidelines and best practices
- [../migrations/README.md](../migrations/README.md) - Migration file documentation
- [DATABASE_DESIGN.md](DATABASE_DESIGN.md) - Design decisions and rationale
- [DATA_DICTIONARY.md](DATA_DICTIONARY.md) - Detailed field descriptions
