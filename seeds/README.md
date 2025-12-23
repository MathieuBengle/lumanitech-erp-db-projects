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

## Directory Structure

```
seeds/
└── dev/           # Development seed data
```

## Loading Seed Data

### Using the Deploy Script (Recommended)

```bash
# Load seeds during initial setup
./scripts/deploy.sh --with-seeds
```

### Using the Load Seeds Script

```bash
# With login-path (recommended)
./scripts/load-seeds.sh --login-path=local -d lumanitech_erp_projects

# With environment variable
export MYSQL_LOGIN_PATH=local
./scripts/load-seeds.sh -d lumanitech_erp_projects
```

### Manual Loading

```bash
# Load seeds in order from dev directory
mysql -u root -p lumanitech_erp_projects < seeds/dev/01_sample_projects.sql
mysql -u root -p lumanitech_erp_projects < seeds/dev/02_sample_tasks.sql
mysql -u root -p lumanitech_erp_projects < seeds/dev/03_sample_project_members.sql
```

## Current Seed Files

All seed files are located in `seeds/dev/`:

1. **`01_sample_projects.sql`** - Sample project records
2. **`02_sample_tasks.sql`** - Sample task records for the projects
3. **`03_sample_project_members.sql`** - Sample team member assignments

## Creating New Seed Files

### Step 1: Determine the Order

New seed files should be numbered sequentially based on their dependencies:
- Tables with no foreign keys first
- Tables with foreign keys after their parent tables

All seed files should be created in the `seeds/dev/` directory.

### Step 2: Create the File

```bash
touch seeds/dev/04_your_seed_data.sql
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

## Resetting Development Database

To start fresh:

```bash
# Drop and recreate database
mysql -u root -p -e "DROP DATABASE IF EXISTS lumanitech_erp_projects;"
mysql -u root -p -e "CREATE DATABASE lumanitech_erp_projects CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Apply migrations and seeds using deploy script
./scripts/deploy.sh --with-seeds

# Or manually apply schema and seeds
mysql -u root -p lumanitech_erp_projects < schema/complete_schema.sql
./scripts/load-seeds.sh --login-path=local -d lumanitech_erp_projects
```

## See Also

- `/migrations` - Database schema migrations
- `/schema` - Current database schema
- `/scripts/load-seeds.sh` - Utility script for loading seeds
