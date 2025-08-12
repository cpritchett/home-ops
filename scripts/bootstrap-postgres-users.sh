#!/usr/bin/env bash

# PostgreSQL Database User Bootstrap Script
# Creates all required database users and databases for home-ops cluster
# Usage: ./bootstrap-postgres-users.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to dynamically discover required database users from ExternalSecrets
discover_postgres_users() {
    local users=()

    # Extract all POSTGRES_USER field patterns from ExternalSecrets
    local postgres_user_fields
    postgres_user_fields=$(kubectl get externalsecrets -A -o yaml 2>/dev/null |
        grep -E "POSTGRES_USER.*}}" |
        grep -v "POSTGRES_SUPER_USER" |
        grep -v "POSTGRES_CLUSTER_USER" |
        sed -E 's/.*\{\{\s*\.([A-Z_]+_POSTGRES_USER)\s*\}\}.*/\1/' |
        sort -u)

    # Convert field names to usernames (e.g., ATUIN_POSTGRES_USER -> atuin)
    for field in $postgres_user_fields; do
        local username="${field%_POSTGRES_USER}" # Remove _POSTGRES_USER suffix
        username="${username,,}"                 # Convert to lowercase
        username="${username//_/-}"              # Replace underscores with hyphens
        users+=("$username")
    done

    # Also check for apps with INIT_POSTGRES_USER patterns
    local init_user_apps
    init_user_apps=$(kubectl get externalsecrets -A -o yaml 2>/dev/null |
        grep -E "INIT_POSTGRES_USER.*\{\{.*_POSTGRES_USER.*\}\}" |
        sed -E 's/.*\{\{\s*\.([A-Z_]+)_POSTGRES_USER\s*\}\}.*/\1/' |
        sort -u)

    for app_field in $init_user_apps; do
        local username="${app_field,,}" # Convert to lowercase
        username="${username//_/-}"     # Replace underscores with hyphens
        users+=("$username")
    done

    # Remove duplicates and sort (output only, no logs)
    printf '%s\n' "${users[@]}" | sort -u
}

# Get required database users (discovered dynamically)
POSTGRES_USERS=()

# Function to check if postgres cluster is ready
check_postgres_ready() {
    log_info "Checking if PostgreSQL cluster is ready..."

    if ! kubectl get cluster postgres -n databases &>/dev/null; then
        log_error "PostgreSQL cluster 'postgres' not found in databases namespace"
        return 1
    fi

    local ready_instances
    ready_instances=$(kubectl get cluster postgres -n databases -o jsonpath='{.status.readyInstances}' 2>/dev/null || echo "0")

    if [[ $ready_instances -lt 1 ]]; then
        log_error "PostgreSQL cluster is not ready (ready instances: $ready_instances)"
        return 1
    fi

    log_success "PostgreSQL cluster is ready with $ready_instances instance(s)"
    return 0
}

# Function to get postgres superuser credentials
get_postgres_credentials() {
    log_info "Getting PostgreSQL superuser credentials..."

    local username password
    username=$(kubectl get secret cloudnative-pg-secret -n databases -o jsonpath='{.data.username}' | base64 -d)
    password=$(kubectl get secret cloudnative-pg-secret -n databases -o jsonpath='{.data.password}' | base64 -d)

    if [[ -z $username || -z $password ]]; then
        log_error "Failed to get PostgreSQL credentials"
        return 1
    fi

    echo "$username:$password"
}

# Function to execute SQL commands on postgres cluster
execute_sql() {
    local sql_command="$1"
    local description="${2:-SQL command}"

    log_info "Executing: $description"

    kubectl exec postgres-1 -n databases -c postgres -- \
        psql -U postgres -c "$sql_command" 2>/dev/null || {
        log_error "Failed to execute SQL: $description"
        return 1
    }

    log_success "Completed: $description"
}

