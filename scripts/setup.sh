#!/bin/bash
# =============================================================================
# Database Setup Script
# =============================================================================
# Description: Creates database and optionally applies migrations and seeds
# Usage: ./scripts/setup.sh [options]
# Example: ./scripts/setup.sh --login-path=local -d lumanitech_projects --with-seeds
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common MySQL functions
source "$SCRIPT_DIR/mysql-common.sh"

# Script-specific variables
WITH_SEEDS=false
FORCE=false

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
Database Setup Script

Usage: $0 [options]

Options:
  -d, --database NAME  Database name (required)
  --with-seeds         Load seed data after migrations
  --force              Drop existing database if it exists
  --help               Show this help message

$(print_mysql_help)

Examples:
  # Using login-path
  $0 --login-path=local -d lumanitech_projects --with-seeds

  # Using environment variable
  export MYSQL_LOGIN_PATH=local
  $0 -d lumanitech_projects

  # Interactive (will prompt for password)
  $0 -h localhost -u root -d lumanitech_projects
EOF
}

# =============================================================================
# Parse arguments
# =============================================================================
parse_args() {
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
                # Let parse_mysql_args handle it
                shift
                ;;
        esac
    done
}

# Parse all arguments (will be parsed again by parse_mysql_args)
ARGS=("$@")
parse_args "$@"

# Parse MySQL connection arguments
parse_mysql_args "${ARGS[@]}"

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
echo "Database Setup Script"
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

# Test connection
echo "Testing database connection..."
if ! test_mysql_connection; then
    echo -e "${RED}ERROR: Cannot connect to MySQL${NC}"
    echo "Please check your credentials and try again."
    exit 1
fi
echo -e "${GREEN}✓ Database connection successful${NC}"
echo ""

# Check if database exists
DB_EXISTS=$(exec_mysql -e "SHOW DATABASES LIKE '$DB_NAME'" -s -N)

if [[ -n "$DB_EXISTS" ]]; then
    if [[ "$FORCE" == "true" ]]; then
        echo -e "${YELLOW}Dropping existing database '$DB_NAME'...${NC}"
        exec_mysql -e "DROP DATABASE $DB_NAME"
        echo -e "${GREEN}✓ Database dropped${NC}"
    else
        echo -e "${YELLOW}WARNING: Database '$DB_NAME' already exists${NC}"
        echo "Use --force to drop and recreate it."
        echo "Or run apply-migrations.sh to apply pending migrations."
        exit 1
    fi
fi

# Create database
echo "Creating database '$DB_NAME'..."
exec_mysql -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
echo -e "${GREEN}✓ Database created${NC}"
echo ""

# Apply migrations
echo "Applying migrations..."
MIGRATIONS_DIR="$PROJECT_ROOT/migrations"
MIGRATION_FILES=($(ls "$MIGRATIONS_DIR"/V*.sql 2>/dev/null | sort))

if [ ${#MIGRATION_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No migration files found${NC}"
else
    echo "Found ${#MIGRATION_FILES[@]} migration file(s)"
    
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
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All migrations applied successfully${NC}"
    else
        echo -e "${RED}✗ Migration failed${NC}"
        exit 1
    fi
fi
echo ""

# Load seeds if requested
if [[ "$WITH_SEEDS" == "true" ]]; then
    echo "Loading seed data..."
    SEEDS_DIR="$PROJECT_ROOT/seeds"
    SEED_FILES=($(ls "$SEEDS_DIR"/*.sql 2>/dev/null | sort))
    
    if [ ${#SEED_FILES[@]} -eq 0 ]; then
        echo -e "${YELLOW}WARNING: No seed files found${NC}"
    else
        echo "Found ${#SEED_FILES[@]} seed file(s)"
        
        SUCCESS=0
        FAILED=0
        
        for filepath in "${SEED_FILES[@]}"; do
            filename=$(basename "$filepath")
            echo -e "${BLUE}  Loading: $filename${NC}"
            
            if exec_mysql "$DB_NAME" < "$filepath"; then
                echo -e "${GREEN}    ✓ Success${NC}"
                SUCCESS=$((SUCCESS + 1))
            else
                echo -e "${RED}    ✗ Failed${NC}"
                FAILED=$((FAILED + 1))
                break
            fi
        done
        
        if [ $FAILED -eq 0 ]; then
            echo -e "${GREEN}✓ All seed data loaded successfully${NC}"
        else
            echo -e "${RED}✗ Seed loading failed${NC}"
            exit 1
        fi
    fi
    echo ""
fi

# Summary
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo -e "${GREEN}Database '$DB_NAME' is ready to use${NC}"
echo ""
