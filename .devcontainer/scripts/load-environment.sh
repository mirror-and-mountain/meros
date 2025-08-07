#!/bin/bash
set -e
trap 'echo "Error on line $LINENO on host: $(hostname)"; exit 1' ERR

OUTPUT_ENV_FILE="$HOME/config/.environment.env"

# Set path to the environment.json file
ENV_CONFIG_PATH="$HOME/config/environment.json"

# See if the ENVIRONMENT variable is set, or try to load from file
if [ -z "$ENVIRONMENT" ]; then
  echo "ENVIRONMENT variable is not set. Checking for configuration file: $ENV_CONFIG_PATH"

  if [ -f "$ENV_CONFIG_PATH" ]; then
    echo "Found $ENV_CONFIG_PATH. Loading JSON from file."
    ENVIRONMENT=$(cat "$ENV_CONFIG_PATH")
  else
    echo "Error: Missing ENVIRONMENT variable containing JSON configuration, and file '$ENV_CONFIG_PATH' not found."
    exit 1
  fi
else
  echo "Using ENVIRONMENT variable for JSON configuration."
fi

# Clear or create the output .env file
> "$OUTPUT_ENV_FILE"

# Helper function to validate and append to the .env file
append_env_var() {
  local PREFIX="$1"   # e.g., "STAGING"
  local SUFFIX="$2"   # e.g., "URL"
  local VALUE="$3"    # The actual value, potentially "null" string from jq
  local ENV_VAR_NAME="${PREFIX}_${SUFFIX}"

  if [ -n "$VALUE" ] && [ "$VALUE" != "null" ]; then
    # Escape double quotes within the value
    local ESCAPED_VALUE="${VALUE//\"/\\\"}"
    echo "${ENV_VAR_NAME}=\"${ESCAPED_VALUE}\"" >> "$OUTPUT_ENV_FILE"
    echo "Info: Added $ENV_VAR_NAME to $OUTPUT_ENV_FILE"
    return 0
  else
    echo "Warning: ${ENV_VAR_NAME} is missing or null. Not adding to $OUTPUT_ENV_FILE."
    echo "# ${ENV_VAR_NAME}=<MISSING_OR_NULL>" >> "$OUTPUT_ENV_FILE"
    return 1
  fi
}

echo "Generating environment settings for $OUTPUT_ENV_FILE..."

# --- Wordpress & Container Settings ---
echo "" >> "$OUTPUT_ENV_FILE"
echo "# --- General WP & VSCode Settings ---" >> "$OUTPUT_ENV_FILE"

# Extract all top-level keys and their values
THEME_NAME="${WP_THEME_NAME:-"meros-blocks"}" # Default to "meros-blocks" if not set
WP_THEME_REPO=$(echo "$ENVIRONMENT" | jq -r '.wp_theme_repo // "meros-blocks"')
WP_TITLE=$(echo "$ENVIRONMENT" | jq -r '.wp_title // "Meros"')
WP_ADMIN_USER=$(echo "$ENVIRONMENT" | jq -r '.wp_admin_user // "admin"')
WP_ADMIN_PASSWORD=$(echo "$ENVIRONMENT" | jq -r '.wp_admin_password // "password"')
WP_ADMIN_EMAIL=$(echo "$ENVIRONMENT" | jq -r '.wp_admin_email // "your-email@example.com"')
WP_DB_HOST=$(echo "$ENVIRONMENT" | jq -r '.wp_db_host // "db"')
WP_DB_NAME=$(echo "$ENVIRONMENT" | jq -r '.wp_db_name // "wordpress"')
WP_DB_USER=$(echo "$ENVIRONMENT" | jq -r '.wp_db_user // "dbuser"')
WP_DB_PASSWORD=$(echo "$ENVIRONMENT" | jq -r '.wp_db_password // "dbpassword"')
WP_DB_PREFIX=$(echo "$ENVIRONMENT" | jq -r '.wp_db_prefix // "wp_"')

append_env_var "WP" "THEME_NAME" "$THEME_NAME"
append_env_var "WP" "THEME_REPO" "$WP_THEME_REPO"
append_env_var "WP" "TITLE" "$WP_TITLE"
append_env_var "WP" "ADMIN_USER" "$WP_ADMIN_USER"
append_env_var "WP" "ADMIN_PASSWORD" "$WP_ADMIN_PASSWORD"
append_env_var "WP" "ADMIN_EMAIL" "$WP_ADMIN_EMAIL"
append_env_var "WP" "DB_HOST" "$WP_DB_HOST"
append_env_var "WP" "DB_NAME" "$WP_DB_NAME"
append_env_var "WP" "DB_USER" "$WP_DB_USER"
append_env_var "WP" "DB_PASSWORD" "$WP_DB_PASSWORD"
append_env_var "WP" "DB_PREFIX" "$WP_DB_PREFIX"

