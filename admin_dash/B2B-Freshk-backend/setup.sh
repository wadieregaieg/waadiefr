#!/bin/bash

# Create a virtual environment if it doesn't exist
if [ ! -d "env" ]; then
    echo "Creating virtual environment..."
    python3 -m venv env
    echo "Virtual environment created!"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source env/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Check if .env file exists, create if not
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << EOL
DEBUG=True
SECRET_KEY=django-insecure-$^(xc7&5qd3$6(8)$@)((6@^$s%9mfff67@x#7bf@%xc7&5qd3$6
ALLOWED_HOSTS=localhost,127.0.0.1

# Database - using SQLite by default for quick setup
# DATABASE_URL=postgres://user:password@localhost:5432/freshk

# CORS settings
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000

# Twilio (for SMS) - Add your credentials if needed
# TWILIO_ACCOUNT_SID=
# TWILIO_AUTH_TOKEN=
# TWILIO_PHONE_NUMBER=
EOL
    echo ".env file created!"
fi

# Run migrations and load seed data
echo "Running migrations..."
python3 manage.py migrate

echo "Loading seed data..."
chmod +x load_seed_data.sh
./load_seed_data.sh

# Run the server
echo "Starting development server..."
python3 manage.py runserver

# Deactivate virtual environment on exit
deactivate 