FROM php:8.2-apache

# Install PHP extensions and system dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev unzip git curl gnupg2 ca-certificates \
    && docker-php-ext-install pdo pdo_mysql zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- \
    && mv composer.phar /usr/local/bin/composer

# Install Node.js 18 and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update && apt-get install -y nodejs

# Set working directory
WORKDIR /var/www/

# Copy only Composer files first (for better Docker caching)
COPY composer.json composer.lock ./

# Install PHP dependencies without dev packages
RUN composer install --no-dev --optimize-autoloader

# Copy rest of the application (includes artisan)
COPY . .

# Install Node packages and build assets
RUN npm ci && npm run build

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Copy custom Apache config
COPY laravel.conf /etc/apache2/sites-available/000-default.conf

# Set correct permissions for Laravel
RUN chown -R www-data:www-data storage bootstrap/cache

# Expose web server port
EXPOSE 80
