#!/bin/bash
set -e
trap 'echo "Error on line $LINENO on host: $(hostname)"; exit 1' ERR

# --- Get Parameters from Command Line ---
# Argument 1: REMOTE_SERVER name (e.g., "production", "staging")
# Argument 2 (Optional): Flag to run pre-sync tests (e.g., "test")

if [ -z "$1" ]; then
  echo "Usage: composer run sync:to-remote -- <REMOTE_SERVER> [run_tests_flag]"
  echo "Example: composer run sync:to-remote -- production"
  echo "Example with tests: composer run sync:to-remote -- staging test"
  exit 1
fi

# --- Configuration ---
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

# Convert user input to uppercase (for env var lookup)
REMOTE_SERVER="${REMOTE_SERVER_INPUT^^}"

# --- Run VAR Check Tests ---
echo "--- Checking remote server variables for ${REMOTE_SERVER_INPUT} ---"
source "$VAR_SCRIPT" "${REMOTE_SERVER}" || {
  echo "Error: Pre-sync remote server variable check failed for ${REMOTE_SERVER_INPUT}. Aborting sync."
  exit 1
}
echo "--- Remote server variable check passed for ${REMOTE_SERVER_INPUT} ---"

# --- Run Pre-Sync Tests (Optional) ---
if [ "$RUN_PRE_SYNC_TESTS" = "true" ]; then
  echo "--- Running pre-sync tests for ${REMOTE_SERVER_INPUT} ---"
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

# --- Determine skip plugins ---
SKIP_PLUGINS_VAR="${REMOTE_SERVER}_SKIP_PLUGINS"
SKIP_PLUGINS_VALUE="${!SKIP_PLUGINS_VAR:-}"

if [ -n "$SKIP_PLUGINS_VALUE" ]; then
  WP_SKIP_PLUGINS_PARAM="--skip-plugins=$(echo "$SKIP_PLUGINS_VALUE" | tr -d '[:space:]')"
  echo "Detected skip plugins for $REMOTE_SERVER: $SKIP_PLUGINS_VALUE"
else
  WP_SKIP_PLUGINS_PARAM=""
  echo "No skip plugins configured for $REMOTE_SERVER."
fi

# --- Create Temp Directory for DB ---
echo "Creating temporary directory..."
TMP_DIR="tmp"
mkdir -p "$TMP_DIR"
TMP_DB_FILE="$TMP_DIR/dev-db.sql"

# --- Export Local Database ---
echo "Exporting database from local (dev)..."
wp db export "$TMP_DB_FILE" --add-drop-table --skip-themes

# --- Sync Operations ---
echo "Establishing SSH connection to $REMOTE_SERVER using ${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:${REMOTE_SSH_PORT_VALUE}..."
echo "Transferring database from local to remote server..."
scp -P "$REMOTE_SSH_PORT_VALUE" \
    -i "$REMOTE_SSH_KEY_FILE_VALUE" \
    -o StrictHostKeyChecking=no "$TMP_DB_FILE" "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:$REMOTE_PATH_VALUE/dev-db.sql"

# --- Import database on remote server ---
echo "Importing database on remote server..."
ssh -i "${REMOTE_SSH_KEY_FILE_VALUE}" \
    -o StrictHostKeyChecking=no \
    -p "${REMOTE_SSH_PORT_VALUE}" \
    "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}" bash -s <<EOF
  set -e
  cd "$REMOTE_PATH_VALUE"

  echo "Importing database..."
  wp db import dev-db.sql --path=. --quiet $WP_SKIP_PLUGINS_PARAM

  echo "Running search-replace for URLs..."
  wp search-replace '$LOCAL_WP_URL' '$REMOTE_URL_VALUE' --path=. --skip-columns=guid --quiet $WP_SKIP_PLUGINS_PARAM

  echo "Updating siteurl and home..."
  wp option update siteurl '$REMOTE_URL_VALUE' --path=. --quiet $WP_SKIP_PLUGINS_PARAM
  wp option update home '$REMOTE_URL_VALUE' --path=. --quiet $WP_SKIP_PLUGINS_PARAM

  echo "Flushing rewrite rules..."
  wp rewrite flush --hard --path=. --quiet $WP_SKIP_PLUGINS_PARAM

  echo "Clearing transients and cache..."
  wp transient delete --all --path=. --quiet $WP_SKIP_PLUGINS_PARAM
  wp cache flush --path=. --quiet $WP_SKIP_PLUGINS_PARAM || echo "No object cache to flush."

  rm -f dev-db.sql
EOF

