#!/bin/bash

# Make sure the script exits if any command fails
set -e

echo "Making migrations for all apps..."
python3 manage.py makemigrations

echo "Running database migrations..."
python3 manage.py migrate

echo "Generating hashed passwords for user fixtures..."
python3 generate_password_hashes.py

echo "Loading user data with hashed passwords..."
python3 manage.py loaddata apps/users/fixtures/initial_users_hashed.json

echo "Loading product categories and products..."
python3 manage.py loaddata apps/products/fixtures/initial_products.json

echo "Loading cart data..."
python3 manage.py loaddata apps/cart/fixtures/initial_carts.json

echo "Loading order data..."
python3 manage.py loaddata apps/orders/fixtures/initial_orders.json

echo "Loading inventory logs..."
python3 manage.py loaddata apps/inventory/fixtures/initial_inventory.json

echo "Loading analytics data..."
python3 manage.py loaddata apps/analytics/fixtures/initial_analytics.json

echo "All seed data loaded successfully!"
echo "You can now login with the credentials listed above." 