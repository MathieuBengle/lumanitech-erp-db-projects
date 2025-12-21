# Seeds Directory

This directory contains sample data scripts for development and testing purposes.

## Purpose

Seed data is used to:
- Populate development databases with realistic sample data
- Provide test data for automated testing
- Demonstrate the database structure with examples
- Enable developers to start working immediately without creating test data manually

## ⚠️ Important Warning

**NEVER use seed data in production environments!**

- Seed data is for development and testing only
- Contains fake/sample data
- May contain predictable or insecure values
- Should be excluded from production deployments

## File Naming Convention

Seed files are numbered to ensure they are loaded in the correct order:

```
{number}_{description}.sql
```

Examples:
- `01_sample_projects.sql`
- `02_sample_tasks.sql`
- `03_sample_project_members.sql`

## Current Seed Files

1. **`01_sample_projects.sql`** - Sample project records
2. **`02_sample_tasks.sql`** - Sample task records for the projects
3. **`03_sample_project_members.sql`** - Sample team member assignments

## Loading Seed Data

### Using the Utility Script

```bash
# Load all seed files
./scripts/load-seeds.sh lumanitech_projects localhost root

# The script will prompt for password
```

### Manual Loading

```bash
# Load seeds in order
mysql -u root -p lumanitech_projects < seeds/01_sample_projects.sql
mysql -u root -p lumanitech_projects < seeds/02_sample_tasks.sql
mysql -u root -p lumanitech_projects < seeds/03_sample_project_members.sql
```

### Loading Individual Seeds

```bash
# Load a specific seed file
mysql -u root -p lumanitech_projects < seeds/01_sample_projects.sql
```

## Creating New Seed Files

### Step 1: Determine the Order

New seed files should be numbered sequentially based on their dependencies:
- Tables with no foreign keys first
- Tables with foreign keys after their parent tables

### Step 2: Create the File

```bash
touch seeds/04_your_seed_data.sql
```

### Step 3: Write Idempotent Seeds

Use `INSERT ... ON DUPLICATE KEY UPDATE` or `INSERT IGNORE` to make seeds idempotent:

```sql
-- Good: Can be run multiple times
INSERT INTO projects (project_code, name, status)
VALUES ('PROJ-999', 'Test Project', 'draft')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- Also good: Ignores duplicates
INSERT IGNORE INTO projects (project_code, name, status)
VALUES ('PROJ-999', 'Test Project', 'draft');
```

### Step 4: Add Header Comments

```sql
-- =============================================================================
-- Seed Data: Description
-- Description: Detailed description of what this seed provides
-- WARNING: Do not use in production!
-- =============================================================================
```

## Best Practices

### DO:

- ✅ Make seeds idempotent (can be run multiple times)
- ✅ Use realistic but fake data
- ✅ Include a variety of test scenarios
- ✅ Document the purpose of each seed file
- ✅ Keep seeds small and focused
- ✅ Use consistent test data patterns
- ✅ Include edge cases in test data

### DON'T:

- ❌ Include real user data or PII
- ❌ Use production data
- ❌ Include sensitive information (passwords, keys, etc.)
- ❌ Create seeds that fail on re-run
- ❌ Include environment-specific data
- ❌ Hardcode IDs unless necessary for relationships

## Sample Data Guidelines

### User References

Seeds reference user IDs (created_by, assigned_to, etc.) assuming users 1-10 exist:
- User 1: Project manager
- User 2: Database specialist
- User 3: Frontend developer
- User 4: Backend developer
- User 5: QA tester
- User 6-10: Additional team members

These users should be created in your user service/database.

### Dates

- Use realistic date ranges
- Include past, current, and future dates
- Consider business rules (e.g., end_date > start_date)

### Status Values

Include various statuses to test different scenarios:
- Active/in-progress items
- Completed items
- Draft/pending items
- Cancelled/failed items

## Environment-Specific Seeds

For different environments, you can create environment-specific seed directories:

```
seeds/
├── development/    # Rich sample data
├── testing/        # Minimal test fixtures
└── staging/        # Production-like sample data
```

Then load the appropriate set:

```bash
mysql -u root -p lumanitech_projects < seeds/development/*.sql
```

## Resetting Development Database

To start fresh:

```bash
# Drop and recreate database
mysql -u root -p -e "DROP DATABASE IF EXISTS lumanitech_projects;"
mysql -u root -p -e "CREATE DATABASE lumanitech_projects CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Apply schema
mysql -u root -p lumanitech_projects < schema/complete_schema.sql

# Load seeds
./scripts/load-seeds.sh lumanitech_projects localhost root
```

## See Also

- `/migrations` - Database schema migrations
- `/schema` - Current database schema
- `/scripts/load-seeds.sh` - Utility script for loading seeds
