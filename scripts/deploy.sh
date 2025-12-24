#!/bin/bash
# =============================================================================
# Deploy Script
# =============================================================================
# Description: Complete database deployment - creates database, applies schema,
#              runs migrations, and optionally loads seed data
# Usage: ./scripts/deploy.sh [options]
# Example: ./scripts/deploy.sh --login-path=local -d lumanitech_erp_projects --with-seeds
# Exit Codes: 0 = success, 1 = error
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCHEMA_DIR="schema"
MIGRATIONS_DIR="migrations"
SEEDS_DIR="seeds/dev"
SCHEMA_PATH="$PROJECT_ROOT/$SCHEMA_DIR"
MIGRATIONS_PATH="$PROJECT_ROOT/$MIGRATIONS_DIR"
SEEDS_PATH="$PROJECT_ROOT/$SEEDS_DIR"

# Source common MySQL functions
source "$SCRIPT_DIR/mysql-common.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
WITH_SEEDS=false
FORCE=false

# =============================================================================
# Print usage information
# =============================================================================
print_usage() {
    cat << EOF
Deploy Script

Usage: $0 [options]

Options:
  -d, --database NAME  Database name (required)
  --with-seeds         Load seed data after migrations
  --force              Drop existing database if it exists
  --help               Show this help message

$(print_mysql_help)

Examples:
  # Deploy with seeds
  $0 --login-path=local -d lumanitech_erp_projects --with-seeds

  # Deploy without seeds
  $0 --login-path=local -d lumanitech_erp_projects

  # Force recreate database
  $0 --login-path=local -d lumanitech_erp_projects --force --with-seeds

  # Using environment variable
  export MYSQL_LOGIN_PATH=local
  $0 -d lumanitech_erp_projects --with-seeds
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-seeds)
            WITH_SEEDS=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            # Store argument for MySQL parsing
            MYSQL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Parse MySQL connection arguments
parse_mysql_args "${MYSQL_ARGS[@]}"

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
echo "Database Deployment"
echo "=================================="
if is_wsl2; then
    echo "[INFO] WSL2 detected. Use --login-path configured with user 'admin'." >&2
fi
echo "Database: $DB_NAME"
echo "With Seeds: $WITH_SEEDS"
echo "Force Recreate: $FORCE"
echo ""

# =============================================================================
# Step 1: Create Database
# =============================================================================
echo -e "${BLUE}Step 1: Creating database...${NC}"

if [[ "$FORCE" == "true" ]]; then
    echo "Dropping existing database if it exists..."
    if exec_mysql -e "DROP DATABASE IF EXISTS $DB_NAME" 2>/dev/null; then
        echo -e "${GREEN}✓ Existing database dropped${NC}"
    fi
fi

# Create database
if exec_mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci" 2>/dev/null; then
    echo -e "${GREEN}✓ Database created: $DB_NAME${NC}"
else
    echo -e "${RED}✗ Failed to create database${NC}"
    exit 1
fi
echo ""

# =============================================================================
# Step 2: Apply Schema
# =============================================================================
echo -e "${BLUE}Step 2: Applying schema...${NC}"

apply_complete_schema_snapshot() {
    local snapshot_file="$SCHEMA_PATH/complete_schema.sql"
    if [[ -f "$snapshot_file" ]]; then
        echo "Applying complete schema snapshot..."
        if exec_mysql "$DB_NAME" < "$snapshot_file" 2>/dev/null; then
            echo -e "${GREEN}✓ Complete schema applied${NC}"
            return 0
        else
            echo -e "${RED}✗${NC}"
            echo -e "${RED}ERROR: Failed to apply complete schema snapshot${NC}"
            exit 1
        fi
    fi
    return 1
}

# Apply table definitions (snapshot preferred)
if apply_complete_schema_snapshot; then
    echo "Skipping individual table definitions (snapshot applied)."
