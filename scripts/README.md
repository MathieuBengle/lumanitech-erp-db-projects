# Scripts Directory

This directory contains utility and CI/CD validation scripts for the Lumanitech ERP Projects database.

## Available Scripts

### 1. validate-migrations.sh

Validates migration file naming, ordering, and format.

**Purpose**: Ensures all migrations follow the correct naming convention and are properly ordered.

**Usage**:
```bash
./scripts/validate-migrations.sh
```

**Checks**:
- ✅ File naming convention (V{version}__description.sql)
- ✅ No duplicate version numbers
- ✅ No gaps in version sequence
- ✅ Files are in correct order
- ✅ Files are readable and not empty
- ✅ Basic SQL content validation

**Exit Codes**:
- 0: All validations passed
- 1: Validation errors found

**Use in CI**:
```yaml
# Example GitHub Actions
- name: Validate Migrations
  run: ./scripts/validate-migrations.sh
```

---

### 2. validate-sql-syntax.sh

Validates SQL syntax without executing the statements.

**Purpose**: Catches basic SQL syntax errors before applying migrations.

**Requirements**: MySQL client must be installed

**Usage**:
```bash
./scripts/validate-sql-syntax.sh
```

**Checks**:
- ✅ Balanced parentheses
- ✅ Common typos (e.g., "IF NOT EXITS" → "IF NOT EXISTS")
- ✅ Presence of SQL statements
- ✅ Basic syntax validation

**Exit Codes**:
- 0: All syntax checks passed
- 1: Syntax errors found

**Use in CI**:
```yaml
# Example GitHub Actions
- name: Validate SQL Syntax
  run: ./scripts/validate-sql-syntax.sh
```

---

### 3. apply-migrations.sh

Applies all migrations in order to a target database.

**Purpose**: Execute migrations against a database.

**Requirements**: MySQL client must be installed

**Usage**:
```bash
./scripts/apply-migrations.sh <database> <host> <user>
```

**Example**:
```bash
./scripts/apply-migrations.sh lumanitech_projects localhost root
```

**Features**:
- Applies migrations in sequential order
- Tests database connection before starting
- Shows progress for each migration
- Option to continue on failure
- Summary report

**Exit Codes**:
- 0: All migrations applied successfully
- 1: One or more migrations failed

**Security Note**: Password is requested interactively (not passed as argument)

---

### 4. load-seeds.sh

Loads all seed data files in order.

**Purpose**: Populate database with sample/test data.

**Requirements**: MySQL client must be installed

**Usage**:
```bash
./scripts/load-seeds.sh <database> <host> <user>
```

**Example**:
```bash
./scripts/load-seeds.sh lumanitech_projects localhost root
```

**Features**:
- Loads seed files in numbered order
- Confirms before inserting data
- Tests database connection
- Shows progress for each seed file
- Option to continue on failure

**Exit Codes**:
- 0: All seeds loaded successfully
- 1: One or more seeds failed

**Warning**: Only use on development/test databases!

---

### 5. test-migrations.sh

Creates a test database, applies all migrations, and validates.

**Purpose**: Comprehensive migration testing including idempotency checks.

**Requirements**: MySQL client with CREATE/DROP database privileges

**Usage**:
```bash
./scripts/test-migrations.sh [test_db_name]
```

**Example**:
```bash
./scripts/test-migrations.sh test_lumanitech_projects
```

**Features**:
- Creates fresh test database
- Applies all migrations in order
- Validates table creation
- Tests idempotency (applies migrations twice)
- Cleans up test database automatically

**Exit Codes**:
- 0: All tests passed
- 1: Tests failed

**Warning**: Will DROP the test database if it exists!

**Use in CI**:
```yaml
# Example GitHub Actions
- name: Test Migrations
  run: ./scripts/test-migrations.sh
  env:
    MYSQL_PWD: ${{ secrets.MYSQL_PASSWORD }}
```

---

## Making Scripts Executable

Before using the scripts, make them executable:

```bash
chmod +x scripts/*.sh
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Database CI

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Make scripts executable
        run: chmod +x scripts/*.sh
      
      - name: Validate migration naming
        run: ./scripts/validate-migrations.sh
      
      - name: Validate SQL syntax
        run: ./scripts/validate-sql-syntax.sh
      
      - name: Setup MySQL
        uses: mirromutth/mysql-action@v1.1
        with:
          mysql version: '8.0'
          mysql root password: 'test_password'
      
      - name: Test migrations
        run: ./scripts/test-migrations.sh
        env:
          MYSQL_PWD: test_password
```

### GitLab CI Example

```yaml
validate:
  stage: test
  script:
    - chmod +x scripts/*.sh
    - ./scripts/validate-migrations.sh
    - ./scripts/validate-sql-syntax.sh

test-migrations:
  stage: test
  services:
    - mysql:8.0
  variables:
    MYSQL_ROOT_PASSWORD: test_password
    MYSQL_DATABASE: test_db
  script:
    - chmod +x scripts/*.sh
    - ./scripts/test-migrations.sh
```

## Development Workflow

### Before Committing

1. **Validate your migration**:
```bash
./scripts/validate-migrations.sh
./scripts/validate-sql-syntax.sh
```

2. **Test on local database**:
```bash
./scripts/test-migrations.sh
```

3. **Fix any issues** and re-run validations

### Applying to Development Database

```bash
./scripts/apply-migrations.sh lumanitech_dev localhost dev_user
```

### Loading Sample Data

```bash
./scripts/load-seeds.sh lumanitech_dev localhost dev_user
```

## Troubleshooting

### Permission Denied

If you get "Permission denied" errors:
```bash
chmod +x scripts/*.sh
```

### MySQL Client Not Found

Install MySQL client:
```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# macOS
brew install mysql-client

# RHEL/CentOS
sudo yum install mysql
```

### Connection Refused

Ensure MySQL server is running:
```bash
# Check MySQL status
sudo systemctl status mysql

# Start MySQL
sudo systemctl start mysql
```

### Access Denied

- Check username and password
- Ensure user has appropriate privileges
- For test-migrations.sh, user needs CREATE/DROP database privileges

## Best Practices

### DO:

- ✅ Run validation scripts before committing
- ✅ Test migrations on a test database first
- ✅ Keep scripts executable in version control
- ✅ Use scripts in CI/CD pipelines
- ✅ Review script output for warnings

### DON'T:

- ❌ Hardcode passwords in scripts
- ❌ Skip validation steps
- ❌ Run load-seeds.sh on production
- ❌ Modify scripts without testing
- ❌ Ignore script warnings

## Extending the Scripts

### Adding a New Script

1. Create the script file in `/scripts`
2. Add shebang: `#!/bin/bash`
3. Add descriptive header comments
4. Use color-coded output for clarity
5. Include error handling (`set -e`)
6. Make it executable: `chmod +x`
7. Document it in this README
8. Test thoroughly

### Script Template

```bash
#!/bin/bash
# =============================================================================
# Script Name
# =============================================================================
# Description: What this script does
# Usage: ./scripts/script-name.sh [args]
# Exit Codes: 0 = success, 1 = error
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Your script logic here
echo -e "${GREEN}✓ Success${NC}"
```

## Support

For issues with these scripts:
- Check the script output for specific error messages
- Ensure all prerequisites are installed
- Verify database credentials and permissions
- Review this documentation
- Contact the Projects API team

---

Last Updated: 2025-12-21
