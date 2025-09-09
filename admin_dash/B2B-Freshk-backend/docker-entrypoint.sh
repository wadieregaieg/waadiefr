#!/bin/bash

set -e

# Wait for the database to be ready (for Render deployment)
if [ -n "$DATABASE_URL" ]; then
  echo "Using DATABASE_URL for database connection..."
  # Extract database host from DATABASE_URL for connection testing
  DB_HOST=$(python -c "
import os
from urllib.parse import urlparse
url = urlparse(os.environ.get('DATABASE_URL', ''))
print(url.hostname or 'localhost')
")
  DB_PORT=$(python -c "
import os
from urllib.parse import urlparse
url = urlparse(os.environ.get('DATABASE_URL', ''))
print(url.port or 5432)
")
  
  echo "Waiting for PostgreSQL at $DB_HOST:$DB_PORT..."
  while ! nc -z "$DB_HOST" "$DB_PORT"; do
    sleep 1
  done
  echo "PostgreSQL started"
else
  echo "Waiting for PostgreSQL..."
  while ! nc -z db 5432; do
    sleep 0.1
  done
  echo "PostgreSQL started"
fi

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Load initial data if the database is empty
USERS_COUNT=$(python manage.py shell -c "from apps.users.models import CustomUser; print(CustomUser.objects.count())")
if [ "$USERS_COUNT" -eq "0" ]; then
  echo "Loading initial data..."
  if [ -f generate_password_hashes.py ]; then
    python generate_password_hashes.py
  fi
  
  # Load fixtures
  python manage.py loaddata apps/users/fixtures/initial_users_hashed.json
  python manage.py loaddata apps/products/fixtures/initial_products.json
  python manage.py loaddata apps/cart/fixtures/initial_carts.json
  python manage.py loaddata apps/orders/fixtures/initial_orders.json
  python manage.py loaddata apps/inventory/fixtures/initial_inventory.json
  python manage.py loaddata apps/analytics/fixtures/initial_analytics.json
  
  echo "Initial data loaded successfully"
fi

# Start the application
exec "$@" 