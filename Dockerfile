FROM php:apache

RUN apt-get update && apt-get install -y libzip-dev unzip git curl && \
    docker-php-ext-install pdo pdo_mysql zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

WORKDIR /var/www/

# Copy all application files 
COPY . .

# Install PHP dependencies with composer
RUN composer install --no-dev --optimize-autoloader

# Install Node packages and run build
RUN npm install && npm run build

# Optionally install vite as dev dependency
RUN npm install --save-dev vite

# Copy Apache config
COPY laravel.conf /etc/apache2/sites-available/000-default.conf

# Enable mod_rewrite
RUN a2enmod rewrite

# Fix permissions for Laravel folders
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 80
