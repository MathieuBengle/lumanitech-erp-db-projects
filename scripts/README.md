# Scripts Directory

This directory contains utility and CI/CD validation scripts for the Lumanitech ERP Projects database.

## 🔐 Secure Authentication

All database scripts support **secure authentication** to avoid exposing passwords on the command line:

- **Recommended:** Use `mysql_config_editor` with `--login-path`
- **Alternative:** Use `MYSQL_LOGIN_PATH` environment variable
- **Fallback:** Interactive password prompt

**See [../docs/QUICKSTART.md](../docs/QUICKSTART.md) for complete authentication setup guide.**

## Available Scripts

### Core Scripts

#### setup_login.sh (NEW)

Interactive helper to configure mysql_config_editor login-path for secure authentication.

**Purpose**: Guides you through setting up encrypted MySQL credentials.

**Usage**:
```bash
./scripts/setup_login.sh
```

**Features**:
- Checks for existing login-paths
- Configures mysql_config_editor
- Tests the connection
- Displays usage examples

**No arguments needed** - fully interactive!

---

#### setup.sh (NEW)

Complete database setup: create database, apply migrations, optionally load seeds.

**Purpose**: One-command database initialization.

**Usage**:
```bash
# With login-path (recommended)
./scripts/setup.sh --login-path=local -d lumanitech_projects --with-seeds

# With environment variable
export MYSQL_LOGIN_PATH=local
./scripts/setup.sh -d lumanitech_projects --with-seeds

# Force recreate
./scripts/setup.sh --login-path=local -d lumanitech_projects --force
```

**Options**:
- `-d, --database NAME` - Database name (required)
- `--login-path=NAME` - Use login-path for authentication
- `-h, --host HOST` - MySQL host (default: localhost)
- `-u, --user USER` - MySQL user (default: root)
- `--with-seeds` - Load seed data after migrations
- `--force` - Drop existing database if it exists
- `--help` - Show help message

**Exit Codes**:
- 0: Setup successful
- 1: Error occurred

---

#### mysql-common.sh (NEW)

Common library for secure MySQL connections. Not executed directly.

**Purpose**: Provides reusable authentication functions for all scripts.

**Features**:
- Unified authentication handling
- Priority: CLI --login-path > env MYSQL_LOGIN_PATH > auto-detect > prompt
- Secure command execution
- Connection testing

**Usage**: Sourced by other scripts
```bash
source "$SCRIPT_DIR/mysql-common.sh"
setup_mysql_cmd
exec_mysql -e "SQL..."
```

---

### Validation Scripts

#### 1. validate-migrations.sh

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

#### 2. validate-sql-syntax.sh

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

### Database Operation Scripts

#### 3. apply-migrations.sh (UPDATED)

Applies all migrations in order to a target database.

**Purpose**: Execute migrations against a database.

**Requirements**: MySQL client must be installed

**Usage**:
```bash
# With login-path (recommended)
./scripts/apply-migrations.sh --login-path=local -d lumanitech_projects

# With environment variable
export MYSQL_LOGIN_PATH=local
./scripts/apply-migrations.sh -d lumanitech_projects

# Interactive (will prompt for password)
./scripts/apply-migrations.sh -h localhost -u root -d lumanitech_projects
```

**Options**:
- `-d, --database NAME` - Database name (required)
- `--login-path=NAME` - Use login-path for authentication
- `-h, --host HOST` - MySQL host (default: localhost)
- `-u, --user USER` - MySQL user (default: root)
- `--help` - Show help message

**Features**:
- ✅ Secure authentication (no password on command line)
- ✅ Applies migrations in sequential order
- ✅ Tests database connection before starting
- ✅ Shows progress for each migration
- ✅ Option to continue on failure
- ✅ Summary report

**Exit Codes**:
- 0: All migrations applied successfully
- 1: One or more migrations failed

---

#### 4. load-seeds.sh (UPDATED)

Loads all seed data files in order.

**Purpose**: Populate database with sample/test data.

**Requirements**: MySQL client must be installed

**Usage**:
```bash
# With login-path (recommended)
./scripts/load-seeds.sh --login-path=local -d lumanitech_projects

# With environment variable
export MYSQL_LOGIN_PATH=local
./scripts/load-seeds.sh -d lumanitech_projects

# Interactive (will prompt for password)
./scripts/load-seeds.sh -h localhost -u root -d lumanitech_projects
```

