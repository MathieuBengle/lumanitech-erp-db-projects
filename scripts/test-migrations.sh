#!/bin/bash
# =============================================================================
# Test Migrations Script
# =============================================================================
# Description: Creates a test database, applies all migrations, and validates
# Usage: ./scripts/test-migrations.sh [test_db_name]
# Example: ./scripts/test-migrations.sh test_lumanitech_projects
# Exit Codes: 0 = success, 1 = error
# Note: This script will DROP the test database if it exists!
# =============================================================================

set -e

# Default test database name
TEST_DB="${1:-test_lumanitech_projects}"
HOST="localhost"
USER="root"

MIGRATIONS_DIR="migrations"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_PATH="$PROJECT_ROOT/$MIGRATIONS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================="
echo "Migration Testing Script"
echo "=================================="
echo ""
echo -e "${BLUE}Test Database: $TEST_DB${NC}"
echo -e "${YELLOW}WARNING: This will DROP the database '$TEST_DB' if it exists!${NC}"
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

# Get password
echo "Enter MySQL root password:"
read -s PASSWORD
echo ""

# Test database connection
echo "Testing database connection..."
if ! mysql -h "$HOST" -u "$USER" -p"$PASSWORD" -e "SELECT 1" 2>/dev/null; then
    echo -e "${RED}ERROR: Cannot connect to database${NC}"
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
mysql -h "$HOST" -u "$USER" -p"$PASSWORD" -e "DROP DATABASE IF EXISTS $TEST_DB" 2>&1
echo -e "${GREEN}✓ Dropped (or didn't exist)${NC}"
echo ""

# Create test database
echo "Creating test database..."
mysql -h "$HOST" -u "$USER" -p"$PASSWORD" -e "CREATE DATABASE $TEST_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci" 2>&1
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
    
    if mysql -h "$HOST" -u "$USER" -p"$PASSWORD" "$TEST_DB" < "$filepath" 2>&1; then
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
    TABLES=$(mysql -h "$HOST" -u "$USER" -p"$PASSWORD" "$TEST_DB" -e "SHOW TABLES" -s)
    
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
    
    IDEMPOTENT=0
    for filepath in "${MIGRATION_FILES[@]}"; do
        filename=$(basename "$filepath")
        
        echo -e "${BLUE}  Re-applying: $filename${NC}"
        
        if mysql -h "$HOST" -u "$USER" -p"$PASSWORD" "$TEST_DB" < "$filepath" 2>&1; then
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
mysql -h "$HOST" -u "$USER" -p"$PASSWORD" -e "DROP DATABASE IF EXISTS $TEST_DB" 2>&1
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
