# Migrations Directory

This directory contains versioned SQL migration scripts for the Lumanitech ERP Projects database.

## Migration Strategy

This repository follows a **forward-only migration strategy**. This means:

- ✅ Migrations are applied sequentially and are never modified once committed
- ✅ To fix an issue in a migration, create a new migration
- ✅ Migrations should be idempotent (safe to run multiple times)
- ✅ Each migration is versioned and has a descriptive name

## Naming Convention

All migration files follow this pattern:

```
V{version}__description.sql
```

### Components:

- **V**: Required prefix indicating a versioned migration
- **{version}**: Zero-padded sequential number (001, 002, 003, ...)
- **__**: Double underscore separator (required)
- **{description}**: Snake_case description of the change
- **.sql**: File extension

### Examples:

```
V001__create_projects_table.sql
V002__create_tasks_table.sql
V003__create_project_members_table.sql
V004__add_index_to_projects_status.sql
V005__add_archived_flag_to_projects.sql
```

## Creating a New Migration

### Step 1: Determine the Next Version Number

```bash
# List existing migrations
ls -1 migrations/

# Your new migration should be the next sequential number
```

### Step 2: Create the Migration File

```bash
# Template
touch migrations/V00X__your_description.sql
```

### Step 3: Write the Migration

```sql
-- =============================================================================
-- Migration: V00X__your_description.sql
-- Description: Brief description of what this migration does
-- Author: Your Name
-- Date: YYYY-MM-DD
-- =============================================================================

-- Your SQL statements here
-- Use IF NOT EXISTS where possible for idempotency

CREATE TABLE IF NOT EXISTS your_table (
    -- columns
);

-- Or for alterations
ALTER TABLE existing_table 
ADD COLUMN IF NOT EXISTS new_column VARCHAR(255);
```

### Step 4: Test the Migration

```bash
# Test on a local database
mysql -u root -p test_database < migrations/V00X__your_description.sql

# Verify it can be run multiple times (idempotency)
mysql -u root -p test_database < migrations/V00X__your_description.sql
```

### Step 5: Update Schema Documentation

After creating and testing your migration:

```bash
# Update the complete schema file
mysqldump -u root -p --no-data --skip-comments lumanitech_projects > schema/complete_schema.sql
```

### Step 6: Validate and Commit

```bash
# Run validation script
./scripts/validate-migrations.sh

# Commit both migration and schema
git add migrations/V00X__your_description.sql
git add schema/complete_schema.sql
git commit -m "Add migration: your description"
```

## Migration Guidelines

### DO:

- ✅ Use `IF NOT EXISTS` for CREATE statements
- ✅ Use `IF EXISTS` for DROP statements
- ✅ Include comments explaining complex changes
- ✅ Consider data migration along with schema changes
- ✅ Use transactions for data modifications
- ✅ Test on a database with existing data
- ✅ Add indexes for frequently queried columns
- ✅ Use appropriate data types and constraints

### DON'T:

- ❌ Modify existing migration files after they're committed
- ❌ Skip version numbers
- ❌ Use database-specific syntax without comments
- ❌ Forget to update the schema documentation
- ❌ Include environment-specific configurations
- ❌ Add sensitive data in migrations
- ❌ Create migrations that can't be applied idempotently

## Common Migration Patterns

### Adding a Column

```sql
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS archived BOOLEAN NOT NULL DEFAULT FALSE;

-- Add index if needed
CREATE INDEX IF NOT EXISTS idx_archived ON projects(archived);
```

### Creating a Table

```sql
CREATE TABLE IF NOT EXISTS new_table (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Adding a Foreign Key

```sql
ALTER TABLE child_table
ADD CONSTRAINT IF NOT EXISTS fk_child_parent 
    FOREIGN KEY (parent_id) REFERENCES parent_table(id) 
    ON DELETE CASCADE;
```

### Data Migration

```sql
-- Use transactions for data changes
START TRANSACTION;

UPDATE projects 
SET status = 'completed' 
WHERE end_date < CURDATE() AND status = 'active';

COMMIT;
```

## Applying Migrations

### Using Validation Scripts

```bash
# Validate migration syntax
./scripts/validate-migrations.sh

# Apply all pending migrations
./scripts/apply-migrations.sh lumanitech_projects localhost root
```

### Manual Application

```bash
# Apply migrations in order
mysql -u root -p lumanitech_projects < migrations/V001__create_projects_table.sql
mysql -u root -p lumanitech_projects < migrations/V002__create_tasks_table.sql
mysql -u root -p lumanitech_projects < migrations/V003__create_project_members_table.sql
```

### Using Flyway (Recommended)

```bash
# Install Flyway
# https://flywaydb.org/

# Configure flyway.conf with your database settings
flyway migrate
```

## Troubleshooting

### Version Conflicts

If two developers create the same version number:

1. The second developer should renumber their migration
2. Update the filename to the next available version
3. Test thoroughly before merging

### Failed Migration

If a migration fails:

1. **DO NOT** modify the failed migration file
2. Investigate the error
3. Create a new migration to fix the issue
4. Document what went wrong and how it was fixed

### Idempotency Issues

If a migration can't be run multiple times:

1. Use `IF NOT EXISTS` / `IF EXISTS` clauses
2. Check for existence before making changes
3. Use `INSERT IGNORE` or `ON DUPLICATE KEY UPDATE` for data

## See Also

- `/schema` - Current database schema
- `/scripts` - Validation and utility scripts
- Main README.md - Overall project documentation
