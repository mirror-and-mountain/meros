#!/bin/bash
set -e
trap 'echo "Error on line $LINENO on host: $(hostname)"; exit 1' ERR

# --- Get Parameters from Command Line ---
# Argument 1: REMOTE_SERVER name (e.g., "production", "staging")

if [ -z "$1" ]; then
  echo "Usage: composer run sync:to-remote -- <REMOTE_SERVER> [run_tests_flag]"
  echo "Example: composer run sync:to-remote -- production"
  exit 1
fi

# --- Configuration ---
ENV_FILE="$HOME/config/.env"
VAR_SCRIPT="check-remote-vars.sh" 

REMOTE_SERVER_INPUT="$1"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE..."
  source "$ENV_FILE"
else
  echo "Error: $HOME/config/.env couldn't be found. Check your .devcontainer directory and ensure one exists before building. Aborting..."
  exit 1
fi

# Convert user input to uppercase
REMOTE_SERVER="${REMOTE_SERVER_INPUT^^}"
# --- End Configuration ---

# --- Run VAR Check Tests ---
echo "--- Checking remote server variables for ${REMOTE_SERVER_INPUT} ---"
  # Execute the test script as a child process.
  source "$VAR_SCRIPT" "${REMOTE_SERVER}" || {
    echo "Error: Remote server variable check failed for ${REMOTE_SERVER_INPUT}. Aborting sync."
    exit 1
  }
echo "--- Remote server variable check passed for ${REMOTE_SERVER_INPUT} ---"

# --- Test SSH Connection & Dependancies ---
echo "Testing SSH connection to $REMOTE_SERVER using ${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}:${REMOTE_SSH_PORT_VALUE}..."

# Connect to remote server and run checks
ssh -i "${REMOTE_SSH_KEY_FILE_VALUE}" \
    -o StrictHostKeyChecking=no \
    -p "${REMOTE_SSH_PORT_VALUE}" \
    "${REMOTE_SSH_USER_VALUE}@${REMOTE_SSH_HOST_VALUE}" bash <<EOF
    # Commands to run on the remote server
    echo "SSH connection to ${REMOTE_SERVER_INPUT} successful."

    echo "Checking wp-cli installation..."
    if ! command -v wp >/dev/null 2>&1; then
        echo "Error: wp-cli is not installed on the remote server."
        exit 1 # Exit the remote shell
    fi
    echo "wp-cli is installed."

    echo "Checking rsync installation..."
    if ! command -v rsync >/dev/null 2>&1; then
        echo "Error: rsync is not installed on the remote server."
        exit 1 # Exit the remote shell
    fi
    echo "rsync is installed."
  
    echo "Checking if WordPress is installed at ${REMOTE_PATH_VALUE}..."
    if wp core is-installed --path="${REMOTE_PATH_VALUE}"; then
        echo "WordPress is installed at ${REMOTE_URL_VALUE}."
    else
        echo "WordPress is NOT installed at ${REMOTE_URL_VALUE}. Please check your installation path or WP installation."
        exit 1 # Exit the remote shell
    fi
    echo "All remote checks passed for ${REMOTE_SERVER_INPUT}."
EOF

echo "All local and remote checks for ${REMOTE_SERVER_INPUT} completed successfully."
# --- End Test SSH Connection & Dependencies ---