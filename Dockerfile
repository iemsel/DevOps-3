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
COPY database/ ./database/ # <-- IMPORTANT: Copy database folder for migrations/seeds

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the project
COPY . .

# Build frontend assets
RUN npm ci && npm run build

# --- NEW ADDITIONS FOR MIGRATIONS AND SEEDS ---
# Ensure storage permissions are set before migrations
# This might already be handled by your chown later, but good to ensure here if needed
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Run database migrations
# Use --force for non-interactive execution
RUN php artisan migrate --force

# Run database seeders (CAUTION: Only for development/testing or initial data)
# If you only want specific seeders, you can specify them:
# RUN php artisan db:seed --class=UserSeeder --force
RUN php artisan db:seed --force
# --- END NEW ADDITIONS ---

# Configure Apache
COPY laravel.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Set correct permissions (already done above for migrations, but good to keep if you have other permission needs)
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose port
EXPOSE 80

# Define the command to run when the container starts
# This will now just start Apache, as migrations/seeds are done during build
CMD ["apache2-foreground"]