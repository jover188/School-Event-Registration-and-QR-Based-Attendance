#!/bin/sh
set -e

# Dynamically bind Apache to Render's $PORT if provided
if [ -n "$PORT" ]; then
    sed -i "s/Listen 80/Listen $PORT/" /etc/apache2/ports.conf
    sed -i "s/<VirtualHost \*:80>/<VirtualHost \*:$PORT>/" /etc/apache2/sites-available/000-default.conf
fi

# Ensure storage directories exist with proper permissions
mkdir -p storage/framework/cache/data \
         storage/framework/sessions \
         storage/framework/views \
         storage/logs \
         bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Ensure Render secret files are accessible to Apache www-data
if [ -d /etc/secrets ]; then
    chmod -R 755 /etc/secrets 2>/dev/null || true
fi

# Cache Laravel configuration, routes, and views in production
if [ "$APP_ENV" = "production" ] || [ "$APP_ENV" = "staging" ]; then
    echo "Caching Laravel configuration, routes, and views..."
    php artisan config:cache || true
    php artisan route:cache || true
    php artisan view:cache || true
fi

# Run database migrations if requested
if [ "$RUN_MIGRATIONS" = "true" ] || [ "$RUN_MIGRATIONS" = "1" ]; then
    echo "Running database migrations..."
    php artisan migrate --force || echo "Warning: Migration failed or database not reachable yet."
fi

# Run database seeder if requested
if [ "$RUN_SEEDER" = "true" ] || [ "$RUN_SEEDER" = "1" ]; then
    echo "Seeding database..."
    php artisan db:seed --force || echo "Warning: Seeder failed or already seeded."
fi

echo "Starting Apache web server..."
exec apache2-foreground
