#!/bin/bash
# =============================================================================
# Test Migrations Script
# =============================================================================
# Description: Creates a test database, applies all migrations, and validates
# Usage: ./scripts/test-migrations.sh [options]
# Example: ./scripts/test-migrations.sh --login-path=local --database=test_db
# Exit Codes: 0 = success, 1 = error
# Note: This script will DROP the test database if it exists!
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="migrations"
MIGRATIONS_PATH="$PROJECT_ROOT/$MIGRATIONS_DIR"

# Source common MySQL functions
source "$SCRIPT_DIR/mysql-common.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Print usage information
# =============================================================================
print_usage() {
    cat << EOF
Test Migrations Script

Usage: $0 [options]

Options:
  -d, --database NAME  Test database name (default: test_lumanitech_projects)
  --help               Show this help message

$(print_mysql_help)

WARNING: This script will DROP the test database if it exists!

Examples:
  # Using login-path
  $0 --login-path=local

  # Using environment variable with custom test db
  export MYSQL_LOGIN_PATH=local
  $0 -d my_test_db

  # Interactive (will prompt for password)
  $0 -h localhost -u root
EOF
}

# Parse MySQL connection arguments
parse_mysql_args "$@"

# Check for help
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        print_usage
        exit 0
    fi
done

# Set default test database name if not provided
if [[ -z "$DB_NAME" ]]; then
    DB_NAME="test_lumanitech_projects"
fi

# Setup MySQL command
if ! setup_mysql_cmd; then
    exit 1
fi

echo "=================================="
echo "Migration Testing Script"
echo "=================================="
echo ""
echo -e "${BLUE}Test Database: $DB_NAME${NC}"
echo -e "${BLUE}Host: $DB_HOST${NC}"
if [[ -n "$LOGIN_PATH" ]]; then
    echo -e "${BLUE}Login-path: $LOGIN_PATH${NC}"
else
    echo -e "${BLUE}User: $DB_USER${NC}"
fi
echo -e "${YELLOW}WARNING: This will DROP the database '$DB_NAME' if it exists!${NC}"
echo ""

# Check if mysql client is available
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}ERROR: mysql client is not installed${NC}"
    exit 1
fi

# Check if migrations directory exists
if [ ! -d "$MIGRATIONS_PATH" ]; then
    echo -e "${RED}ERROR: Migrations directory not found: $MIGRATIONS_PATH${NC}"
    exit 1
fi

# Test database connection
echo "Testing database connection..."
if ! test_mysql_connection; then
    echo -e "${RED}ERROR: Cannot connect to MySQL${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Database connection successful${NC}"
echo ""

# Confirm before proceeding
echo "Continue? (y/n)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi
echo ""

# Drop test database if exists
echo "Dropping test database if it exists..."
exec_mysql -e "DROP DATABASE IF EXISTS $DB_NAME"
echo -e "${GREEN}✓ Dropped (or didn't exist)${NC}"
echo ""

# Create test database
echo "Creating test database..."
exec_mysql -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
echo -e "${GREEN}✓ Test database created${NC}"
echo ""

# Get migration files
MIGRATION_FILES=($(ls "$MIGRATIONS_PATH"/V*.sql 2>/dev/null | sort))

if [ ${#MIGRATION_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No migration files found${NC}"
    exit 0
fi

echo "Found ${#MIGRATION_FILES[@]} migration file(s)"
echo ""

# Apply each migration
echo "Applying migrations..."
SUCCESS=0
FAILED=0

for filepath in "${MIGRATION_FILES[@]}"; do
    filename=$(basename "$filepath")
    
    echo -e "${BLUE}  Applying: $filename${NC}"
    
    if exec_mysql "$DB_NAME" < "$filepath"; then
        echo -e "${GREEN}    ✓ Success${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}    ✗ Failed${NC}"
        FAILED=$((FAILED + 1))
        break
    fi
done

echo ""

# If all migrations succeeded, run some validation queries
if [ $FAILED -eq 0 ]; then
    echo "Running validation checks..."
    
    # Check tables exist
    echo "Checking if tables were created..."
    TABLES=$(exec_mysql "$DB_NAME" -e "SHOW TABLES" -s)
    
    if [ -z "$TABLES" ]; then
        echo -e "${RED}  ✗ No tables found${NC}"
        FAILED=1
    else
        TABLE_COUNT=$(echo "$TABLES" | wc -l)
        echo -e "${GREEN}  ✓ Found $TABLE_COUNT table(s)${NC}"
        echo "    Tables: $(echo $TABLES | tr '\n' ', ' | sed 's/,$//')"
    fi
    echo ""
fi

# Test idempotency - apply migrations again
if [ $FAILED -eq 0 ]; then
    echo "Testing idempotency (applying migrations again)..."
    
    # Track idempotency failures (informational only, doesn't affect exit code)
    IDEMPOTENT=0
    for filepath in "${MIGRATION_FILES[@]}"; do
        filename=$(basename "$filepath")
        
        echo -e "${BLUE}  Re-applying: $filename${NC}"
        
        if exec_mysql "$DB_NAME" < "$filepath"; then
            echo -e "${GREEN}    ✓ Idempotent${NC}"
        else
            echo -e "${YELLOW}    ! Not idempotent (may be expected)${NC}"
            IDEMPOTENT=1
        fi
    done
    echo ""
fi

# Cleanup - drop test database
echo "Cleaning up..."
exec_mysql -e "DROP DATABASE IF EXISTS $DB_NAME"
echo -e "${GREEN}✓ Test database dropped${NC}"
echo ""

# Summary
echo "=================================="
echo "Test Summary"
echo "=================================="
echo "Migrations applied: $SUCCESS"
echo "Migrations failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All migration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Migration testing failed${NC}"
    exit 1
fi
