FROM php:8.2-apache

ARG WP_THEME_NAME

# Install system dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    less \
    mariadb-client \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    libzip-dev \
    npm \
    nodejs \
    jq \
    sudo \
    gnupg \
    ca-certificates \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Install Github-CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
 && apt-get update && apt-get install -y gh \
 && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install mysqli pdo pdo_mysql zip

# Enable Apache mod_rewrite and FollowSymLinks
RUN a2enmod rewrite \
 && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
 && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/apache2/apache2.conf

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/local/bin/wp

# Add load-environment script to path
COPY /scripts/load-environment.sh /usr/local/bin/load-environment.sh
RUN chmod +x /usr/local/bin/load-environment.sh

# Add setup-wp script to path
COPY /scripts/setup-wp.sh /usr/local/bin/setup-wp.sh
RUN chmod +x /usr/local/bin/setup-wp.sh

# Add test-remote script to path
COPY /scripts/test-remote.sh /usr/local/bin/test-remote.sh
RUN chmod +x /usr/local/bin/test-remote.sh

# Add check-remote-vars script to path
COPY /scripts/check-remote-vars.sh /usr/local/bin/check-remote-vars.sh
RUN chmod +x /usr/local/bin/check-remote-vars.sh

# Add sync-from-remote script to path
COPY /scripts/sync-from-remote.sh /usr/local/bin/sync-from-remote.sh
RUN chmod +x /usr/local/bin/sync-from-remote.sh

# Add sync-to-remote script to path
COPY /scripts/sync-to-remote.sh /usr/local/bin/sync-to-remote.sh
RUN chmod +x /usr/local/bin/sync-to-remote.sh

# Create a home directory for www-data
RUN mkdir -p /home/www-data \
    && chown www-data:www-data /home/www-data \
    && chmod 755 /home/www-data

# Modify the www-data user entry to point its HOME to /home/www-data
RUN usermod -d /home/www-data www-data
RUN usermod -d /home/www-data -s /bin/bash www-data

# Add enviromment json
COPY /config/environment.json /home/www-data/config/environment.json

# Ensure the config directory exists and has the right permissions
RUN chown -R www-data:www-data /home/www-data/config \
    && chmod 755 /home/www-data/config

# Increase PHP upload limit
RUN echo "upload_max_filesize=256M\npost_max_size=256M" > /usr/local/etc/php/conf.d/uploads.ini

# Set Apache document root to WordPress installation path
WORKDIR /var/www/html

# Increase PHP memory limit and download wordpress core
RUN php -d memory_limit=512M /usr/local/bin/wp core download --allow-root

# Ensure key directories exist in the image for mounting
RUN mkdir -p /var/www/html/wp-content/themes/
RUN mkdir -p /var/www/html/wp-content/plugins/
RUN mkdir -p /var/www/html/wp-content/uploads/

# Ensure /var/www/html ownership for web server operations
RUN chown -R www-data:www-data /var/www/html
RUN find /var/www/html -type d -exec chmod 775 {} +
RUN find /var/www/html -type f -exec chmod 664 {} +

# Set the default user to www-data
USER www-data

# Set the theme working directory
WORKDIR /var/www/html/wp-content/themes/${WP_THEME_NAME}
