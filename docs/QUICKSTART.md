# Quick Start Guide

This guide will help you set up and use the Lumanitech ERP Projects database quickly and securely.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Secure Authentication Setup](#secure-authentication-setup)
- [Database Setup](#database-setup)
- [Common Tasks](#common-tasks)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

- **MySQL Server 8.0+** installed and running
- **MySQL Client** (includes `mysql` and `mysql_config_editor` commands)
- **Bash shell** (Linux, macOS, WSL2 on Windows)

### Installing MySQL Client

```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# RHEL/CentOS
sudo yum install mysql

# macOS
brew install mysql-client

# WSL2 (Ubuntu)
sudo apt-get update && sudo apt-get install mysql-client
```

## Secure Authentication Setup

### Why use mysql_config_editor?

The `mysql_config_editor` utility provides **encrypted storage** of MySQL credentials, eliminating the need to:
- Type passwords repeatedly
- Expose passwords on the command line (visible in process lists and logs)
- Store passwords in plain text files

### Setting up a login-path

We provide a helper script to configure secure authentication:

```bash
# Run the interactive setup
./scripts/setup_login.sh
```

The script will:
1. Check if `mysql_config_editor` is available
2. Show existing login-paths (if any)
3. Prompt for a login-path name (e.g., `local`, `dev`, `staging`)
4. Ask for MySQL host, user, and password
5. Test the connection
6. Display usage examples

**WSL2 local note:**
Use a login-path configured with user 'admin'.
Example:
```bash
mysql_config_editor set --login-path=local --host=localhost --user=admin --password
```

#### Manual setup (alternative)

If you prefer to set up manually:

```bash
# Configure login-path
mysql_config_editor set \
  --login-path=local \
  --host=localhost \
  --user=root \
  --password

# You will be prompted to enter the password
# The password is stored encrypted in ~/.mylogin.cnf

# Verify the configuration
mysql_config_editor print --all

# Test the connection
mysql --login-path=local -e "SELECT 1"
```

### Security Notes

✅ **DO:**
- Keep `~/.mylogin.cnf` secure (it's encrypted but should be protected)
- Use different login-paths for different environments (`local`, `dev`, `staging`, `prod`)
- Set appropriate file permissions: `chmod 600 ~/.mylogin.cnf`

❌ **DON'T:**
- Commit `~/.mylogin.cnf` to version control
- Share your `~/.mylogin.cnf` file
- Use production credentials on development machines

## Database Setup

### Option 1: Complete Setup with One Command

Create the database, apply migrations, and optionally load seed data:

```bash
# Using login-path (recommended)
./scripts/setup.sh --login-path=local -d lumanitech_erp_projects --with-seeds

# Using environment variable
export MYSQL_LOGIN_PATH=local
./scripts/setup.sh -d lumanitech_erp_projects --with-seeds

# Force recreate (drops existing database)
./scripts/setup.sh --login-path=local -d lumanitech_erp_projects --force
```

### Option 2: Step-by-Step Setup

If you prefer to run each step manually:

#### 1. Create the database

```bash
# Using login-path
mysql --login-path=local -e "CREATE DATABASE lumanitech_erp_projects CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
```

#### 2. Apply migrations

```bash
./scripts/apply-migrations.sh --login-path=local -d lumanitech_erp_projects
```

#### 3. Load seed data (optional, for development)

```bash
./scripts/load-seeds.sh --login-path=local -d lumanitech_erp_projects
```

## Common Tasks

### Running Migrations

```bash
# Apply all pending migrations
./scripts/apply-migrations.sh --login-path=local -d lumanitech_erp_projects
```

### Loading Sample Data

```bash
# Load seed data into an existing database
./scripts/load-seeds.sh --login-path=local -d lumanitech_erp_projects
```

### Testing Migrations

```bash
# Test migrations on a temporary database
./scripts/test-migrations.sh --login-path=local

# Test with custom database name
./scripts/test-migrations.sh --login-path=local -d my_test_db
```

**Note:** The test script will DROP the test database if it exists!

### Validating Migrations

```bash
# Validate migration file naming and ordering
./scripts/validate-migrations.sh

# Validate SQL syntax
./scripts/validate-sql-syntax.sh
```

## Authentication Methods Priority

Scripts use the following priority for authentication:

1. **CLI `--login-path` argument** (highest priority)
   ```bash
   ./scripts/setup.sh --login-path=local -d mydb
   ```

2. **Environment variable `MYSQL_LOGIN_PATH`**
   ```bash
   export MYSQL_LOGIN_PATH=local
   ./scripts/setup.sh -d mydb
   ```

3. **Auto-detect from mysql_config_editor**
   - If you have configured login-paths, the first one found will be used automatically
   ```bash
   ./scripts/setup.sh -d mydb  # Auto-uses first available login-path
   ```

4. **Interactive password prompt** (fallback)
   - If no login-path is available, you'll be prompted for the password
   ```bash
   ./scripts/setup.sh -h localhost -u root -d mydb
   # Enter MySQL password: ****
   ```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Database CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test_password
          MYSQL_DATABASE: test_db
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Wait for MySQL
        run: |
          for i in {1..30}; do
            if mysqladmin ping -h 127.0.0.1 --silent; then
              break
            fi
            sleep 1
          done
      
      - name: Configure MySQL login-path
        run: |
          mysql_config_editor set \
            --login-path=ci \
            --host=127.0.0.1 \
            --user=root \
            --password <<< "test_password"
      
      - name: Set environment variable
        run: echo "MYSQL_LOGIN_PATH=ci" >> $GITHUB_ENV
      
      - name: Validate migrations
        run: |
          chmod +x scripts/*.sh
          ./scripts/validate-migrations.sh
          ./scripts/validate-sql-syntax.sh
      
      - name: Test migrations
        run: ./scripts/test-migrations.sh -d test_db
      
      - name: Setup database with seeds
        run: ./scripts/setup.sh -d lumanitech_erp_projects --with-seeds --force
```

### GitLab CI Example

```yaml
test:
  image: mysql:8.0
  
  services:
    - mysql:8.0
  
  variables:
    MYSQL_ROOT_PASSWORD: test_password
    MYSQL_DATABASE: test_db
  
  before_script:
    - apt-get update && apt-get install -y mysql-client
    - |
      mysql_config_editor set \
        --login-path=ci \
        --host=mysql \
        --user=root \
        --password <<< "$MYSQL_ROOT_PASSWORD"
    - export MYSQL_LOGIN_PATH=ci
    - chmod +x scripts/*.sh
  
  script:
    - ./scripts/validate-migrations.sh
    - ./scripts/validate-sql-syntax.sh
    - ./scripts/test-migrations.sh -d test_db
```

### Using MYSQL_LOGIN_PATH in CI

For non-interactive CI environments, configure the login-path programmatically:

```bash
# In CI environment
mysql_config_editor set \
  --login-path=ci \
  --host=${DB_HOST} \
  --user=${DB_USER} \
  --password <<< "${DB_PASSWORD}"

# Then use it
export MYSQL_LOGIN_PATH=ci
./scripts/setup.sh -d lumanitech_erp_projects
```

## Script Options Reference

### setup.sh

Complete database setup with migrations and optional seeds.

```bash
./scripts/setup.sh [options]

Options:
  -d, --database NAME  Database name (required)
  --login-path=NAME    Use mysql_config_editor login-path
  -h, --host HOST      MySQL host (default: localhost)
  -u, --user USER      MySQL user (default: root)
  --with-seeds         Load seed data after migrations
  --force              Drop existing database if it exists
  --help               Show help message
```

### apply-migrations.sh

Apply migrations to an existing database.

```bash
./scripts/apply-migrations.sh [options]

Options:
  -d, --database NAME  Database name (required)
  --login-path=NAME    Use mysql_config_editor login-path
  -h, --host HOST      MySQL host (default: localhost)
  -u, --user USER      MySQL user (default: root)
  --help               Show help message
```

### load-seeds.sh

Load sample data into an existing database.

```bash
./scripts/load-seeds.sh [options]

Options:
  -d, --database NAME  Database name (required)
  --login-path=NAME    Use mysql_config_editor login-path
  -h, --host HOST      MySQL host (default: localhost)
  -u, --user USER      MySQL user (default: root)
  --help               Show help message
```

### test-migrations.sh

Test migrations on a temporary database (will DROP the test database!).

```bash
./scripts/test-migrations.sh [options]

Options:
  -d, --database NAME  Test database name (default: test_lumanitech_erp_projects)
  --login-path=NAME    Use mysql_config_editor login-path
  -h, --host HOST      MySQL host (default: localhost)
  -u, --user USER      MySQL user (default: root)
  --help               Show help message
```

### setup_login.sh

Interactive helper to configure mysql_config_editor login-path.

```bash
./scripts/setup_login.sh

# Follow the interactive prompts
```

## Troubleshooting

### "mysql_config_editor: command not found"

Install MySQL client tools (includes mysql_config_editor):

```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# macOS
brew install mysql-client
```

### "ERROR: Cannot connect to MySQL"

1. Check if MySQL server is running:
   ```bash
   sudo systemctl status mysql
   # or
   mysqladmin ping -h localhost
   ```

2. Verify your credentials:
   ```bash
   mysql --login-path=local -e "SELECT 1"
   ```

3. Check if the login-path is configured:
   ```bash
   mysql_config_editor print --all
   ```

### "WARNING: Using a password on the command line interface can be insecure"

This warning should NOT appear when using `--login-path`. If you see it:

1. Make sure you're using a login-path:
   ```bash
   ./scripts/setup.sh --login-path=local -d mydb
   ```

2. Or set the environment variable:
   ```bash
   export MYSQL_LOGIN_PATH=local
   ```

### Database already exists

Use the `--force` option to drop and recreate:

```bash
./scripts/setup.sh --login-path=local -d lumanitech_erp_projects --force
```

### Permission denied when running scripts

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

### Login-path not found in CI

Make sure to configure the login-path in your CI script:

```bash
mysql_config_editor set \
  --login-path=ci \
  --host=localhost \
  --user=root \
  --password <<< "${DB_PASSWORD}"

export MYSQL_LOGIN_PATH=ci
```

## WSL2 Specific Notes

When using WSL2 on Windows:

1. **Install MySQL client in WSL2:**
   ```bash
   sudo apt-get update
   sudo apt-get install mysql-client
   ```

2. **Connect to MySQL on Windows:**
   If MySQL is running on Windows host:
   ```bash
   # Get Windows host IP
   export WIN_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
   
   # Configure login-path
   mysql_config_editor set \
     --login-path=windows \
     --host=$WIN_HOST \
     --user=root \
     --password
   ```

3. **File permissions:**
   Ensure `~/.mylogin.cnf` has correct permissions:
   ```bash
   chmod 600 ~/.mylogin.cnf
   ```

## Best Practices

1. **Use login-paths for all environments:**
   - `local` for local development
   - `dev` for development server
   - `staging` for staging environment
   - `ci` for CI/CD pipelines

2. **Never commit credentials:**
   - Add to `.gitignore`: `~/.mylogin.cnf`, `.env`, `*.key`

3. **Test before production:**
   - Always run `test-migrations.sh` before deploying
   - Validate with `validate-migrations.sh`

4. **Use --force carefully:**
   - Only use on development databases
   - Never use on production

5. **Environment variables in CI:**
   - Store `MYSQL_LOGIN_PATH` in CI environment
   - Configure login-path in CI scripts

## Next Steps

- Read the [main README](../README.md) for migration strategy
- Check [DATABASE_DESIGN.md](DATABASE_DESIGN.md) for architecture details
- Review [DATA_DICTIONARY.md](DATA_DICTIONARY.md) for schema reference
- See [ERD.md](ERD.md) for entity relationships

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section above
- Review script output for specific error messages
- Contact the Projects API team
