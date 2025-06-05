FROM php:8.3-apache

# Install system packages
RUN apt-get update && apt-get install -y \
    libzip-dev unzip git curl gnupg2 \
    libpq-dev \
    && docker-php-ext-install pdo zip pdo_pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

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
# IMPORTANT: Copy database folder for migrations/seeds (comment moved to its own line)
COPY database/ ./database/

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the project
COPY . .

# Build frontend assets
RUN npm ci && npm run build

# --- ADDITIONS FOR MIGRATIONS AND SEEDS DURING BUILD ---
# Ensure storage permissions are set before migrations
# Laravel needs to write to these directories for cache and sessions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Run database migrations
# Use --force for non-interactive execution during Docker build
RUN php artisan migrate --force

# Run database seeders (CAUTION: Only for development/testing or initial production data)
# This will run your DatabaseSeeder.php
# If you only want specific seeders, uncomment and modify the line below:
# RUN php artisan db:seed --class=UserSeeder --force
RUN php artisan db:seed --force
# --- END ADDITIONS ---

# Configure Apache
COPY laravel.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Set correct permissions (redundant if done above, but harmless to keep if other parts rely on it)
# The chown above specifically targets storage and cache before migrations.
# This one might be for other parts of /var/www if needed.
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose port
EXPOSE 80

# Clear Laravel's configuration cache to ensure it picks up fresh env vars
RUN php artisan config:clear
RUN php artisan cache:clear # Also good to clear general cache

CMD ["apache2-foreground"]