#!/bin/bash
# =============================================================================
# Migration Validation Script
# =============================================================================
# Description: Validates migration file naming, ordering, and format
# Usage: ./scripts/validate-migrations.sh
# Exit Codes: 0 = success, 1 = validation errors found
# =============================================================================

set -e

MIGRATIONS_DIR="migrations"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_PATH="$PROJECT_ROOT/$MIGRATIONS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "Migration Validation Script"
echo "=================================="
echo ""

# Check if migrations directory exists
if [ ! -d "$MIGRATIONS_PATH" ]; then
    echo -e "${RED}ERROR: Migrations directory not found: $MIGRATIONS_PATH${NC}"
    exit 1
fi

# Initialize counters
TOTAL_MIGRATIONS=0
ERRORS=0

echo "Validating migrations in: $MIGRATIONS_PATH"
echo ""

# Pattern for migration files: V{version}__description.sql
MIGRATION_PATTERN="^V[0-9]+__[a-z0-9_]+\.sql$"

# Get all migration files
MIGRATION_FILES=($(ls "$MIGRATIONS_PATH"/V*.sql 2>/dev/null | sort))

if [ ${#MIGRATION_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No migration files found${NC}"
    exit 0
fi

echo "Found ${#MIGRATION_FILES[@]} migration file(s)"
echo ""

# Track version numbers to check for duplicates and gaps
declare -a VERSIONS=()

# Validate each migration
for filepath in "${MIGRATION_FILES[@]}"; do
    TOTAL_MIGRATIONS=$((TOTAL_MIGRATIONS + 1))
    filename=$(basename "$filepath")
    
    echo "Checking: $filename"
    
    # Validate naming convention
    if ! [[ "$filename" =~ $MIGRATION_PATTERN ]]; then
        echo -e "${RED}  ✗ Invalid naming convention${NC}"
        echo "    Expected: V{version}__description.sql (e.g., V001__create_table.sql)"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}  ✓ Naming convention valid${NC}"
    fi
    
    # Extract version number
    VERSION=$(echo "$filename" | sed 's/V\([0-9]*\)__.*/\1/')
    VERSIONS+=("$VERSION")
    
    # Check if file is readable and not empty
    if [ ! -r "$filepath" ]; then
        echo -e "${RED}  ✗ File not readable${NC}"
        ERRORS=$((ERRORS + 1))
    elif [ ! -s "$filepath" ]; then
        echo -e "${RED}  ✗ File is empty${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}  ✓ File is readable and not empty${NC}"
    fi
    
    # Check for basic SQL syntax issues
    if grep -q "^--" "$filepath"; then
        echo -e "${GREEN}  ✓ Contains comments${NC}"
    fi
    
    # Check for common SQL keywords
    if grep -qi "CREATE\|ALTER\|INSERT\|UPDATE\|DELETE\|DROP" "$filepath"; then
        echo -e "${GREEN}  ✓ Contains SQL statements${NC}"
    else
        echo -e "${YELLOW}  ! No SQL DDL/DML statements found${NC}"
    fi
    
    echo ""
done

# Check for duplicate versions
echo "Checking for duplicate version numbers..."
SORTED_VERSIONS=($(printf '%s\n' "${VERSIONS[@]}" | sort -n))
UNIQUE_VERSIONS=($(printf '%s\n' "${VERSIONS[@]}" | sort -u -n))

if [ ${#SORTED_VERSIONS[@]} -ne ${#UNIQUE_VERSIONS[@]} ]; then
    echo -e "${RED}✗ Duplicate version numbers found!${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ No duplicate versions${NC}"
fi
echo ""

# Check for version gaps
echo "Checking for version number gaps..."
HAS_GAPS=0
EXPECTED=1

for version in "${SORTED_VERSIONS[@]}"; do
    # Remove leading zeros for comparison
    VERSION_NUM=$((10#$version))
    
    if [ $VERSION_NUM -ne $EXPECTED ]; then
        echo -e "${YELLOW}! Gap detected: Expected V$(printf '%03d' $EXPECTED), found V$version${NC}"
        HAS_GAPS=1
    fi
    EXPECTED=$((VERSION_NUM + 1))
done

if [ $HAS_GAPS -eq 0 ]; then
    echo -e "${GREEN}✓ No version gaps detected${NC}"
fi
echo ""

# Check migrations are in alphabetical order (which should match version order)
echo "Checking migration file ordering..."
SORTED_FILES=($(printf '%s\n' "${MIGRATION_FILES[@]}" | sort))

if [ "${MIGRATION_FILES[*]}" = "${SORTED_FILES[*]}" ]; then
    echo -e "${GREEN}✓ Migration files are properly ordered${NC}"
else
    echo -e "${RED}✗ Migration files are not in proper order${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Summary
echo "=================================="
echo "Validation Summary"
echo "=================================="
echo "Total migrations: $TOTAL_MIGRATIONS"
echo "Errors found: $ERRORS"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All validations passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s)${NC}"
    exit 1
fi
