# Lumanitech ERP - Projects Database

This repository contains the MySQL database schema, migrations, and seed data for the Lumanitech ERP Projects module.

## Database Ownership

**This database is owned and managed by the Projects API service.**

The Projects API is the single source of truth for:
- Schema definitions
- Data integrity rules
- Business logic related to project management
- Database migrations and versioning

Other services should interact with project data **only** through the Projects API endpoints, never directly accessing the database.

## Repository Structure

```
.
├── schema/              # Current database schema definitions
├── migrations/          # Forward-only versioned migration scripts
├── seeds/              # Sample and test data
├── docs/               # Database documentation
├── scripts/            # CI/CD validation and utility scripts
└── README.md           # This file
```

### Folders

- **`schema/`**: Contains the current complete database schema. This represents the state after all migrations have been applied.
- **`migrations/`**: Version-controlled SQL migration scripts following a forward-only strategy.
- **`seeds/`**: Sample data for development and testing environments.
- **`docs/`**: Database documentation including entity-relationship diagrams, data dictionaries, and design decisions.
- **`scripts/`**: Validation scripts for CI/CD pipelines and utility scripts for database management.

## Migration Strategy

This repository follows a **forward-only migration strategy**:

### Principles

1. **Never modify existing migrations**: Once a migration is committed and deployed, it should never be altered.
2. **Always create new migrations**: To fix issues or make changes, create a new migration script.
3. **Sequential versioning**: Migrations are numbered sequentially and must be applied in order.
4. **Idempotency**: Migrations should be idempotent where possible, using `IF NOT EXISTS` and similar constructs.

### Migration Naming Convention

Migrations follow this naming pattern:
```
V{version}__description.sql
```

Examples:
- `V001__create_projects_table.sql`
- `V002__add_status_to_projects.sql`
- `V003__create_tasks_table.sql`

### Version Format

- **V**: Prefix indicating a versioned migration
- **{version}**: Zero-padded integer (001, 002, 003, ...)
- **__**: Double underscore separator
- **{description}**: Snake_case description of the change
- **.sql**: File extension

### Applying Migrations

Migrations should be applied in version order using your migration tool of choice (Flyway, Liquibase, or custom scripts).

Example using the validation script:
```bash
./scripts/validate-migrations.sh
```

## Getting Started

### Prerequisites

- MySQL 8.0 or higher
- Access to the target database server
- Migration tool (Flyway recommended) or use the provided scripts

### Initial Setup

1. Create a new database:
```sql
CREATE DATABASE lumanitech_projects CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. Apply all migrations in order:
```bash
# Using the provided script
./scripts/apply-migrations.sh <database_name> <host> <user>

# Or apply manually
mysql -h <host> -u <user> -p lumanitech_projects < migrations/V001__create_projects_table.sql
mysql -h <host> -u <user> -p lumanitech_projects < migrations/V002__...
```

3. (Optional) Load seed data:
```bash
./scripts/load-seeds.sh <database_name> <host> <user>
```

### Development Workflow

1. **Making Schema Changes**:
   - Create a new migration file with the next version number
   - Write your SQL changes (CREATE, ALTER, INSERT, etc.)
   - Update the schema files to reflect the new state
   - Test the migration on a local database
   - Commit both the migration and updated schema files

2. **Testing Migrations**:
   - Run validation scripts before committing
   - Test on a fresh database
   - Test on a database with existing data
   - Verify rollback strategy (if applicable)

3. **Code Review**:
   - All migrations must be reviewed before merging
   - Verify naming conventions
   - Check for data integrity issues
   - Ensure backward compatibility when needed

## CI/CD Integration

This repository includes validation scripts for continuous integration:

- **`scripts/validate-migrations.sh`**: Validates migration file naming and ordering
- **`scripts/validate-sql-syntax.sh`**: Checks SQL syntax without executing
- **`scripts/test-migrations.sh`**: Applies migrations to a test database

These scripts are designed to run in CI pipelines to catch issues before deployment.

## Best Practices

### DO:
- ✅ Create new migrations for all schema changes
- ✅ Use descriptive migration names
- ✅ Test migrations locally before committing
- ✅ Include comments in complex migrations
- ✅ Consider data migration along with schema changes
- ✅ Use transactions where appropriate
- ✅ Document breaking changes in the migration file

### DON'T:
- ❌ Modify existing migration files
- ❌ Skip version numbers
- ❌ Include application code in this repository
- ❌ Store sensitive data in seed files
- ❌ Create migrations that can't be applied multiple times safely
- ❌ Bypass the migration process with manual schema changes

## Troubleshooting

### Migration Conflicts

If multiple developers create migrations simultaneously:
1. Renumber your migration to the next available number
2. Update your migration filename
3. Test thoroughly before merging

### Failed Migrations

If a migration fails in production:
1. Do NOT modify the failed migration
2. Create a new migration to fix the issue
3. Document the issue and resolution
4. Update monitoring to prevent recurrence

## Support

For questions or issues related to this database:
- **Primary Contact**: Projects API Team
- **Repository Issues**: [GitHub Issues](../../issues)
- **Documentation**: See `docs/` folder

## License

Internal use only - Lumanitech ERP System
