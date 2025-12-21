#!/bin/bash
# =============================================================================
# Apply Migrations Script
# =============================================================================
# Description: Applies all migrations in order to a target database
# Usage: ./scripts/apply-migrations.sh [options]
# Example: ./scripts/apply-migrations.sh --login-path=local -d lumanitech_projects
# Exit Codes: 0 = success, 1 = error
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
Apply Migrations Script

Usage: $0 [options]

Options:
  -d, --database NAME  Database name (required)
  --help               Show this help message

$(print_mysql_help)

Examples:
  # Using login-path
  $0 --login-path=local -d lumanitech_projects

  # Using environment variable
  export MYSQL_LOGIN_PATH=local
  $0 -d lumanitech_projects

  # Interactive (will prompt for password)
  $0 -h localhost -u root -d lumanitech_projects
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

# Validate required arguments
if [[ -z "$DB_NAME" ]]; then
    echo -e "${RED}ERROR: Database name is required${NC}"
    echo ""
    print_usage
    exit 1
fi

# Setup MySQL command
if ! setup_mysql_cmd; then
    exit 1
fi

echo "=================================="
echo "Migration Application Script"
echo "=================================="
echo ""
echo -e "${BLUE}Database: $DB_NAME${NC}"
echo -e "${BLUE}Host: $DB_HOST${NC}"
if [[ -n "$LOGIN_PATH" ]]; then
    echo -e "${BLUE}Login-path: $LOGIN_PATH${NC}"
else
    echo -e "${BLUE}User: $DB_USER${NC}"
fi
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
    echo "Please check your credentials and ensure the database exists"
    exit 1
fi
echo -e "${GREEN}✓ Database connection successful${NC}"
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
SUCCESS=0
FAILED=0

for filepath in "${MIGRATION_FILES[@]}"; do
    filename=$(basename "$filepath")
    
    echo -e "${BLUE}Applying: $filename${NC}"
    
    # Apply migration
    if exec_mysql "$DB_NAME" < "$filepath"; then
        echo -e "${GREEN}  ✓ Successfully applied${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}  ✗ Failed to apply${NC}"
        FAILED=$((FAILED + 1))
        
        # Ask if we should continue
        echo ""
        echo "Migration failed. Continue with remaining migrations? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Aborting migration process"
            exit 1
        fi
    fi
    echo ""
done

# Summary
echo "=================================="
echo "Migration Summary"
echo "=================================="
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All migrations applied successfully!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some migrations failed${NC}"
    exit 1
fi
