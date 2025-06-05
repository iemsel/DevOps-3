#!/bin/bash

# Change to the application directory
cd /var/www/

# Run migrations (ensure database credentials are set in Render environment variables)
php artisan migrate --force

# Run seeds (CAUTION: only for dev/test or initial production data)
# php artisan db:seed --force

# Start the Apache web server in the foreground
apache2-foreground