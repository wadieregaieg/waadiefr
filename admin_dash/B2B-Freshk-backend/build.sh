#!/usr/bin/env bash
# Exit on error
set -o errexit

# Make sure this script is executable (safety measure)
chmod +x "$0" 2>/dev/null || true

# Modify pip.conf to use a user-owned directory for cache
export PIP_CACHE_DIR=/tmp/pip-cache
mkdir -p $PIP_CACHE_DIR

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --no-input

# Run database migrations
echo "Running database migrations..."
python manage.py migrate

echo "Build completed successfully!" 