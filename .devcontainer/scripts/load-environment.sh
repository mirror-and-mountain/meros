#!/bin/bash
set -e
trap 'echo "Error on line $LINENO on host: $(hostname)"; exit 1' ERR

# --- Configuration ---
ENV_FILE="$HOME/config/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $HOME/config/.env couldn't be found. Check your .devcontainer directory and ensure one exists before building. Aborting..."
  exit 1
fi

# Get remotes.json file
REMOTE_CONFIG_FILE="$HOME/config/remotes/remotes.json"

if [ ! -f "$REMOTE_CONFIG_FILE" ]; then
  echo "A remotes.json file couldn't be found. Skipping configure remote server properties..."
  exit 0
fi

REMOTE_CONFIG=$(cat "$REMOTE_CONFIG_FILE")
# --- End Configuration ---

# Helper function to validate and append to the .env file
append_env_var() {
  local PREFIX="$1"   # e.g., "STAGING"
  local SUFFIX="$2"   # e.g., "URL"
  local VALUE="$3"    # The actual value, potentially "null" string from jq
  local ENV_VAR_NAME="${PREFIX}_${SUFFIX}"

  if [ -n "$VALUE" ] && [ "$VALUE" != "null" ]; then
    # Escape double quotes within the value
    local ESCAPED_VALUE="${VALUE//\"/\\\"}"
    echo "${ENV_VAR_NAME}=\"${ESCAPED_VALUE}\"" >> "$ENV_FILE"
    echo "Info: Added $ENV_VAR_NAME to $ENV_FILE"
    return 0
  else
    echo "Warning: ${ENV_VAR_NAME} is missing or null. Not adding to $ENV_FILE."
    echo "# ${ENV_VAR_NAME}=<MISSING_OR_NULL>" >> "$ENV_FILE"
    return 1
  fi
}

# --- Append Remote Server Config to .env ---
echo "Appending remote server configurations to .env..."

echo "" >> "$ENV_FILE"
echo "# --- Remote Server Settings ---" >> "$ENV_FILE"

# Load remote server environment keys (e.g., "production", "staging")
readarray -t SERVERS < <(echo "$REMOTE_CONFIG" | jq -r 'keys[] | select(. != "$schema")')

# Iterate over each remote server environment
for server in "${SERVERS[@]}"; do
  echo "" >> "$ENV_FILE" # Add a blank line for readability between environments
  echo "# --- Remote Server: ${server^^} ---" >> "$ENV_FILE"

  # Convert server name to uppercase for prefixing
  REMOTE_PREFIX="${server^^}"

  # Extract values using jq
  URL=$(echo "$REMOTE_CONFIG" | jq -r --arg s "$server" '.[$s].url // ""')
  WP_PATH=$(echo "$REMOTE_CONFIG" | jq -r --arg s "$server" '.[$s].path // "public_html"')
  SSH_HOST=$(echo "$REMOTE_CONFIG" | jq -r --arg s "$server" '.[$s].ssh.host // ""')
  SSH_PORT=$(echo "$REMOTE_CONFIG" | jq -r --arg s "$server" '.[$s].ssh.port // "22"')
  SSH_USER=$(echo "$REMOTE_CONFIG" | jq -r --arg s "$server" '.[$s].ssh.user // ""')

  # Append variables to the .env file
  append_env_var "$REMOTE_PREFIX" "URL" "$URL"
  append_env_var "$REMOTE_PREFIX" "PATH" "$WP_PATH"
  append_env_var "$REMOTE_PREFIX" "SSH_HOST" "$SSH_HOST"
  append_env_var "$REMOTE_PREFIX" "SSH_PORT" "$SSH_PORT"
  append_env_var "$REMOTE_PREFIX" "SSH_USER" "$SSH_USER"

  # Handling for SSH_KEY
  SSH_KEY_VAR_NAME="${REMOTE_PREFIX}_SSH_KEY" # e.g., PRODUCTION_SSH_KEY (for shell fallback)
  SSH_KEY_FROM_JSON=$(echo "$REMOTE_CONFIG" | jq -r --arg s "$server" '.[$s].ssh.key // ""')
  SSH_KEY_FROM_SHELL="${!SSH_KEY_VAR_NAME}" # Get value from shell environment

  SSH_KEY_VALUE=""

  if [ -n "$SSH_KEY_FROM_SHELL" ]; then
    echo "Info: Using SSH key from shell environment variable '${SSH_KEY_VAR_NAME}' for ${server}."
    SSH_KEY_VALUE="$SSH_KEY_FROM_SHELL"

    SSH_KEY_FILE="$HOME/.ssh/${server}_key"

    rm -f "$SSH_KEY_FILE" || { echo "Error: Failed to remove existing key file $SSH_KEY_FILE for ${server}. Exiting."; exit 1; }
    printf %s "$SSH_KEY_VALUE" | base64 -d > "$SSH_KEY_FILE" || { echo "Error: Failed to write SSH key to $SSH_KEY_FILE for ${server}. Exiting."; exit 1; }
    chmod 600 "$SSH_KEY_FILE" || { echo "Error: Failed to set permissions on $SSH_KEY_FILE for ${server}. Exiting."; exit 1; }

    echo "Info: SSH key for '${server}' saved to '$SSH_KEY_FILE' with permissions 600."
    append_env_var "$REMOTE_PREFIX" "SSH_KEY_FILE" "$SSH_KEY_FILE"

  elif [ -n "$SSH_KEY_FROM_JSON" ]; then
    echo "Info: Using SSH key value from remotes.json."
    SSH_KEY_VALUE="$SSH_KEY_FROM_JSON"

    if [ -f "$HOME/.ssh/$SSH_KEY_VALUE" ]; then
      echo "Info: Using SSH key from file '$HOME/.ssh/$SSH_KEY_VALUE' for ${server}. Renaming to ${server}_key..."
      SSH_KEY_FILE="$HOME/.ssh/$SSH_KEY_VALUE"
      
      # Ensure permissions are set for usage
      chmod 600 "$SSH_KEY_FILE" || { echo "Error: Failed to set permissions on $SSH_KEY_FILE for ${server}. Exiting."; exit 1; }
      
      echo "Info: Set permissions 600 for '${server}' SSH key file."
      append_env_var "$REMOTE_PREFIX" "SSH_KEY_FILE" "$SSH_KEY_FILE"

    else
      echo "Warning: Couldn't locate "$HOME/.ssh/$SSH_KEY_VALUE". ${server} ssh key value will not be set."
      echo "# ${REMOTE_PREFIX}_SSH_KEY_FILE=<MISSING>" >> "$ENV_FILE"
    fi

  else 
    echo "Warning: Couldn't locate SSH key configuration. SSH key value will not be set."
    echo "# ${REMOTE_PREFIX}_SSH_KEY_FILE=<MISSING>" >> "$ENV_FILE"
  fi
done

echo ""
echo "Finished appending $ENV_FILE."
echo "You can now source this file: source $ENV_FILE"

# To verify the content
echo "--- Content of $ENV_FILE ---"
cat "$ENV_FILE"
echo "--- End of $ENV_FILE ---"

# --- End Append Remote Server Config to .env ---