**Options**:
- `-d, --database NAME` - Database name (required)
- `--login-path=NAME` - Use login-path for authentication
- `-h, --host HOST` - MySQL host (default: localhost)
- `-u, --user USER` - MySQL user (default: root)
- `--help` - Show help message

**Features**:
- ✅ Secure authentication (no password on command line)
- ✅ Loads seed files in numbered order
- ✅ Confirms before inserting data
- ✅ Tests database connection
- ✅ Shows progress for each seed file
- ✅ Option to continue on failure

**Exit Codes**:
- 0: All seeds loaded successfully
- 1: One or more seeds failed

**Warning**: Only use on development/test databases!

---

#### 5. test-migrations.sh (UPDATED)

Creates a test database, applies all migrations, and validates.

**Purpose**: Comprehensive migration testing including idempotency checks.

**Requirements**: MySQL client with CREATE/DROP database privileges

**Usage**:
```bash
# With login-path (recommended)
./scripts/test-migrations.sh --login-path=local

# With custom test database name
./scripts/test-migrations.sh --login-path=local -d my_test_db

# Using environment variable
export MYSQL_LOGIN_PATH=local
./scripts/test-migrations.sh
```

**Options**:
- `-d, --database NAME` - Test database name (default: test_lumanitech_projects)
- `--login-path=NAME` - Use login-path for authentication
- `-h, --host HOST` - MySQL host (default: localhost)
- `-u, --user USER` - MySQL user (default: root)
- `--help` - Show help message

**Features**:
- ✅ Secure authentication (no password on command line)
- ✅ Creates fresh test database
- ✅ Applies all migrations in order
- ✅ Validates table creation
- ✅ Tests idempotency (applies migrations twice)
- ✅ Cleans up test database automatically

**Exit Codes**:
- 0: All tests passed
- 1: Tests failed

**Warning**: Will DROP the test database if it exists!

---

## Security Features

### No Password Exposure

All scripts use secure authentication methods:

1. **mysql_config_editor (Recommended)**:
   ```bash
   # Setup once
   ./scripts/setup_login.sh
   
   # Use in scripts
   ./scripts/setup.sh --login-path=local -d mydb
   ```

2. **Environment Variable**:
   ```bash
   export MYSQL_LOGIN_PATH=local
   ./scripts/setup.sh -d mydb
   ```

3. **Interactive Prompt** (fallback):
   - No password visible in command history
   - No password in process list
   - Single prompt for entire operation

### What We DON'T Do

❌ Never use `-p'password'` (exposes password in process list)
❌ Never use `MYSQL_PWD` environment variable (deprecated and insecure)
❌ Never echo passwords in logs

### Benefits

✅ Encrypted credential storage with mysql_config_editor
✅ No passwords in command history
✅ No passwords in process lists (`ps aux`)
✅ No "Using a password on the command line" warnings
✅ CI/CD compatible with `MYSQL_LOGIN_PATH`

---

## Making Scripts Executable

Before using the scripts, make them executable:

```bash
chmod +x scripts/*.sh
```

## CI/CD Integration

### GitHub Actions Example (UPDATED)

```yaml
name: Database CI

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test_password
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Wait for MySQL
        run: |
          for i in {1..30}; do
            if mysqladmin ping -h 127.0.0.1 --silent; then break; fi
            sleep 1
          done
      
      - name: Configure MySQL login-path
        run: |
          mysql_config_editor set --login-path=ci \
            --host=127.0.0.1 --user=root --password <<< "test_password"
      
      - name: Set environment
        run: echo "MYSQL_LOGIN_PATH=ci" >> $GITHUB_ENV
      
      - name: Make scripts executable
        run: chmod +x scripts/*.sh
      
      - name: Validate migrations
        run: |
          ./scripts/validate-migrations.sh
          ./scripts/validate-sql-syntax.sh
      
      - name: Test migrations
        run: ./scripts/test-migrations.sh -d test_db
      
      - name: Setup database with seeds
        run: ./scripts/setup.sh -d lumanitech_projects --with-seeds --force
```

### GitLab CI Example (UPDATED)

