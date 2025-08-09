#!/bin/bash
set -e
trap 'echo "Error on line $LINENO on host: $(hostname)"; exit 1' ERR

# --- Get Parameters from Command Line ---
# Argument 1: REMOTE_SERVER name (e.g., "production", "staging")
# Argument 2 (Optional): Flag to run pre-sync tests (e.g., "test")

if [ -z "$1" ]; then
  echo "Usage: composer run sync:from-remote -- <REMOTE_SERVER> [run_tests_flag]"
  echo "Example: composer run sync:from-remote -- production"
  echo "Example with tests: composer run sync:from-remote -- staging test"
  exit 1
fi

# --- Configuration ---
ENV_FILE="$HOME/config/.env"
TEST_SCRIPT="test-remote.sh"
VAR_SCRIPT="check-remote-vars.sh"
LOCAL_PATH="/var/www/html"
# --- End Configuration ---

# Navigate to Wordpress root directory
cd "$LOCAL_PATH" || {
  echo "Error: Could not change directory to $LOCAL_PATH."
  exit 1
}

REMOTE_SERVER_INPUT="$1"
RUN_PRE_SYNC_TESTS="${2:-false}" # Default to 'false' if second arg is not provided

# Convert user input to uppercase
REMOTE_SERVER="${REMOTE_SERVER_INPUT^^}"
# --- End Configuration ---

# --- Load and check env file ---
if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE..."
  source "$ENV_FILE"
else
  echo "Error: $HOME/config/.env couldn't be found. Check your .devcontainer directory and ensure one exists before building. Aborting..."
  exit 1
fi

# --- Run VAR Check Tests ---
echo "--- Checking remote server variables for ${REMOTE_SERVER_INPUT} ---"
  # Execute the test script as a child process.
  source "$VAR_SCRIPT" "${REMOTE_SERVER}" || {
    echo "Error: Pre-sync remote server variable check failed for ${REMOTE_SERVER_INPUT}. Aborting sync."
    exit 1
  }
echo "--- Remote server variable check passed for ${REMOTE_SERVER_INPUT} ---"

# --- Run Pre-Sync Tests (Optional) ---
if [ "$RUN_PRE_SYNC_TESTS" = "test" ]; then
  echo "--- Running pre-sync tests for ${REMOTE_SERVER_INPUT} ---"
  # Execute the test script as a child process.
  "$TEST_SCRIPT" "${REMOTE_SERVER_INPUT}" || {
    echo "Error: Pre-sync tests failed for ${REMOTE_SERVER_INPUT}. Aborting sync."
    exit 1
  }
  echo "--- Pre-sync tests passed for ${REMOTE_SERVER_INPUT} ---"
else
  echo "Pre-sync tests skipped (to run, add 'test' as the second argument: e.g., 'composer run sync-remote -- production test')."
fi

# --- Configure Site URL ---
echo "Establishing local WordPress URL..."
if [ -n "$CODESPACE_NAME" ]; then
  export LOCAL_WP_URL="https://${CODESPACE_NAME}-80.app.github.dev"
  echo "Detected Codespace. Using LOCAL_WP_URL: $LOCAL_WP_URL"
else
  export LOCAL_WP_URL="http://localhost:8000"
fi

echo "Detected local WordPress URL: $LOCAL_WP_URL"

# --- Create Temp Directory for DB ---
echo "Creating temporary directory..."
TMP_DIR="tmp"
mkdir -p "$TMP_DIR"
TMP_DB_FILE="$TMP_DIR/remote-db.sql"

# --- Sync Operations ---
echo "Establishing SSH connection to $REMOTE_SERVER using ${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:${REMOTE_SSH_PORT_VALUE}..."

# Export database from remote and pipe to local file
echo "Exporting database from remote server to local file $TMP_DB_FILE..."
ssh -i "${REMOTE_SSH_KEY_FILE_VALUE}" \
    -o StrictHostKeyChecking=no \
    -p "${REMOTE_SSH_PORT_VALUE}" \
    "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}" \
    "wp db export - --path=\"${REMOTE_PATH_VALUE}\" --add-drop-table" \
     > "$TMP_DB_FILE"

echo "Database exported to $TMP_DB_FILE"

# Import database into local environment
echo "Importing database into local environment..."
wp db import "$TMP_DB_FILE" || { echo "Error: Local DB import failed. Ensure local DB connection is configured."; exit 1; }

# Run search-replace to update URLs in the database
echo "Running search-replace to update URLs..."
wp search-replace "$REMOTE_URL_VALUE" "$LOCAL_WP_URL" --skip-columns=guid

# Sync uploads and plugins from remote
echo "Syncing uploads from REMOTE..."
rsync -avz \
    -e "ssh -p $REMOTE_SSH_PORT_VALUE -i $REMOTE_SSH_KEY_FILE_VALUE -o StrictHostKeyChecking=no" \
    "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:$REMOTE_PATH_VALUE/wp-content/uploads/" \
    "wp-content/uploads/" \
    --delete

echo "Syncing plugins from REMOTE..."
rsync -avz \
    -e "ssh -p $REMOTE_SSH_PORT_VALUE -i $REMOTE_SSH_KEY_FILE_VALUE -o StrictHostKeyChecking=no" \
    "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:$REMOTE_PATH_VALUE/wp-content/plugins/" \
    "wp-content/plugins/" \
    --delete

rm -rf $TMP_DIR

echo "Sync from REMOTE complete."
# --- End Sync Operations ---

echo "Cleaning up environment..."
# Fix site URLs
wp option update home "$LOCAL_WP_URL"
wp option update siteurl "$LOCAL_WP_URL"

# Flush rewrite rules
wp option update permalink_structure '/%postname%/'
wp rewrite flush --hard

# Clear transients and caches
wp transient delete --all
wp cache flush || echo "No object cache available, skipping..."

echo "Environment clean-up complete."
echo "Checking .htaccess file."

# Create .htaccess file if it doesn't exist
HTACCESS_PATH=".htaccess"
if [ ! -f "$HTACCESS_PATH" ]; then
  echo "Creating .htaccess file at $HTACCESS_PATH"
  cat <<EOF > "$HTACCESS_PATH"
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\\.php\$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
else
  echo ".htaccess already exists at $HTACCESS_PATH"
fi

echo "Sync from $REMOTE_SERVER complete."