# --- Sync uploads and plugins to remote ---
echo "Syncing uploads to REMOTE..."
rsync -avz \
  -e "ssh -p "$REMOTE_SSH_PORT_VALUE" -i $REMOTE_SSH_KEY_FILE_VALUE -o StrictHostKeyChecking=no" \
  "wp-content/uploads/" \
  "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:$REMOTE_PATH_VALUE/wp-content/uploads/" \
  --delete

echo "Syncing plugins to REMOTE..."
rsync -avz \
  -e "ssh -p "$REMOTE_SSH_PORT_VALUE" -i $REMOTE_SSH_KEY_FILE_VALUE -o StrictHostKeyChecking=no" \
  "wp-content/plugins/" \
  "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:$REMOTE_PATH_VALUE/wp-content/plugins/" \
  --delete

# --- Clean up active_plugins ---
if [ -n "$LOCAL_SKIP_PLUGINS" ]; then
  echo "Ensuring include plugins are activated on remote..."
  ssh -i "${REMOTE_SSH_KEY_FILE_VALUE}" \
      -o StrictHostKeyChecking=no \
      -p "${REMOTE_SSH_PORT_VALUE}" \
      "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}" bash -s <<EOF
    set -e
    cd "$REMOTE_PATH_VALUE"

    INCLUDE_LIST="${LOCAL_SKIP_PLUGINS//,/ }"
    SKIP_LIST="${SKIP_PLUGINS_VALUE//,/ }"

    for slug in \$INCLUDE_LIST; do
      # Only activate if not in SKIP_LIST
      if ! [[ " \$SKIP_LIST " =~ " \$slug " ]]; then
        echo "Activating plugin: \$slug"
        wp plugin activate "\$slug" --quiet || echo "Warning: Could not activate plugin \$slug"
      else
        echo "Skipping activation for plugin (in skip list): \$slug"
      fi
    done
    echo "Include plugins activated on remote."
EOF
fi

if [ -n "$SKIP_PLUGINS_VALUE" ]; then
  echo "Ensuring skip plugins are deactivated on remote..."
  ssh -i "${REMOTE_SSH_KEY_FILE_VALUE}" \
      -o StrictHostKeyChecking=no \
      -p "${REMOTE_SSH_PORT_VALUE}" \
      "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}" bash -s <<EOF
    set -e
    cd "$REMOTE_PATH_VALUE"

    ACTIVE_PLUGINS_JSON=\$(wp option get active_plugins --format=json)
    SKIP_LIST="${SKIP_PLUGINS_VALUE//,/ }"

    for slug in $SKIP_LIST; do
      ACTIVE_PLUGINS_JSON=$(echo "$ACTIVE_PLUGINS_JSON" | sed -E "s#\"$slug/[^\"/]*\",?##g" | sed -E 's#,\s*,#,#g' | sed -E 's#\[\s*,#\[#g' | sed -E 's#,\s*\]#]#g')
    done

    if [ -n "\$ACTIVE_PLUGINS_JSON" ] && [ "\$ACTIVE_PLUGINS_JSON" != "null" ]; then
      wp option update active_plugins "\$ACTIVE_PLUGINS_JSON" --format=json --quiet
      echo "Cleaned active_plugins on remote."
    else
      echo "Warning: No active plugins found or unexpected null result."
    fi
EOF
fi

# --- Sync theme ---
if [ -n "$THEME_DIR" ]; then
  echo "Syncing theme to REMOTE..."
  rsync -avz \
    -e "ssh -p $REMOTE_SSH_PORT_VALUE -i $REMOTE_SSH_KEY_FILE_VALUE -o StrictHostKeyChecking=no" \
    --exclude '/.devcontainer/' \
    --exclude='/.git/' \
    --exclude='/.vscode/' \
    --exclude='/node_modules/' \
    --exclude='/.DS_Store' \
    --exclude='/composer.lock' \
    --exclude='/package-lock.json' \
    --exclude='/.gitattributes' \
    --exclude='/.gitignore' \
    --exclude '/storage/logs/laravel.log' \
    --exclude '/app/Features/**/assets/src/' \
    --exclude '/app/Features/**/blocks/src/' \
    --exclude '/app/Features/**/node_modules/' \
    --exclude '/app/Features/**/composer.json/' \
    --exclude '/app/Features/**/package.json/' \
    --exclude '/app/Features/**/package.lock/' \
    --exclude '/app/Features/**/webpack.assets.config.js/' \
    "wp-content/themes/$THEME_DIR/" \
    "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:$REMOTE_PATH_VALUE/wp-content/themes/$THEME_DIR/" \
    --delete \
    --delete-excluded
fi

# --- Clean up ---
rm -rf "$TMP_DB_FILE"

echo "Sync to $REMOTE_SERVER complete."
# --- End Sync Operations ---