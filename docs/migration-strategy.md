# Migration Strategy

## Overview

This database follows a **forward-only migration strategy** for schema versioning and evolution. All schema changes are tracked through versioned migration scripts that are applied sequentially.

## Core Principles

### 1. Forward-Only Approach

- **Never modify existing migrations**: Once a migration is committed and deployed, it becomes immutable.
- **Create new migrations for changes**: To fix issues or modify schema, always create a new migration.
- **Sequential versioning**: Migrations are numbered sequentially (V000, V001, V002, ...) and must be applied in order.
- **No rollbacks**: This strategy does not support automatic rollbacks. Instead, create corrective migrations.

### 2. Migration Tracking

All applied migrations are recorded in the `schema_migrations` table:

```sql
CREATE TABLE schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description VARCHAR(255) NOT NULL,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_applied_at (applied_at)
);
```

Each migration automatically inserts its own record:

```sql
INSERT INTO schema_migrations (version, description)
VALUES ('V001', 'create_projects_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

## Migration Naming Convention

### Format

```
V###_description.sql
```

### Components

- **V**: Prefix indicating a versioned migration
- **###**: Three-digit zero-padded version number (000, 001, 002, ...)
- **_**: Single underscore separator
- **description**: Snake_case description of the change
- **.sql**: File extension

### Examples

```
V000_create_schema_migrations_table.sql
V001_create_projects_table.sql
V002_create_tasks_table.sql
V003_create_project_members_table.sql
V004_add_archived_flag_to_projects.sql
V005_create_index_on_project_status.sql
```

## Creating a Migration

### Step 1: Determine the Version Number

Find the latest migration:

```bash
ls -1 migrations/V*.sql | tail -1
```

Your new migration should use the next sequential number.

### Step 2: Copy the Template

```bash
cp migrations/TEMPLATE.sql migrations/V004_your_description.sql
```

### Step 3: Write the Migration

Edit the file and replace placeholders:

```sql
-- =============================================================================
-- Migration: V004_add_archived_flag_to_projects
-- Description: Add archived flag to projects table
-- Author: Your Name
-- Date: YYYY-MM-DD
-- =============================================================================

-- Add archived column
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS archived BOOLEAN NOT NULL DEFAULT FALSE;

-- Add index for archived column
CREATE INDEX IF NOT EXISTS idx_archived ON projects(archived);

-- =============================================================================
-- Migration Tracking
-- =============================================================================
INSERT INTO schema_migrations (version, description)
VALUES ('V004', 'add_archived_flag_to_projects')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### Step 4: Test the Migration

```bash
# Apply to a test database
mysql -u root -p test_db < migrations/V004_add_archived_flag_to_projects.sql

# Verify idempotency - should run without errors
mysql -u root -p test_db < migrations/V004_add_archived_flag_to_projects.sql
```

### Step 5: Validate

```bash
# Validate naming and syntax
./scripts/validate.sh
```

## Idempotency

All migrations must be idempotent (safe to run multiple times).

### Techniques

**Creating Tables:**
```sql
CREATE TABLE IF NOT EXISTS table_name (
    ...
);
```

**Adding Columns:**
```sql
ALTER TABLE table_name
ADD COLUMN IF NOT EXISTS column_name VARCHAR(255);
```

**Creating Indexes:**
```sql
CREATE INDEX IF NOT EXISTS idx_name ON table_name(column_name);
```

**Inserting Data:**
```sql
INSERT INTO table_name (id, name)
VALUES (1, 'value')
ON DUPLICATE KEY UPDATE name = VALUES(name);
```

## Common Patterns

### Adding a Column

```sql
-- Migration: V004_add_priority_to_tasks
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS priority ENUM('low', 'medium', 'high') 
NOT NULL DEFAULT 'medium';

INSERT INTO schema_migrations (version, description)
VALUES ('V004', 'add_priority_to_tasks')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### Creating an Index

```sql
-- Migration: V005_add_index_on_task_status
CREATE INDEX IF NOT EXISTS idx_task_status 
ON tasks(status);

INSERT INTO schema_migrations (version, description)
VALUES ('V005', 'add_index_on_task_status')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### Renaming a Column

**DO NOT** use `RENAME COLUMN` as it's not idempotent. Instead:

```sql
-- Migration: V006_rename_task_title_to_name
-- Add new column
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS name VARCHAR(255);

-- Copy data (only if name is NULL)
UPDATE tasks
SET name = title
WHERE name IS NULL;

-- Mark old column for removal in next migration
-- DO NOT DROP in the same migration!

INSERT INTO schema_migrations (version, description)
VALUES ('V006', 'rename_task_title_to_name')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

Then in the next migration:
```sql
-- Migration: V007_drop_old_task_title_column
ALTER TABLE tasks
DROP COLUMN IF EXISTS title;

INSERT INTO schema_migrations (version, description)
VALUES ('V007', 'drop_old_task_title_column')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

## Best Practices

### DO

✅ **Test migrations on a local database first**
✅ **Use IF NOT EXISTS / IF EXISTS for idempotency**
✅ **Keep migrations small and focused**
✅ **Document breaking changes in comments**
✅ **Consider data migration along with schema changes**
✅ **Use transactions for data modifications**

### DON'T

❌ **Never modify an existing migration file**
❌ **Never skip version numbers**
❌ **Never hard-code environment-specific values**
❌ **Never drop tables or columns without careful consideration**
❌ **Never mix schema and data changes in complex ways**

## Handling Conflicts

### Version Number Conflicts

If two developers create migrations with the same version number:

1. The second developer must renumber their migration
2. Update the version in both the filename and the INSERT statement
3. Retest the migration
4. Coordinate with the team to avoid future conflicts

### Failed Migrations

If a migration fails in production:

1. **DO NOT** modify the failed migration
2. Investigate the root cause
3. Create a new corrective migration
4. Document what went wrong and how it was fixed

## Deployment Process

### Development

```bash
# Apply all pending migrations
./scripts/deploy.sh
```

### Production

```bash
# 1. Backup database
mysqldump -u user -p database_name > backup.sql

# 2. Apply migrations
./scripts/deploy.sh

# 3. Verify migration table
mysql -u user -p -D database_name -e "SELECT * FROM schema_migrations ORDER BY version;"
```

## Monitoring

### Check Applied Migrations

```sql
SELECT version, description, applied_at
FROM schema_migrations
ORDER BY version;
```

### Check Pending Migrations

Compare migration files in `migrations/` directory with records in `schema_migrations` table.

## Troubleshooting

### Migration Already Applied

If a migration was already applied but is being run again:
- This is normal for idempotent migrations
- The `ON DUPLICATE KEY UPDATE` clause will update the timestamp
- No schema changes will occur if using `IF NOT EXISTS` / `IF EXISTS`

### Migration Fails Midway

If a migration partially completes:
1. Check `schema_migrations` table - was it recorded?
2. Manually verify what schema changes were applied
3. Create a corrective migration to complete or undo the change
4. Never manually modify the failed migration

### Orphaned Migration Files

If migration files exist but aren't in `schema_migrations`:
- These migrations have not been applied
- Apply them using `./scripts/deploy.sh`
- Or apply manually in order

## See Also

- [migrations/README.md](../migrations/README.md) - Detailed migration guidelines
- [migrations/TEMPLATE.sql](../migrations/TEMPLATE.sql) - Migration template
- [schema.md](schema.md) - Current schema documentation