# --- Remote Server Settings ---
echo "" >> "$OUTPUT_ENV_FILE"
echo "# --- Remote Server Settings ---" >> "$OUTPUT_ENV_FILE"

# Load remote server environment keys (e.g., "production", "staging")
readarray -t SERVERS < <(echo "$ENVIRONMENT" | jq -r '.remote_servers | keys[]')

echo "Getting environment remote server settings for $OUTPUT_ENV_FILE..."

# Iterate over each remote server environment
for server in "${SERVERS[@]}"; do
  echo "" >> "$OUTPUT_ENV_FILE" # Add a blank line for readability between environments
  echo "# --- Remote Server: ${server^^} ---" >> "$OUTPUT_ENV_FILE"

  # Convert server name to uppercase for prefixing
  REMOTE_PREFIX="${server^^}"

  # Extract values using jq
  URL=$(echo "$ENVIRONMENT" | jq -r --arg s "$server" '.remote_servers[$s].url // ""')
  WP_PATH=$(echo "$ENVIRONMENT" | jq -r --arg s "$server" '.remote_servers[$s].path // "public_html"')
  SSH_HOST=$(echo "$ENVIRONMENT" | jq -r --arg s "$server" '.remote_servers[$s].ssh.host // ""')
  SSH_PORT=$(echo "$ENVIRONMENT" | jq -r --arg s "$server" '.remote_servers[$s].ssh.port // "22"')
  SSH_USER=$(echo "$ENVIRONMENT" | jq -r --arg s "$server" '.remote_servers[$s].ssh.user // ""')
  # See whether an SSH key is provided in the JSON or shell environment
  SSH_KEY_FROM_JSON=$(echo "$ENVIRONMENT" | jq -r --arg s "$server" '.remote_servers[$s].ssh.key // ""')

  # Append variables to the .env file
  append_env_var "$REMOTE_PREFIX" "URL" "$URL"
  append_env_var "$REMOTE_PREFIX" "PATH" "$WP_PATH"
  append_env_var "$REMOTE_PREFIX" "SSH_HOST" "$SSH_HOST"
  append_env_var "$REMOTE_PREFIX" "SSH_PORT" "$SSH_PORT"
  append_env_var "$REMOTE_PREFIX" "SSH_USER" "$SSH_USER"

  # Handling for SSH_KEY
  SSH_KEY_VAR_NAME="${REMOTE_PREFIX}_SSH_KEY" # e.g., PRODUCTION_SSH_KEY (for shell fallback)
  SSH_KEY_FROM_SHELL="${!SSH_KEY_VAR_NAME}" # Get value from shell environment

  SSH_KEY_VALUE=""
  if [ -n "$SSH_KEY_FROM_JSON" ]; then
    SSH_KEY_VALUE="$SSH_KEY_FROM_JSON"
  elif [ -n "$SSH_KEY_FROM_SHELL" ]; then
    echo "Info: Using SSH key from shell environment variable '${SSH_KEY_VAR_NAME}' for ${server}."
    SSH_KEY_VALUE="$SSH_KEY_FROM_SHELL"
  fi

  # Use the determined SSH_KEY_VALUE to create the file
  if [ -z "$SSH_KEY_VALUE" ]; then
    echo "Warning: SSH key for '${server}' (from JSON or shell variable '${SSH_KEY_VAR_NAME}') is empty or not set. No key file will be created."
    echo "# ${REMOTE_PREFIX}_SSH_KEY_FILE=<MISSING>" >> "$OUTPUT_ENV_FILE"
  else
    SSH_KEY_FILE="$HOME/.ssh/${server}_key" # Use lowercase server name for file

    mkdir -p "$HOME/.ssh" || { echo "Error: Failed to create $HOME/.ssh directory for ${server}. Exiting."; exit 1; }
    rm -f "$SSH_KEY_FILE" || { echo "Error: Failed to remove existing key file $SSH_KEY_FILE for ${server}. Exiting."; exit 1; }
    printf %s "$SSH_KEY_VALUE" | base64 -d > "$SSH_KEY_FILE" || { echo "Error: Failed to decode and write SSH key to $SSH_KEY_FILE for ${server}. Exiting."; exit 1; }
    chmod 600 "$SSH_KEY_FILE" || { echo "Error: Failed to set permissions on $SSH_KEY_FILE for ${server}. Exiting."; exit 1; }

    echo "Info: SSH key for '${server}' saved to '$SSH_KEY_FILE' with permissions 600."
    append_env_var "$REMOTE_PREFIX" "SSH_KEY_FILE" "$SSH_KEY_FILE"
  fi
done

echo ""
echo "Finished generating $OUTPUT_ENV_FILE."
echo "You can now source this file: source $OUTPUT_ENV_FILE"

# To verify the content
echo "--- Content of $OUTPUT_ENV_FILE ---"
cat "$OUTPUT_ENV_FILE"
echo "--- End of $OUTPUT_ENV_FILE ---"