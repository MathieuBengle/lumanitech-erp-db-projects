# Schema Directory

This directory contains the current complete database schema for the Lumanitech ERP Projects database.

## Files

- **`complete_schema.sql`**: The complete, current database schema including all tables, indexes, and constraints. This represents the state after all migrations have been applied.

## Purpose

The schema files in this directory serve as:
1. **Documentation**: A single source to view the current database structure
2. **Reference**: For developers to understand the data model
3. **Baseline**: For creating new development/test databases

## Important Notes

⚠️ **These files are documentation only!** 

- Schema changes should NEVER be made directly to these files in isolation
- All schema changes must be made through versioned migration scripts
- When creating a new migration, update these schema files to reflect the new state

## Usage

### Creating a Fresh Database

To create a new database with the current schema:

```bash
# Create the database
mysql -u root -p -e "CREATE DATABASE lumanitech_projects CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Apply the schema
mysql -u root -p lumanitech_projects < complete_schema.sql
```

### Updating Schema Files

When you create a new migration:

1. Create the migration file in `/migrations`
2. Apply the migration to your local database
3. Dump the updated schema to this file
4. Commit both the migration and the updated schema

Example:
```bash
# After applying your migration
mysqldump -u root -p --no-data --skip-comments lumanitech_projects > schema/complete_schema.sql
```

## Workflow

```
[New Requirement] 
    ↓
[Create Migration] → migrations/V00X__description.sql
    ↓
[Apply Migration]
    ↓
[Update Schema] → schema/complete_schema.sql
    ↓
[Commit Both]
```

## See Also

- `/migrations` - Version-controlled schema changes
- `/docs` - Database documentation and ERD diagrams