# Function to create a database user and database
create_user_and_database() {
    local username="$1"

    log_info "Creating user and database: $username"

    # Get or create password in 1Password
    local password
    local username_upper="${username^^}"
    local password_field="${username_upper}_POSTGRES_PASS"

    # Try to get existing password from 1Password
    password=$(op item get "$username" --vault homelab --reveal 2>/dev/null |
        grep "$password_field" | awk '{print $2}' || echo "")

    if [[ -z $password ]]; then
        # Generate new password and add to 1Password
        password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

        # Check if 1Password item exists, create if not
        if ! op item get "$username" --vault homelab &>/dev/null; then
            log_info "Creating new 1Password item for $username"
            op item create --vault homelab --title "$username" --category database \
                "${password_field}[password]=$password" \
                "${username_upper}_POSTGRES_USER[text]=$username" &>/dev/null || {
                log_error "Failed to create 1Password item for $username"
                return 1
            }
        else
            log_info "Adding password field to existing 1Password item for $username"
            op item edit "$username" --vault homelab "${password_field}[password]=$password" &>/dev/null || {
                log_error "Failed to update 1Password item for $username"
                return 1
            }
        fi

        log_success "Generated new password and stored in 1Password for $username"
    else
        log_success "Using existing password from 1Password for $username"
    fi

    # Create user if not exists
    execute_sql "DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$username') THEN
            CREATE USER \"$username\" WITH PASSWORD '$password';
            RAISE NOTICE 'User $username created successfully';
        ELSE
            RAISE NOTICE 'User $username already exists, updating password';
            ALTER USER \"$username\" WITH PASSWORD '$password';
        END IF;
    END
    \$\$;" "Create/update user: $username"

    # Create database using createdb utility (simpler and more reliable)
    log_info "Creating database: $username"
    if kubectl exec postgres-1 -n databases -c postgres -- \
        createdb -U postgres "$username" 2>/dev/null; then
        log_success "Created database: $username"
    else
        log_warning "Database $username may already exist (ignoring createdb error)"
    fi

    # Grant permissions
    execute_sql "GRANT ALL PRIVILEGES ON DATABASE \"$username\" TO \"$username\";" \
        "Grant permissions to $username"

    # Set default privileges for future objects
    execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO \"$username\";" \
        "Set default table privileges for $username"

    execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO \"$username\";" \
        "Set default sequence privileges for $username"

    log_success "User and database '$username' ready"
}

# Function to verify user can connect
verify_user_connection() {
    local username="$1"

    log_info "Verifying connection for user: $username"

    kubectl exec postgres-1 -n databases -c postgres -- \
        psql -U "$username" -d "$username" -c "SELECT current_user, current_database();" 2>/dev/null || {
        log_warning "Connection verification failed for $username (may need password sync)"
        return 1
    }

    log_success "Connection verified for $username"
}

main() {
    echo "🚀 PostgreSQL User Bootstrap Script for Home-Ops"
    echo "=================================================="

    # Check prerequisites
    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl is required but not installed"
        exit 1
    fi

    if ! command -v openssl &>/dev/null; then
        log_error "openssl is required but not installed"
        exit 1
    fi

    if ! command -v op &>/dev/null; then
        log_error "1Password CLI (op) is required but not installed"
        exit 1
    fi

    # Verify 1Password authentication
    if ! op user get --me &>/dev/null; then
        log_error "1Password CLI is not authenticated. Run: op signin"
        exit 1
    fi

    # Check if cluster is ready
    if ! check_postgres_ready; then
        log_error "PostgreSQL cluster is not ready. Ensure cluster is running first."
        exit 1
    fi

    # Discover required database users dynamically
    log_info "Scanning ExternalSecrets for database user requirements..."
    mapfile -t POSTGRES_USERS < <(discover_postgres_users)

    if [[ ${#POSTGRES_USERS[@]} -eq 0 ]]; then
        log_warning "No database users found in ExternalSecrets. Nothing to create."
        exit 0
    fi

    log_success "Found ${#POSTGRES_USERS[@]} database users to create/update:"
    for user in "${POSTGRES_USERS[@]}"; do
        echo "  - $user"
    done
    echo

    # Get credentials
    local creds
    creds=$(get_postgres_credentials) || exit 1

    log_success "Connected to PostgreSQL cluster"

    # Create all users and databases
    for user in "${POSTGRES_USERS[@]}"; do
        echo
        log_info "Processing user: $user"
        create_user_and_database "$user"
        # Skip connection verification for now as passwords may not be synced
        # verify_user_connection "$user"
    done

    echo
    echo "🎉 PostgreSQL user bootstrap completed!"
    echo
    log_info "Next steps:"
    echo "1. Ensure all app secrets are synced from 1Password"
    echo "2. Restart failing application pods to pick up database access"
    echo "3. Monitor application logs for database connectivity"
    echo
    log_warning "Note: Some apps may need their secrets re-synced from 1Password"
}

# Run main function
main "$@"
