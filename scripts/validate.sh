#!/bin/bash
# =============================================================================
# Validate Script
# =============================================================================
# Description: Validates migrations and SQL syntax
# Usage: ./scripts/validate.sh
# Exit Codes: 0 = success, 1 = validation errors
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="$PROJECT_ROOT/migrations"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error counter
ERRORS=0

echo "=================================="
echo "Database Validation"
echo "=================================="
echo ""

# =============================================================================
# Step 1: Validate Migration File Naming
# =============================================================================
echo -e "${BLUE}Step 1: Validating migration file naming...${NC}"

# Check if migrations directory exists
if [[ ! -d "$MIGRATIONS_DIR" ]]; then
    echo -e "${RED}✗ Migrations directory not found: $MIGRATIONS_DIR${NC}"
    ERRORS=$((ERRORS + 1))
else
    # Find all migration files (excluding TEMPLATE.sql and README.md)
    migration_files=($(find "$MIGRATIONS_DIR" -maxdepth 1 -name "V*.sql" -type f ! -name "TEMPLATE.sql" | sort))
    
    if [[ ${#migration_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠ No migration files found${NC}"
    else
        echo "Found ${#migration_files[@]} migration file(s)"
        
        # Validate each migration file
        for migration_file in "${migration_files[@]}"; do
            filename=$(basename "$migration_file")
            
            # Check naming convention: V###_description.sql (single underscore)
            if [[ ! "$filename" =~ ^V[0-9]{3}_[a-z0-9_]+\.sql$ ]]; then
                echo -e "${RED}✗ Invalid filename: $filename${NC}"
                echo "  Expected format: V###_description.sql (e.g., V001_create_table.sql)"
                ERRORS=$((ERRORS + 1))
            else
                echo -e "${GREEN}✓${NC} $filename"
            fi
            
            # Check file is readable and not empty
            if [[ ! -r "$migration_file" ]]; then
                echo -e "${RED}✗ File not readable: $filename${NC}"
                ERRORS=$((ERRORS + 1))
            elif [[ ! -s "$migration_file" ]]; then
                echo -e "${RED}✗ File is empty: $filename${NC}"
                ERRORS=$((ERRORS + 1))
            fi
        done
        
        # Check for version number gaps and duplicates
        echo ""
        echo "Checking version sequence..."
        
        versions=()
        for migration_file in "${migration_files[@]}"; do
            filename=$(basename "$migration_file")
            # Extract version number (e.g., V001 -> 001)
            if [[ "$filename" =~ ^V([0-9]{3})_ ]]; then
                version="${BASH_REMATCH[1]}"
                versions+=("$version")
            fi
        done
        
        # Check for duplicates
        duplicates=$(printf '%s\n' "${versions[@]}" | sort | uniq -d)
        if [[ -n "$duplicates" ]]; then
            echo -e "${RED}✗ Duplicate version numbers found:${NC}"
            echo "$duplicates"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✓${NC} No duplicate versions"
        fi
        
        # Check for expected sequence (allowing V000 as first)
        expected=0
        for version in $(printf '%s\n' "${versions[@]}" | sort); do
            version_num=$((10#$version))
            if [[ $version_num -ne $expected ]]; then
                echo -e "${YELLOW}⚠ Version gap detected: expected V$(printf '%03d' $expected), found V$version${NC}"
            fi
            expected=$((version_num + 1))
        done
    fi
fi

echo ""

# =============================================================================
# Step 2: Validate SQL Syntax
# =============================================================================
echo -e "${BLUE}Step 2: Validating SQL syntax...${NC}"

# Basic SQL syntax checks (without MySQL connection)
for migration_file in "${migration_files[@]}"; do
    filename=$(basename "$migration_file")
    
    # Check for common typos
    if grep -q "IF NOT EXITS" "$migration_file" 2>/dev/null; then
        echo -e "${RED}✗ Typo found in $filename: 'IF NOT EXITS' should be 'IF NOT EXISTS'${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check for balanced parentheses (basic check)
    open_parens=$(grep -o '(' "$migration_file" | wc -l)
    close_parens=$(grep -o ')' "$migration_file" | wc -l)
    if [[ $open_parens -ne $close_parens ]]; then
        echo -e "${YELLOW}⚠ Unbalanced parentheses in $filename${NC}"
    fi
    
    # Check for presence of SQL statements
    if ! grep -q -i "CREATE\|ALTER\|DROP\|INSERT\|UPDATE\|DELETE" "$migration_file" 2>/dev/null; then
        echo -e "${YELLOW}⚠ No SQL statements found in $filename${NC}"
    fi
done

echo -e "${GREEN}✓ Basic SQL syntax checks completed${NC}"
echo ""

# =============================================================================
# Step 3: Validate TEMPLATE.sql
# =============================================================================
echo -e "${BLUE}Step 3: Validating TEMPLATE.sql...${NC}"

template_file="$MIGRATIONS_DIR/TEMPLATE.sql"
if [[ ! -f "$template_file" ]]; then
    echo -e "${YELLOW}⚠ TEMPLATE.sql not found${NC}"
else
    # Check template has required placeholders
    if grep -q "V###" "$template_file" && grep -q "description" "$template_file"; then
        echo -e "${GREEN}✓${NC} TEMPLATE.sql contains required placeholders"
    else
        echo -e "${RED}✗ TEMPLATE.sql missing required placeholders (V###, description)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check template has schema_migrations insert
    if grep -q "schema_migrations" "$template_file"; then
        echo -e "${GREEN}✓${NC} TEMPLATE.sql includes schema_migrations tracking"
    else
        echo -e "${RED}✗ TEMPLATE.sql missing schema_migrations tracking${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo ""

# =============================================================================
# Step 4: Validate Schema Structure
# =============================================================================
echo -e "${BLUE}Step 4: Validating schema structure...${NC}"

schema_dir="$PROJECT_ROOT/schema"
required_dirs=("tables")
optional_dirs=("views" "procedures" "functions" "triggers" "indexes")

# Check required directories
for dir in "${required_dirs[@]}"; do
    if [[ -d "$schema_dir/$dir" ]]; then
        echo -e "${GREEN}✓${NC} schema/$dir exists"
    else
        echo -e "${RED}✗ Required directory missing: schema/$dir${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check optional directories (just report)
for dir in "${optional_dirs[@]}"; do
    if [[ -d "$schema_dir/$dir" ]]; then
        echo -e "${GREEN}✓${NC} schema/$dir exists"
    fi
done

# Check for 01_create_database.sql
if [[ -f "$schema_dir/01_create_database.sql" ]]; then
    echo -e "${GREEN}✓${NC} 01_create_database.sql exists"
    
    # Verify it contains CREATE DATABASE
    if grep -q "CREATE DATABASE" "$schema_dir/01_create_database.sql"; then
        echo -e "${GREEN}✓${NC} 01_create_database.sql contains CREATE DATABASE"
    else
        echo -e "${RED}✗ 01_create_database.sql missing CREATE DATABASE statement${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}⚠ 01_create_database.sql not found${NC}"
fi

echo ""

# =============================================================================
# Step 5: Validate Seeds Structure
# =============================================================================
echo -e "${BLUE}Step 5: Validating seeds structure...${NC}"

seeds_dir="$PROJECT_ROOT/seeds"
dev_seeds_dir="$seeds_dir/dev"

if [[ -d "$dev_seeds_dir" ]]; then
    echo -e "${GREEN}✓${NC} seeds/dev directory exists"
    
    seed_files=($(find "$dev_seeds_dir" -name "*.sql" -type f 2>/dev/null | sort))
    if [[ ${#seed_files[@]} -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Found ${#seed_files[@]} seed file(s)"
    else
        echo -e "${YELLOW}⚠ No seed files found in seeds/dev${NC}"
    fi
else
    echo -e "${RED}✗ seeds/dev directory not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# =============================================================================
# Summary
# =============================================================================
echo "=================================="
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}✓ All validations passed!${NC}"
    echo "=================================="
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s)${NC}"
    echo "=================================="
    exit 1
fi
