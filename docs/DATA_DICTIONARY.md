# Data Dictionary

Complete reference for all tables, columns, and data types in the Lumanitech ERP Projects database.

## Table of Contents

- [projects](#projects)
- [tasks](#tasks)
- [project_members](#project_members)

---

## projects

Main table for storing project information.

### Purpose
Stores core project data including metadata, timeline, budget, and current status.

### Columns

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | Primary key, unique project identifier |
| project_code | VARCHAR(50) | NO | - | Business key, human-readable unique project code |
| name | VARCHAR(255) | NO | - | Project name/title |
| description | TEXT | YES | NULL | Detailed project description |
| status | ENUM | NO | 'draft' | Current project status (draft, active, on_hold, completed, cancelled) |
| priority | ENUM | NO | 'medium' | Project priority level (low, medium, high, critical) |
| start_date | DATE | YES | NULL | Planned or actual project start date |
| end_date | DATE | YES | NULL | Planned or actual project end date |
| budget | DECIMAL(15,2) | YES | NULL | Project budget in currency units |
| created_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record last update timestamp |
| created_by | BIGINT UNSIGNED | YES | NULL | User ID who created the project |
| updated_by | BIGINT UNSIGNED | YES | NULL | User ID who last updated the project |

### Indexes

- PRIMARY KEY (id)
- UNIQUE KEY (project_code)
- INDEX idx_status (status)
- INDEX idx_priority (priority)
- INDEX idx_dates (start_date, end_date)
- INDEX idx_created_at (created_at)

### Status Values

- **draft**: Project is being planned, not yet active
- **active**: Project is currently in progress
- **on_hold**: Project is temporarily paused
- **completed**: Project has been finished successfully
- **cancelled**: Project was terminated before completion

### Priority Values

- **low**: Can be deferred, not urgent
- **medium**: Normal priority, standard timeline
- **high**: Important, should be prioritized
- **critical**: Urgent, requires immediate attention

### Business Rules

- `project_code` must be unique across all projects
- `end_date` should be >= `start_date` (enforced by application)
- `budget` is in decimal format to handle currency accurately
- Foreign key references to user IDs are not enforced (managed by user service)

---

## tasks

Table for storing individual tasks within projects.

### Purpose
Tracks granular work items, assignments, and progress within each project.

### Columns

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | Primary key, unique task identifier |
| project_id | BIGINT UNSIGNED | NO | - | Foreign key to projects table |
| task_code | VARCHAR(50) | NO | - | Task code, unique within project |
| title | VARCHAR(255) | NO | - | Task title/summary |
| description | TEXT | YES | NULL | Detailed task description |
| status | ENUM | NO | 'todo' | Current task status |
| priority | ENUM | NO | 'medium' | Task priority level |
| assigned_to | BIGINT UNSIGNED | YES | NULL | User ID of assignee |
| estimated_hours | DECIMAL(8,2) | YES | NULL | Estimated effort in hours |
| actual_hours | DECIMAL(8,2) | YES | NULL | Actual time spent in hours |
| due_date | DATE | YES | NULL | Task deadline |
| completed_at | TIMESTAMP | YES | NULL | When the task was completed |
| created_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record last update timestamp |
| created_by | BIGINT UNSIGNED | YES | NULL | User ID who created the task |
| updated_by | BIGINT UNSIGNED | YES | NULL | User ID who last updated the task |

### Indexes

- PRIMARY KEY (id)
- UNIQUE KEY uk_project_task_code (project_id, task_code)
- INDEX idx_project_id (project_id)
- INDEX idx_status (status)
- INDEX idx_assigned_to (assigned_to)
- INDEX idx_due_date (due_date)

### Foreign Keys

- CONSTRAINT fk_tasks_project: project_id REFERENCES projects(id) ON DELETE CASCADE

### Status Values

- **todo**: Task is planned but not started
- **in_progress**: Task is actively being worked on
- **review**: Task is completed and awaiting review
- **done**: Task is completed and approved
- **blocked**: Task cannot proceed due to dependencies or issues

### Priority Values

Same as projects table: low, medium, high, critical

### Business Rules

- `task_code` must be unique within each project (composite unique key)
- Tasks are deleted when their parent project is deleted (CASCADE)
- `completed_at` should be set when status changes to 'done'
- `actual_hours` should be <= `estimated_hours` ideally (enforced by application)
- Foreign key references to user IDs are not enforced (managed by user service)

---

## project_members

Table for tracking team members assigned to projects.

### Purpose
Manages project team composition and member roles.

### Columns

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | Primary key, unique assignment identifier |
| project_id | BIGINT UNSIGNED | NO | - | Foreign key to projects table |
| user_id | BIGINT UNSIGNED | NO | - | User ID from user service |
| role | ENUM | NO | 'viewer' | Member's role in the project |
| joined_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | When the member joined the project |
| created_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record last update timestamp |

### Indexes

- PRIMARY KEY (id)
- UNIQUE KEY uk_project_user (project_id, user_id)
- INDEX idx_project_id (project_id)
- INDEX idx_user_id (user_id)
- INDEX idx_role (role)

### Foreign Keys

- CONSTRAINT fk_project_members_project: project_id REFERENCES projects(id) ON DELETE CASCADE

### Role Values

- **owner**: Project owner, full control over project
- **manager**: Project manager, can manage tasks and team
- **developer**: Team member working on tasks
- **viewer**: Read-only access to project information

### Business Rules

- A user can be assigned to a project only once (composite unique key on project_id, user_id)
- Members are removed when their project is deleted (CASCADE)
- At least one member should have 'owner' role per project (enforced by application)
- Role changes should be logged/audited (application responsibility)

---

## Common Data Types

### BIGINT UNSIGNED
- Range: 0 to 18,446,744,073,709,551,615
- Used for all ID fields
- Future-proof for large-scale systems

### VARCHAR
- Variable-length strings
- More efficient than CHAR for variable-length data
- Used for names, codes, and short text

### TEXT
- Large text fields
- Used for descriptions and long-form content
- No default values allowed

### ENUM
- String representation of predefined values
- Stored as integers internally
- Schema change required to add new values

### DECIMAL(p,s)
- Fixed-point numbers
- p = precision (total digits)
- s = scale (digits after decimal)
- Used for currency and hours to avoid floating-point errors

### TIMESTAMP
- Date and time with timezone
- Automatic updates supported
- Range: 1970-01-01 00:00:01 UTC to 2038-01-19 03:14:07 UTC

### DATE
- Date without time
- Format: YYYY-MM-DD
- Range: 1000-01-01 to 9999-12-31

---

## Character Set and Collation

All tables use:
- **Character Set**: utf8mb4
- **Collation**: utf8mb4_unicode_ci

This provides:
- Full Unicode support including emojis
- Case-insensitive comparisons
- International character support

---

## Maintenance Notes

When updating this data dictionary:
1. Keep it synchronized with actual schema
2. Update after each migration
3. Document all ENUM value changes
4. Note any business rule changes
5. Update indexes when they change

Last Updated: 2025-12-21
