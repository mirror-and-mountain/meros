#!/bin/bash
set -e
trap 'echo "Error on line $LINENO on host: $(hostname)"; exit 1' ERR

# --- Configuration ---
ENV_FILE="$HOME/config/.env"
# --- End Configuration ---

# -- Load and Check Environment Variables ---
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "Error: $HOME/config/.env couldn't be found. Check your .devcontainer directory and ensure one exists before building. Aborting..."
  exit 1
fi

if [ -z "$WP_DB_NAME" ] || [ -z "$WP_DB_USER" ] || [ -z "$WP_DB_PASSWORD" ] || [ -z "$WP_DB_HOST" ] || [ -z "$WP_DB_PREFIX" ]; then
  echo "Error: Required WordPress database environment variables are not set."
  exit 1
fi

if [ -z "$WP_THEME_NAME" ] || [ -z "$WP_TITLE" ] || [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || [ -z "$WP_ADMIN_EMAIL" ]; then
  echo "Error: Required WordPress environment variables are not set."
  exit 1
fi
# -- End Environment Variable Check ---

# -- Navigate to WordPress Directory ---
cd /var/www/html

# -- Wait for MySQL to be ready ---
echo "Installing WordPress..."
echo "Waiting for MySQL to be ready..."

attempts=0
until mysqladmin ping -h"$WP_DB_HOST" -u"$WP_DB_USER" -p"$WP_DB_PASSWORD" --silent; do
  attempts=$((attempts+1))
  if [ "$attempts" -gt 20 ]; then
    echo "MySQL did not become available after multiple attempts"
    exit 1
  fi
  echo "MySQL is unavailable - sleeping"
  sleep 2
done

echo "MySQL is ready."
# -- End Wait for MySQL ---

#-- Install WordPress --
if [ ! -f wp-config.php ]; then
  echo "WordPress not found, downloading and configuring..."

  # Create wp-config.php
  wp config create \
    --dbname="$WP_DB_NAME" \
    --dbuser="$WP_DB_USER" \
    --dbpass="$WP_DB_PASSWORD" \
    --dbhost="$WP_DB_HOST" \
    --dbprefix="$WP_DB_PREFIX" \

  # Detect if running inside GitHub Codespaces
  if [ -n "$CODESPACE_NAME" ]; then
    export WP_URL="https://${CODESPACE_NAME}-80.app.github.dev"
    echo "Detected Codespace. Using WP_URL: $WP_URL"

    # Add Codespaces HTTPS/proxy fix (should be before ABSPATH definition)
    sed -i '/\/\*\* Sets up WordPress vars and included files\. \*\//i \
if (isset($_SERVER["HTTP_X_FORWARDED_HOST"]) && isset($_SERVER["HTTP_X_FORWARDED_PROTO"])) {\n\
    $_SERVER["HTTP_HOST"] = $_SERVER["HTTP_X_FORWARDED_HOST"];\n\
    $_SERVER["HTTPS"] = $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https" ? "on" : "off";\n\
}\n' wp-config.php
  else
    export WP_URL="http://localhost:8000"
  fi

  echo "DEBUG: WP_URL is currently: $WP_URL"
  echo "Installing Wordpress..."

  # Install WordPress
  wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email

  echo "WordPress installed successfully."
  
  # Install theme dependencies
  if [ -d "wp-content/themes/$WP_THEME_NAME" ]; then
    echo "Installing theme dependencies..."
    cd "wp-content/themes/$WP_THEME_NAME"
    if [ -f "composer.json" ]; then
      composer install --no-dev --optimize-autoloader
    else
      echo "No composer.json found in theme directory, skipping composer install."
    fi
    cd /var/www/html
    echo "Activating theme: $WP_THEME_NAME..."
    wp theme activate "$WP_THEME_NAME"
  else
    echo "Theme directory $WP_THEME_NAME does not exist, skipping theme dependencies installation."
  fi
else
  echo "WordPress wp-config.php already exists, skipping installation."
fi

echo "WordPress setup complete."
# -- Install WordPress --
