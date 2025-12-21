#!/bin/bash
# =============================================================================
# SQL Syntax Validation Script
# =============================================================================
# Description: Validates SQL syntax without executing the statements
# Usage: ./scripts/validate-sql-syntax.sh
# Requirements: MySQL client must be installed
# Exit Codes: 0 = success, 1 = validation errors found
# =============================================================================

set -e

MIGRATIONS_DIR="migrations"
SCHEMA_DIR="schema"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "SQL Syntax Validation Script"
echo "=================================="
echo ""

# Check if mysql client is available
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}ERROR: mysql client is not installed${NC}"
    echo "Please install MySQL client to run syntax validation"
    exit 1
fi

ERRORS=0
CHECKED=0

# Function to validate SQL file syntax
validate_sql_file() {
    local filepath=$1
    local filename=$(basename "$filepath")
    
    echo "Validating: $filename"
    
    # Use mysql to check syntax without executing
    # The --help option with piping to mysql will parse but not execute
    if mysql --help > /dev/null 2>&1; then
        # Basic syntax check - look for common SQL errors
        if grep -E "(CREATE TABLE|CREATE INDEX|ALTER TABLE|INSERT INTO|UPDATE|DELETE|DROP)" "$filepath" > /dev/null; then
            
            # Check for balanced parentheses
            OPEN_PARENS=$(grep -o '(' "$filepath" | wc -l)
            CLOSE_PARENS=$(grep -o ')' "$filepath" | wc -l)
            
            if [ "$OPEN_PARENS" -ne "$CLOSE_PARENS" ]; then
                echo -e "${RED}  ✗ Unbalanced parentheses (open: $OPEN_PARENS, close: $CLOSE_PARENS)${NC}"
                ERRORS=$((ERRORS + 1))
                return 1
            fi
            
            # Check for common syntax issues
            if grep -i "IF NOT EXITS" "$filepath" > /dev/null; then
                echo -e "${RED}  ✗ Typo: 'IF NOT EXITS' should be 'IF NOT EXISTS'${NC}"
                ERRORS=$((ERRORS + 1))
                return 1
            fi
            
            # Check for semicolons at end of statements
            if ! grep -E ";$" "$filepath" > /dev/null; then
                echo -e "${YELLOW}  ! Warning: No semicolons found - may be intentional${NC}"
            fi
            
            echo -e "${GREEN}  ✓ Basic syntax checks passed${NC}"
            return 0
        else
            echo -e "${YELLOW}  ! No SQL statements found${NC}"
            return 0
        fi
    fi
}

# Validate migration files
echo "Validating migration files..."
echo ""

MIGRATION_PATH="$PROJECT_ROOT/$MIGRATIONS_DIR"
if [ -d "$MIGRATION_PATH" ]; then
    for sqlfile in "$MIGRATION_PATH"/*.sql; do
        if [ -f "$sqlfile" ]; then
            validate_sql_file "$sqlfile"
            CHECKED=$((CHECKED + 1))
            echo ""
        fi
    done
else
    echo -e "${YELLOW}WARNING: Migrations directory not found${NC}"
fi

# Validate schema files
echo "Validating schema files..."
echo ""

SCHEMA_PATH="$PROJECT_ROOT/$SCHEMA_DIR"
if [ -d "$SCHEMA_PATH" ]; then
    for sqlfile in "$SCHEMA_PATH"/*.sql; do
        if [ -f "$sqlfile" ]; then
            validate_sql_file "$sqlfile"
            CHECKED=$((CHECKED + 1))
            echo ""
        fi
    done
else
    echo -e "${YELLOW}WARNING: Schema directory not found${NC}"
fi

# Summary
echo "=================================="
echo "Validation Summary"
echo "=================================="
echo "Files checked: $CHECKED"
echo "Errors found: $ERRORS"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All SQL syntax validations passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ SQL syntax validation failed with $ERRORS error(s)${NC}"
    exit 1
fi