else
    if [[ -d "$SCHEMA_PATH/tables" ]]; then
        echo "Applying table definitions..."
        for schema_file in "$SCHEMA_PATH"/tables/*.sql; do
            if [[ -f "$schema_file" ]]; then
                filename=$(basename "$schema_file")
                echo -n "  - $filename... "
                if exec_mysql "$DB_NAME" < "$schema_file" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC}"
                else
                    echo -e "${RED}✗${NC}"
                    echo -e "${RED}ERROR: Failed to apply $filename${NC}"
                    exit 1
                fi
            fi
        done
    fi
fi

# Apply views if they exist
if [[ -d "$SCHEMA_PATH/views" ]] && [[ -n "$(ls -A "$SCHEMA_PATH/views" 2>/dev/null)" ]]; then
    echo "Applying views..."
    for schema_file in "$SCHEMA_PATH"/views/*.sql; do
        if [[ -f "$schema_file" ]]; then
            filename=$(basename "$schema_file")
            echo -n "  - $filename... "
            if exec_mysql "$DB_NAME" < "$schema_file" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
            fi
        fi
    done
fi

# Apply procedures if they exist
if [[ -d "$SCHEMA_PATH/procedures" ]] && [[ -n "$(ls -A "$SCHEMA_PATH/procedures" 2>/dev/null)" ]]; then
    echo "Applying stored procedures..."
    for schema_file in "$SCHEMA_PATH"/procedures/*.sql; do
        if [[ -f "$schema_file" ]]; then
            filename=$(basename "$schema_file")
            echo -n "  - $filename... "
            if exec_mysql "$DB_NAME" < "$schema_file" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
            fi
        fi
    done
fi

# Apply functions if they exist
if [[ -d "$SCHEMA_PATH/functions" ]] && [[ -n "$(ls -A "$SCHEMA_PATH/functions" 2>/dev/null)" ]]; then
    echo "Applying functions..."
    for schema_file in "$SCHEMA_PATH"/functions/*.sql; do
        if [[ -f "$schema_file" ]]; then
            filename=$(basename "$schema_file")
            echo -n "  - $filename... "
            if exec_mysql "$DB_NAME" < "$schema_file" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
            fi
        fi
    done
fi

# Apply triggers if they exist
if [[ -d "$SCHEMA_PATH/triggers" ]] && [[ -n "$(ls -A "$SCHEMA_PATH/triggers" 2>/dev/null)" ]]; then
    echo "Applying triggers..."
    for schema_file in "$SCHEMA_PATH"/triggers/*.sql; do
        if [[ -f "$schema_file" ]]; then
            filename=$(basename "$schema_file")
            echo -n "  - $filename... "
            if exec_mysql "$DB_NAME" < "$schema_file" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
            fi
        fi
    done
fi

# Apply indexes if they exist
if [[ -d "$SCHEMA_PATH/indexes" ]] && [[ -n "$(ls -A "$SCHEMA_PATH/indexes" 2>/dev/null)" ]]; then
    echo "Applying indexes..."
    for schema_file in "$SCHEMA_PATH"/indexes/*.sql; do
        if [[ -f "$schema_file" ]]; then
            filename=$(basename "$schema_file")
            echo -n "  - $filename... "
            if exec_mysql "$DB_NAME" < "$schema_file" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
            fi
        fi
    done
fi

echo -e "${GREEN}✓ Schema applied successfully${NC}"
echo ""

# =============================================================================
# Step 3: Apply Migrations
# =============================================================================
echo -e "${BLUE}Step 3: Applying migrations...${NC}"

# Find all migration files and sort them
migration_files=($(find "$MIGRATIONS_PATH" -name "V*.sql" -type f | sort))

if [[ ${#migration_files[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No migration files found${NC}"
else
    echo "Found ${#migration_files[@]} migration(s)"
    
    for migration_file in "${migration_files[@]}"; do
        filename=$(basename "$migration_file")
        echo -n "  - $filename... "
        
        if exec_mysql "$DB_NAME" < "$migration_file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            echo -e "${RED}ERROR: Failed to apply $filename${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✓ All migrations applied successfully${NC}"
fi
echo ""

# =============================================================================
# Step 4: Load Seeds (if requested)
# =============================================================================
if [[ "$WITH_SEEDS" == "true" ]]; then
    echo -e "${BLUE}Step 4: Loading seed data...${NC}"
    echo -e "${YELLOW}WARNING: Seed data is for development/testing only!${NC}"
    
    if [[ ! -d "$SEEDS_PATH" ]]; then
        echo -e "${YELLOW}No seeds directory found at $SEEDS_PATH${NC}"
    else
        seed_files=($(find "$SEEDS_PATH" -name "*.sql" -type f | sort))
        
        if [[ ${#seed_files[@]} -eq 0 ]]; then
            echo -e "${YELLOW}No seed files found${NC}"
        else
            echo "Found ${#seed_files[@]} seed file(s)"
            
            for seed_file in "${seed_files[@]}"; do
                filename=$(basename "$seed_file")
                echo -n "  - $filename... "
                
                if exec_mysql "$DB_NAME" < "$seed_file" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC}"
                else
                    echo -e "${YELLOW}⚠${NC}"
                    echo -e "${YELLOW}WARNING: Failed to load $filename (continuing...)${NC}"
                fi
            done
            
            echo -e "${GREEN}✓ Seed data loaded${NC}"
        fi
    fi
    echo ""
fi

# =============================================================================
# Summary
# =============================================================================
echo "=================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=================================="
echo "Database: $DB_NAME"
echo ""
echo "Next steps:"
echo "  - Connect to the database:"
echo "    mysql --login-path=<your-login-path> -D $DB_NAME"
echo ""
echo "  - Verify tables:"
echo "    SHOW TABLES;"
echo ""
if [[ "$WITH_SEEDS" == "true" ]]; then
    echo "  - Check seed data:"
    echo "    SELECT * FROM projects LIMIT 5;"
    echo ""
fi

exit 0
