#!/bin/bash
# =============================================================================
# Load Seed Data Script
# =============================================================================
# Description: Loads all seed data files in order
# Usage: ./scripts/load-seeds.sh [options]
# Example: ./scripts/load-seeds.sh --login-path=local -d lumanitech_projects
# Exit Codes: 0 = success, 1 = error
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEEDS_DIR="seeds"
SEEDS_PATH="$PROJECT_ROOT/$SEEDS_DIR"

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
Load Seed Data Script

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
echo "Seed Data Loading Script"
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

# Check if seeds directory exists
if [ ! -d "$SEEDS_PATH" ]; then
    echo -e "${RED}ERROR: Seeds directory not found: $SEEDS_PATH${NC}"
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

# Get seed files (sorted by name to respect numbering)
SEED_FILES=($(ls "$SEEDS_PATH"/*.sql 2>/dev/null | sort))

if [ ${#SEED_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No seed files found${NC}"
    exit 0
fi

echo "Found ${#SEED_FILES[@]} seed file(s)"
echo ""

# Confirm before loading
echo -e "${YELLOW}WARNING: This will insert data into the database${NC}"
echo "Continue? (y/n)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi
echo ""

# Load each seed file
SUCCESS=0
FAILED=0

for filepath in "${SEED_FILES[@]}"; do
    filename=$(basename "$filepath")
    
    echo -e "${BLUE}Loading: $filename${NC}"
    
    # Load seed data
    if exec_mysql "$DB_NAME" < "$filepath"; then
        echo -e "${GREEN}  ✓ Successfully loaded${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}  ✗ Failed to load${NC}"
        FAILED=$((FAILED + 1))
        
        # Ask if we should continue
        echo ""
        echo "Seed loading failed. Continue with remaining seeds? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Aborting seed loading process"
            exit 1
        fi
    fi
    echo ""
done

# Summary
echo "=================================="
echo "Seed Loading Summary"
echo "=================================="
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All seed data loaded successfully!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some seed files failed to load${NC}"
    exit 1
fi
