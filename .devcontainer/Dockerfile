FROM docker.io/php:8.4-apache

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
    jq \
    sudo \
    gnupg \
    ca-certificates \
    rsync \
    libmagickwand-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install mysqli pdo pdo_mysql zip

# Change Apache to listen on port 8080 (Crucial for non-root)
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
 && sed -i 's/:80/:8080/g' /etc/apache2/sites-enabled/000-default.conf

# Enable Apache mod_rewrite and FollowSymLinks
RUN a2enmod rewrite \
 && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
 && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/apache2/apache2.conf

# Install Github-CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
 && apt-get update && apt-get install -y gh \
 && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/local/bin/wp

# --- USER CONFIGURATION START ---
# Define default UID/GID 
# Used for Podman setups to ensure www-data matches host user permissions. Not needed for Docker Desktop.
ARG USER_UID=1000
ARG USER_GID=1000

# Modify the EXISTING www-data user to match the ARG UID/GID
# This is cleaner than creating a new user and avoids conflicts with the base image
RUN usermod -u ${USER_UID} www-data \
 && groupmod -g ${USER_GID} www-data \
 && mkdir -p /home/www-data \
 && chown www-data:www-data /home/www-data \
 && chmod 755 /home/www-data \
 && usermod -d /home/www-data -s /bin/bash www-data

# Create home subdirectories
RUN mkdir -p /home/www-data/bin \
 && mkdir -p /home/www-data/keys \
 && mkdir -p /home/www-data/.wp-cli \
 && chown -R www-data:www-data /home/www-data \
 && chmod -R 755 /home/www-data

# Copy MySQL SSL Conf & WP CLI config.yml
COPY /config/wpcli.config.yml /home/www-data/.wp-cli/config.yml
COPY /config/mariadb.my.cnf /home/www-data/.my.cnf

# Set .my.cnf file permissions
RUN chown www-data:www-data /home/www-data/.my.cnf \
 && chmod 600 /home/www-data/.my.cnf

# Allow www-data to use sudo (Needed for WP-CLI scripts)
RUN echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Increase PHP upload limit
RUN echo "upload_max_filesize=256M\npost_max_size=256M" > /usr/local/etc/php/conf.d/uploads.ini

# Set Apache document root to WordPress installation path
WORKDIR /var/www/html

# Increase PHP memory limit and download wordpress core
RUN php -d memory_limit=512M /usr/local/bin/wp core download --allow-root

# Ensure WordPress directories exist in the image for mounting
RUN mkdir -p /var/www/html/wp-content/themes/ \
 && mkdir -p /var/www/html/wp-content/plugins/ \
 && mkdir -p /var/www/html/wp-content/uploads/

# Ensure /var/www/html ownership and permissions
# 777 on mounted dirs ensures write access regardless of UID timing
RUN chmod -R 777 /var/www/html/wp-content/themes/ \
 && chmod -R 777 /var/www/html/wp-content/plugins/ \
 && chmod -R 777 /var/www/html/wp-content/uploads/ \
 && chown -R www-data:www-data /var/www/html

#Set the meros environment variable
ENV MEROS_ENVIRONMENT=true

# Set the default user to www-data
USER www-data