```yaml
validate:
  stage: test
  image: mysql:8.0
  
  services:
    - mysql:8.0
  
  variables:
    MYSQL_ROOT_PASSWORD: test_password
  
  before_script:
    - apt-get update && apt-get install -y mysql-client
    - |
      mysql_config_editor set --login-path=ci \
        --host=mysql --user=root --password <<< "$MYSQL_ROOT_PASSWORD"
    - export MYSQL_LOGIN_PATH=ci
    - chmod +x scripts/*.sh
  
  script:
    - ./scripts/validate-migrations.sh
    - ./scripts/validate-sql-syntax.sh
    - ./scripts/test-migrations.sh -d test_db
```

---

## Development Workflow

### Initial Setup

```bash
# 1. Configure login-path (one-time)
./scripts/setup_login.sh

# 2. Create database with migrations and seeds
./scripts/setup.sh --login-path=local -d lumanitech_projects --with-seeds
```

### Before Committing

1. **Validate your migration**:
```bash
./scripts/validate-migrations.sh
./scripts/validate-sql-syntax.sh
```

2. **Test on local database**:
```bash
./scripts/test-migrations.sh --login-path=local
```

3. **Fix any issues** and re-run validations

### Applying to Development Database

```bash
./scripts/apply-migrations.sh --login-path=local -d lumanitech_dev
```

### Loading Sample Data

```bash
./scripts/load-seeds.sh --login-path=local -d lumanitech_dev
```

---

## Common Use Cases

### Fresh Database Setup

```bash
# Complete setup with one command
./scripts/setup.sh --login-path=local -d mydb --with-seeds
```

### Apply New Migrations

```bash
# Just the migrations
./scripts/apply-migrations.sh --login-path=local -d mydb
```

### Reset Development Database

```bash
# Force recreate
./scripts/setup.sh --login-path=local -d mydb --force --with-seeds
```

### Test Before Deploying

```bash
# Validate
./scripts/validate-migrations.sh
./scripts/validate-sql-syntax.sh

# Test
./scripts/test-migrations.sh --login-path=local
```

---

## Troubleshooting

### "mysql_config_editor: command not found"

Install MySQL client:
```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# macOS
brew install mysql-client
```

### "No login-path found"

Configure a login-path:
```bash
./scripts/setup_login.sh
```

### "Using a password on the command line" warning

This should NOT appear when using login-path. Make sure you're using:
```bash
./scripts/setup.sh --login-path=local -d mydb
# OR
export MYSQL_LOGIN_PATH=local
```

### Permission Denied

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

### Connection Refused

Ensure MySQL server is running:
```bash
# Check MySQL status
sudo systemctl status mysql

# Start MySQL
sudo systemctl start mysql
```

---

## Best Practices

### DO:

- ✅ Use `mysql_config_editor` for all environments
- ✅ Run validation scripts before committing
- ✅ Test migrations on a test database first
- ✅ Use `--login-path` for secure authentication
- ✅ Set `MYSQL_LOGIN_PATH` in CI/CD environments
- ✅ Review script output for warnings

### DON'T:

- ❌ Hardcode passwords in scripts or config files
- ❌ Use `-p'password'` or `MYSQL_PWD`
- ❌ Skip validation steps
- ❌ Run load-seeds.sh on production
- ❌ Modify scripts without testing
- ❌ Ignore script warnings
- ❌ Commit `~/.mylogin.cnf` to version control

---

## Authentication Priority Reference

All scripts follow this priority for authentication:

1. **CLI --login-path argument** (highest priority)
   ```bash
   ./script.sh --login-path=local -d mydb
   ```

2. **MYSQL_LOGIN_PATH environment variable**
   ```bash
   export MYSQL_LOGIN_PATH=local
   ./script.sh -d mydb
   ```

3. **Auto-detect from mysql_config_editor**
   - First available login-path is used
   ```bash
   ./script.sh -d mydb  # Auto-uses first login-path
   ```

4. **Interactive password prompt** (lowest priority, fallback)
   ```bash
   ./script.sh -h localhost -u root -d mydb
   # Enter MySQL password: ****
   ```

---

## See Also

- [../docs/QUICKSTART.md](../docs/QUICKSTART.md) - Detailed setup guide with secure authentication
- [../README.md](../README.md) - Main project documentation and migration strategy
- [../migrations/README.md](../migrations/README.md) - Migration guidelines
- [../docs/DATABASE_DESIGN.md](../docs/DATABASE_DESIGN.md) - Database architecture

---

Last Updated: 2025-12-21
