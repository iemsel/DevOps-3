FROM php:8.3-apache

# Install system packages
RUN apt-get update && apt-get install -y \
    libzip-dev unzip git curl gnupg2 \
    && docker-php-ext-install pdo pdo_mysql zip \
    && apt-get clean

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js (18.x)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs
WORKDIR /var/www/

# Copy minimum files for composer install, including app/
COPY composer.json composer.lock ./
COPY artisan ./
COPY bootstrap/ ./bootstrap/
COPY config/ ./config/
COPY routes/ ./routes/
COPY app/ ./app/

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the project
COPY . .

# Build frontend assets
RUN npm ci && npm run build

# Configure Apache
COPY laravel.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Set correct permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose port
EXPOSE 80
