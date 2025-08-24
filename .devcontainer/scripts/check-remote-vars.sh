#!/bin/bash
set -e
trap 'echo "Error on line $LINENO on host: $(hostname)"; exit 1' ERR

# --- Get Input Parameters ---
# Argument 1: REMOTE_SERVER name (e.g., "PRODUCTION")

if [ -z "$1" ]; then
  echo "Can't check remote variables without a REMOTE_SERVER name."
  exit 1
fi

# --- Configuration ---
ENV_FILE="$HOME/config/.env"
REMOTE_SERVER="$1"
# --- End Configuration ---

# --- Load and check env file ---
if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE..."
  source "$ENV_FILE"
else
  echo "Error: $HOME/config/.env couldn't be found. Check your .devcontainer directory and ensure one exists before building. Aborting..."
  exit 1
fi

# --- Check Environment Variables ---
echo "Checking environment variables for remote server: $REMOTE_SERVER."

THEME_DIR="${WP_THEME_NAME}"

# Remote site URL
REMOTE_URL_VAR_NAME="${REMOTE_SERVER}_URL"
if [ -z "${!REMOTE_URL_VAR_NAME}" ]; then
  echo "Error: ${REMOTE_URL_VAR_NAME} is not set. Please check your remote server name and settings."
  exit 1;
fi
REMOTE_URL_VALUE="${!REMOTE_URL_VAR_NAME}"

# Remote WordPress path
REMOTE_PATH_VAR_NAME="${REMOTE_SERVER}_PATH"
if [ -z "${!REMOTE_PATH_VAR_NAME}" ]; then
  echo "Error: ${REMOTE_PATH_VAR_NAME} is not set. Please check your remote server name and settings."
  exit 1;
fi
REMOTE_PATH_VALUE="${!REMOTE_PATH_VAR_NAME}"

# Remote SSH Host
REMOTE_SSH_HOST_VAR_NAME="${REMOTE_SERVER}_SSH_HOST"
if [ -z "${!REMOTE_SSH_HOST_VAR_NAME}" ]; then
  echo "Error: ${REMOTE_SSH_HOST_VAR_NAME} is not set. Please check your remote server name and settings."
  exit 1;
fi
REMOTE_SSH_HOST_VALUE="${!REMOTE_SSH_HOST_VAR_NAME}"

# Remote SSH port
REMOTE_SSH_PORT_VAR_NAME="${REMOTE_SERVER}_SSH_PORT"
if [ -z "${!REMOTE_SSH_PORT_VAR_NAME}" ]; then
  echo "Error: ${REMOTE_SSH_PORT_VAR_NAME} is not set. Please check your remote server name and settings."
  exit 1;
fi
REMOTE_SSH_PORT_VALUE="${!REMOTE_SSH_PORT_VAR_NAME}"

# Remote SSH user
REMOTE_SSH_USER_VAR_NAME="${REMOTE_SERVER}_SSH_USER"
if [ -z "${!REMOTE_SSH_USER_VAR_NAME}" ]; then
  echo "Error: ${REMOTE_SSH_USER_VAR_NAME} is not set. Please check your remote server name and settings."
  exit 1;
fi
REMOTE_SSH_USER_VALUE="${!REMOTE_SSH_USER_VAR_NAME}"

# Remote SSH key file
REMOTE_SSH_KEY_FILE_VAR_NAME="${REMOTE_SERVER}_SSH_KEY_FILE"
if [ -z "${!REMOTE_SSH_KEY_FILE_VAR_NAME}" ]; then
  echo "Error: ${REMOTE_SSH_KEY_FILE_VAR_NAME} is not set. This means the SSH key file was not generated or the variable is missing. Please check your environment setup."
  exit 1;
fi
REMOTE_SSH_KEY_FILE_VALUE="${!REMOTE_SSH_KEY_FILE_VAR_NAME}"

# Also check if the key file actually exists on the local machine
if [ ! -f "$REMOTE_SSH_KEY_FILE_VALUE" ]; then
  echo "Error: SSH Key file '$REMOTE_SSH_KEY_FILE_VALUE' not found locally. Ensure it was generated correctly and has read permissions."
  exit 1;
fi
# Check key file permissions
if [ "$(stat -c "%a" "$REMOTE_SSH_KEY_FILE_VALUE")" -ne 600 ]; then
    echo "Warning: SSH key file '$REMOTE_SSH_KEY_FILE_VALUE' has incorrect permissions. Setting to 600."
    chmod 600 "$REMOTE_SSH_KEY_FILE_VALUE" || { echo "Error: Failed to set permissions on SSH key file. Exiting."; exit 1; }
fi

echo "Remote server environment variables appear to be set correctly."