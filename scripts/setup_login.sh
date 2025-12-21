#!/bin/bash
# =============================================================================
# Setup MySQL Login-Path Helper
# =============================================================================
# Description: Interactive script to configure mysql_config_editor login-path
# Usage: ./scripts/setup_login.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================="
echo "MySQL Login-Path Configuration Helper"
echo "============================================="
echo ""
echo "This script will help you configure a secure"
echo "MySQL login-path using mysql_config_editor."
echo ""

# Check if mysql_config_editor is available
if ! command -v mysql_config_editor &> /dev/null; then
    echo -e "${RED}ERROR: mysql_config_editor is not installed${NC}"
    echo ""
    echo "mysql_config_editor is part of MySQL client tools."
    echo "Please install MySQL client (version 5.6+):"
    echo ""
    echo "  Ubuntu/Debian: sudo apt-get install mysql-client"
    echo "  RHEL/CentOS:   sudo yum install mysql"
    echo "  macOS:         brew install mysql-client"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ mysql_config_editor found${NC}"
echo ""

# Show existing login-paths
echo "Existing login-paths:"
echo "--------------------"
if mysql_config_editor print --all 2>/dev/null | grep -q '^\['; then
    mysql_config_editor print --all 2>/dev/null | grep '^\[' | tr -d '[]' | while read -r path; do
        echo -e "  ${BLUE}$path${NC}"
    done
else
    echo "  (none)"
fi
echo ""

# Get login-path name
echo -e "${YELLOW}Enter login-path name (e.g., 'local', 'dev', 'staging'):${NC}"
read -r LOGIN_PATH_NAME

if [[ -z "$LOGIN_PATH_NAME" ]]; then
    echo -e "${RED}ERROR: Login-path name cannot be empty${NC}"
    exit 1
fi

# Check if login-path already exists
if mysql_config_editor print --all 2>/dev/null | grep -q "^\[$LOGIN_PATH_NAME\]"; then
    echo -e "${YELLOW}WARNING: Login-path '$LOGIN_PATH_NAME' already exists${NC}"
    echo "Do you want to overwrite it? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 0
    fi
    # Remove existing login-path
    mysql_config_editor remove --login-path="$LOGIN_PATH_NAME" 2>/dev/null || true
fi

# Get MySQL connection details
echo ""
echo -e "${YELLOW}Enter MySQL host (default: localhost):${NC}"
read -r DB_HOST
DB_HOST="${DB_HOST:-localhost}"

echo -e "${YELLOW}Enter MySQL user (default: root):${NC}"
read -r DB_USER
DB_USER="${DB_USER:-root}"

echo ""
echo "Configuration summary:"
echo "  Login-path: $LOGIN_PATH_NAME"
echo "  Host:       $DB_HOST"
echo "  User:       $DB_USER"
echo ""
echo -e "${YELLOW}mysql_config_editor will now prompt for the password...${NC}"
echo ""

# Configure login-path using mysql_config_editor
if mysql_config_editor set \
    --login-path="$LOGIN_PATH_NAME" \
    --host="$DB_HOST" \
    --user="$DB_USER" \
    --password; then
    echo ""
    echo -e "${GREEN}✓ Login-path '$LOGIN_PATH_NAME' configured successfully${NC}"
else
    echo ""
    echo -e "${RED}✗ Failed to configure login-path${NC}"
    exit 1
fi

# Test the connection
echo ""
echo "Testing MySQL connection..."
if mysql --login-path="$LOGIN_PATH_NAME" -e "SELECT 1" 2>/dev/null >/dev/null; then
    echo -e "${GREEN}✓ Connection test successful!${NC}"
else
    echo -e "${RED}✗ Connection test failed${NC}"
    echo "Please check your credentials and try again."
    exit 1
fi

# Success message with usage instructions
echo ""
echo "============================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "============================================="
echo ""
echo "You can now use this login-path with scripts:"
echo ""
echo "  ${BLUE}# Using command-line option:${NC}"
echo "  ./scripts/setup.sh --login-path=$LOGIN_PATH_NAME"
echo "  ./scripts/apply-migrations.sh --login-path=$LOGIN_PATH_NAME -d lumanitech_projects"
echo ""
echo "  ${BLUE}# Using environment variable:${NC}"
echo "  export MYSQL_LOGIN_PATH=$LOGIN_PATH_NAME"
echo "  ./scripts/setup.sh -d lumanitech_projects"
echo ""
echo "  ${BLUE}# For CI/CD (add to secrets/environment):${NC}"
echo "  MYSQL_LOGIN_PATH=$LOGIN_PATH_NAME"
echo ""
echo "The password is stored encrypted in:"
echo "  ~/.mylogin.cnf"
echo ""
echo -e "${YELLOW}Security Notes:${NC}"
echo "  • Do NOT commit ~/.mylogin.cnf to version control"
echo "  • Keep ~/.mylogin.cnf secure (readable only by your user)"
echo "  • For CI/CD, configure login-path in the CI environment"
echo ""
