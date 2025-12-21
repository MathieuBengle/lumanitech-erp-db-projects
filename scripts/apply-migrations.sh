#!/bin/bash
# =============================================================================
# Apply Migrations Script
# =============================================================================
# Description: Applies all migrations in order to a target database
# Usage: ./scripts/apply-migrations.sh <database> <host> <user>
# Example: ./scripts/apply-migrations.sh lumanitech_projects localhost root
# Exit Codes: 0 = success, 1 = error
# =============================================================================

set -e

# Check arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 <database> <host> <user>"
    echo "Example: $0 lumanitech_projects localhost root"
    exit 1
fi

DATABASE=$1
HOST=$2
USER=$3

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
echo "Migration Application Script"
echo "=================================="
echo ""
echo -e "${BLUE}Database: $DATABASE${NC}"
echo -e "${BLUE}Host: $HOST${NC}"
echo -e "${BLUE}User: $USER${NC}"
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
echo "Enter MySQL password:"
read -s PASSWORD
echo ""

# Test database connection
echo "Testing database connection..."
if ! mysql -h "$HOST" -u "$USER" -p"$PASSWORD" -e "USE $DATABASE" 2>/dev/null; then
    echo -e "${RED}ERROR: Cannot connect to database${NC}"
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
    if mysql -h "$HOST" -u "$USER" -p"$PASSWORD" "$DATABASE" < "$filepath" 2>&1; then
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
