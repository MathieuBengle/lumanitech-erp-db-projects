# Contributing to Lumanitech ERP - Projects Database

Thank you for your interest in contributing to the Projects Database repository! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Repository Structure](#repository-structure)
- [Development Workflow](#development-workflow)
- [Migration Guidelines](#migration-guidelines)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)

## Code of Conduct

This project adheres to a code of professional conduct. By participating, you are expected to:

- Be respectful and inclusive
- Focus on constructive feedback
- Prioritize the project's best interests
- Maintain confidentiality of sensitive information

## Getting Started

### Prerequisites

- MySQL 8.0+
- MySQL client tools (`mysql`, `mysql_config_editor`)
- Bash shell (Linux, macOS, or WSL2)
- Git

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MathieuBengle/lumanitech-erp-db-projects.git
   cd lumanitech-erp-db-projects
   ```

2. **Configure MySQL authentication:**
   ```bash
   ./scripts/setup_login.sh
   ```

3. **Set up local database:**
   ```bash
   ./scripts/deploy.sh --login-path=local -d lumanitech_erp_projects --with-seeds
   ```

## Repository Structure

```
.
├── CONTRIBUTING.md          # This file
├── README.md               # Project overview
├── docs/                   # Documentation
│   ├── migration-strategy.md
│   ├── schema.md
│   └── ...
├── migrations/             # Versioned migration scripts
│   ├── TEMPLATE.sql
│   ├── README.md
│   └── V###_*.sql
├── schema/                 # Current schema definitions
│   ├── 01_create_database.sql
│   ├── tables/
│   ├── views/
│   ├── procedures/
│   ├── functions/
│   ├── triggers/
│   └── indexes/
├── seeds/                  # Sample data
│   ├── README.md
│   └── dev/
└── scripts/                # Utility scripts
    ├── deploy.sh
    ├── validate.sh
    └── README.md
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

Follow the guidelines in this document for:
- Creating migrations
- Updating schema
- Adding seed data
- Updating documentation

### 3. Validate Your Changes

```bash
# Validate migrations and schema
./scripts/validate.sh

# Test migrations on a clean database
./scripts/deploy.sh --login-path=local -d test_db --force
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "Type: Brief description

Detailed explanation of changes"
```

**Commit message types:**
- `feat:` New feature or migration
- `fix:` Bug fix or corrective migration
- `docs:` Documentation updates
- `refactor:` Code refactoring
- `test:` Test updates
- `chore:` Maintenance tasks

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

## Migration Guidelines

### Creating a New Migration

1. **Determine the next version number:**
   ```bash
   ls -1 migrations/V*.sql | tail -1
   ```

2. **Copy the template:**
   ```bash
   cp migrations/TEMPLATE.sql migrations/V004_your_description.sql
   ```

3. **Edit the migration:**
   - Update the header with version, description, author, and date
   - Write your SQL statements
   - Use `IF NOT EXISTS` / `IF EXISTS` for idempotency
   - Update the schema_migrations INSERT statement

4. **Example migration:**
   ```sql
   -- =============================================================================
   -- Migration: V004_add_archived_flag_to_projects
   -- Description: Add archived flag to projects table
   -- Author: Your Name
   -- Date: 2025-12-23
   -- =============================================================================

   ALTER TABLE projects 
   ADD COLUMN IF NOT EXISTS archived BOOLEAN NOT NULL DEFAULT FALSE;

   CREATE INDEX IF NOT EXISTS idx_archived ON projects(archived);

   -- =============================================================================
   -- Migration Tracking
   -- =============================================================================
   INSERT INTO schema_migrations (version, description)
   VALUES ('V004', 'add_archived_flag_to_projects')
   ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
   ```

### Migration Naming Convention

- **Format:** `V###_description.sql`
- **Version:** Three-digit number (V000, V001, V002, ...)
- **Separator:** Single underscore (`_`)
- **Description:** Snake_case, descriptive (e.g., `create_projects_table`, `add_archived_flag`)

### Migration Best Practices

**DO:**
- ✅ Test migrations on a local database first
- ✅ Make migrations idempotent
- ✅ Keep migrations focused and small
- ✅ Document complex changes with comments
- ✅ Update schema files after migrations

**DON'T:**
- ❌ Modify existing migrations
- ❌ Skip version numbers
- ❌ Include environment-specific values
- ❌ Mix schema and data changes carelessly
- ❌ Forget to update schema_migrations table

## Testing

### Validate Changes

```bash
# Run all validations
./scripts/validate.sh
```

### Test Migrations

```bash
# Test on a fresh database
./scripts/deploy.sh --login-path=local -d test_lumanitech_erp_projects --force

# Test idempotency
./scripts/deploy.sh --login-path=local -d test_lumanitech_erp_projects
```

### Manual Testing

```bash
# Apply your migration
mysql --login-path=local -D test_db < migrations/V004_your_migration.sql

# Verify changes
mysql --login-path=local -D test_db -e "DESCRIBE projects;"

# Test idempotency
mysql --login-path=local -D test_db < migrations/V004_your_migration.sql
```

## Pull Request Process

### Before Submitting

1. ✅ All validations pass (`./scripts/validate.sh`)
2. ✅ Migrations tested on a clean database
3. ✅ Schema files updated to reflect changes
4. ✅ Documentation updated (if applicable)
5. ✅ No merge conflicts with main branch

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New migration
- [ ] Schema update
- [ ] Documentation update
- [ ] Bug fix
- [ ] Other (specify)

## Changes Made
- Migration: V00X_description.sql
- Updated schema files
- Updated documentation

## Testing
- [ ] Validated with ./scripts/validate.sh
- [ ] Tested on clean database
- [ ] Tested idempotency
- [ ] Manual verification completed

## Checklist
- [ ] Migration follows naming convention
- [ ] Migration is idempotent
- [ ] Schema files updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process

1. Automated checks run on PR creation
2. Code review by maintainers
3. Approval required before merge
4. Squash and merge to main branch

## Coding Standards

### SQL Style

- Use **UPPERCASE** for SQL keywords (`CREATE`, `SELECT`, `ALTER`, etc.)
- Use **snake_case** for table and column names
- Indent nested statements consistently
- Add comments for complex logic
- Use explicit column names (avoid `SELECT *`)

### Example

```sql
-- Good
CREATE TABLE IF NOT EXISTS projects (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bad
create table projects (id int, code varchar(50), name text);
```

### File Organization

- One statement per file (for schema files)
- Group related statements in migrations
- Use clear, descriptive filenames
- Include header comments in all SQL files

### Documentation

- Update README.md for significant changes
- Update docs/schema.md when schema changes
- Add inline comments for complex logic
- Keep migration comments up to date

## Seed Data

### Creating Seed Files

Seed files go in `seeds/dev/`:

```bash
touch seeds/dev/04_your_seed_data.sql
```

### Seed Data Guidelines

- Use realistic but fake data
- Make seeds idempotent (`INSERT ... ON DUPLICATE KEY UPDATE`)
- Number files for proper ordering
- Never include real user data or PII
- Document the purpose in file header

### Example Seed

```sql
-- =============================================================================
-- Seed Data: Sample Projects
-- Description: Development sample data for projects
-- WARNING: Do not use in production!
-- =============================================================================

INSERT INTO projects (project_code, name, status, priority)
VALUES 
    ('PROJ-001', 'Sample Project 1', 'active', 'high'),
    ('PROJ-002', 'Sample Project 2', 'draft', 'medium')
ON DUPLICATE KEY UPDATE 
    name = VALUES(name),
    status = VALUES(status),
    priority = VALUES(priority);
```

## Questions or Issues?

- **Documentation:** Check [README.md](README.md) and [docs/](docs/)
- **Issues:** Open a GitHub issue
- **Questions:** Contact the Projects API Team

## License

Internal use only - Lumanitech ERP System

---

Thank you for contributing to the Lumanitech ERP Projects Database! 🚀
