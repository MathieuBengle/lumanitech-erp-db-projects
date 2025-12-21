#!/bin/bash
# =============================================================================
# Load Seed Data Script
# =============================================================================
# Description: Loads all seed data files in order
# Usage: ./scripts/load-seeds.sh <database> <host> <user>
# Example: ./scripts/load-seeds.sh lumanitech_projects localhost root
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

SEEDS_DIR="seeds"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEEDS_PATH="$PROJECT_ROOT/$SEEDS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================="
echo "Seed Data Loading Script"
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

# Check if seeds directory exists
if [ ! -d "$SEEDS_PATH" ]; then
    echo -e "${RED}ERROR: Seeds directory not found: $SEEDS_PATH${NC}"
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
    if mysql -h "$HOST" -u "$USER" -p"$PASSWORD" "$DATABASE" < "$filepath" 2>&1; then
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
