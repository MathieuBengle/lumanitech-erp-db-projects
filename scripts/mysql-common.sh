#!/bin/bash
# =============================================================================
# MySQL Connection Helper Library
# =============================================================================
# Description: Common functions for secure MySQL connections
# Usage: Source this file in your scripts: source "$(dirname "$0")/mysql-common.sh"
# =============================================================================

# Global variables for MySQL connection
declare -a MYSQL_CMD
DB_HOST=""
DB_USER=""
DB_NAME=""
LOGIN_PATH=""

# =============================================================================
# Parse common MySQL connection arguments
# =============================================================================
# Parses standard arguments: --login-path, -h/--host, -u/--user, database name
# Usage: parse_mysql_args "$@"
# Sets: LOGIN_PATH, DB_HOST, DB_USER, DB_NAME
# =============================================================================
parse_mysql_args() {
    # Default values
    DB_HOST="${DB_HOST:-localhost}"
    DB_USER="${DB_USER:-root}"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --login-path=*)
                LOGIN_PATH="${1#*=}"
                shift
                ;;
            --login-path)
                LOGIN_PATH="$2"
                shift 2
                ;;
            -h|--host)
                DB_HOST="$2"
                shift 2
                ;;
            -u|--user)
                DB_USER="$2"
                shift 2
                ;;
            -d|--database)
                DB_NAME="$2"
                shift 2
                ;;
            *)
                # If it's not a flag and DB_NAME is empty, assume it's the database name
                if [[ -z "$DB_NAME" && ! "$1" =~ ^- ]]; then
                    DB_NAME="$1"
                fi
                shift
                ;;
        esac
    done
}

# =============================================================================
# Auto-detect available login-path from mysql_config_editor
# =============================================================================
# Returns: First available login-path name, or empty string if none found
# =============================================================================
auto_detect_login_path() {
    if ! command -v mysql_config_editor &> /dev/null; then
        echo ""
        return
    fi
    
    # Get first login-path from mysql_config_editor
    local first_path=$(mysql_config_editor print --all 2>/dev/null | grep '^\[' | head -1 | tr -d '[]')
    echo "$first_path"
}

# =============================================================================
# Setup MySQL command array for secure execution
# =============================================================================
# Determines the best authentication method and configures MYSQL_CMD array
# Priority: CLI --login-path > env MYSQL_LOGIN_PATH > auto-detect > interactive
# Usage: setup_mysql_cmd
# Sets: MYSQL_CMD (array)
# =============================================================================
setup_mysql_cmd() {
    local password=""
    
    # Priority 1: CLI --login-path argument
    if [[ -n "$LOGIN_PATH" ]]; then
        MYSQL_CMD=(mysql --login-path="$LOGIN_PATH")
        if [[ -n "$DB_HOST" ]]; then
            MYSQL_CMD+=(-h "$DB_HOST")
        fi
        echo "[INFO] Using login-path: $LOGIN_PATH" >&2
        return 0
    fi
    
    # Priority 2: Environment variable MYSQL_LOGIN_PATH
    if [[ -n "${MYSQL_LOGIN_PATH:-}" ]]; then
        LOGIN_PATH="$MYSQL_LOGIN_PATH"
        MYSQL_CMD=(mysql --login-path="$LOGIN_PATH")
        if [[ -n "$DB_HOST" ]]; then
            MYSQL_CMD+=(-h "$DB_HOST")
        fi
        echo "[INFO] Using login-path from environment: $LOGIN_PATH" >&2
        return 0
    fi
    
    # Priority 3: Auto-detect from mysql_config_editor
    local detected_path=$(auto_detect_login_path)
    if [[ -n "$detected_path" ]]; then
        LOGIN_PATH="$detected_path"
        MYSQL_CMD=(mysql --login-path="$LOGIN_PATH")
        if [[ -n "$DB_HOST" ]]; then
            MYSQL_CMD+=(-h "$DB_HOST")
        fi
        echo "[INFO] Auto-detected login-path: $LOGIN_PATH" >&2
        return 0
    fi
    
    # Priority 4: No fallback - require login-path for security
    echo "[ERROR] No login-path configured." >&2
    echo "" >&2
    echo "For security reasons, password-based authentication is not supported." >&2
    echo "Please configure a login-path using one of these methods:" >&2
    echo "" >&2
    echo "  1. Run the setup helper:" >&2
    echo "     ./scripts/setup_login.sh" >&2
    echo "" >&2
    echo "  2. Configure manually:" >&2
    echo "     mysql_config_editor set --login-path=local --host=localhost --user=root --password" >&2
    echo "" >&2
    echo "  3. Use command-line option:" >&2
    echo "     $0 --login-path=local ..." >&2
    echo "" >&2
    echo "  4. Set environment variable:" >&2
    echo "     export MYSQL_LOGIN_PATH=local" >&2
    echo "" >&2
    return 1
}

# =============================================================================
# Test MySQL connection
# =============================================================================
# Tests the connection using configured MYSQL_CMD
# Usage: test_mysql_connection
# Returns: 0 if successful, 1 if failed
# =============================================================================
test_mysql_connection() {
    if "${MYSQL_CMD[@]}" -e "SELECT 1" 2>/dev/null >/dev/null; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# Execute MySQL command
# =============================================================================
# Executes a MySQL command using the configured connection
# Filters out password warnings automatically while preserving errors
# Usage: exec_mysql [additional mysql args...]
# Example: exec_mysql -e "SHOW DATABASES"
# =============================================================================
exec_mysql() {
    # Execute and filter only the specific password warning
    # Preserve other error messages
    "${MYSQL_CMD[@]}" "$@" 2> >(grep -v "Using a password on the command line" >&2)
}

# =============================================================================
# Print MySQL connection help
# =============================================================================
print_mysql_help() {
    cat << 'EOF'
MySQL Connection Options:
  --login-path=NAME    Use mysql_config_editor login-path (REQUIRED for security)
  -h, --host HOST      MySQL host (default: localhost)
  -u, --user USER      MySQL user (default: root)
  -d, --database NAME  Database name

Environment Variables:
  MYSQL_LOGIN_PATH     Login-path to use (overridden by --login-path)

Authentication Priority:
  1. CLI --login-path argument
  2. MYSQL_LOGIN_PATH environment variable
  3. Auto-detect first available login-path
  4. Error if no login-path found (password auth disabled for security)

For secure authentication, use mysql_config_editor:
  mysql_config_editor set --login-path=local --host=localhost --user=root --password

Or use the interactive helper:
  ./scripts/setup_login.sh

Then use:
  ./script.sh --login-path=local
  or
  export MYSQL_LOGIN_PATH=local && ./script.sh

SECURITY NOTE: Interactive password prompts are disabled to prevent password
exposure in process lists. Login-path configuration is required.
EOF
}
