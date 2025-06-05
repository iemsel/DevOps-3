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

# Copy Composer files and artisan for initial Composer install
COPY composer.json composer.lock ./
COPY artisan ./
# Copy app, bootstrap, config, routes, database for dependencies and migrations
COPY app/ ./app/
COPY bootstrap/ ./bootstrap/
COPY config/ ./config/
COPY routes/ ./routes/
COPY database/ ./database/ # Ensure database folder is copied for migrations/seeds

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Copy the rest of the project files needed for asset building and runtime
COPY . .

# Build frontend assets with Vite
# This step is CRUCIAL for the Vite ManifestNotFoundException error
RUN npm ci && npm run build

# --- DATABASE MIGRATIONS AND SEEDS (DURING BUILD) ---
# Ensure storage permissions for database writes (migrations/seeds)
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Run database migrations
# This will create all your tables including 'sessions'
RUN php artisan migrate --force

# Run database seeders (CAUTION: Use with care in production environments)
RUN php artisan db:seed --force
# --- END DATABASE MIGRATIONS AND SEEDS ---

# Configure Apache
COPY laravel.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Final permissions for the web server to write to storage/cache
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Clear Laravel's configuration and application cache
# This ensures the running app loads fresh environment variables and config,
# and clears any cached views that might rely on old asset paths.
RUN php artisan config:clear
RUN php artisan cache:clear
RUN php artisan view:clear # Add view clear for compiled blade templates

# Expose port
EXPOSE 80

# Define the command to run when the container starts
# This will just start Apache, as everything else is done during build
CMD ["apache2-foreground"]