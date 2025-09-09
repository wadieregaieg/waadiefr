#!/usr/bin/env python
"""
This script generates password hashes for user fixtures.
Run this from your project root directory.
"""

import os
import json
import django
from django.contrib.auth.hashers import make_password
from django.utils import timezone

# Setup Django environment
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "freshk.settings")
django.setup()

# Path to your users fixture file
FIXTURE_PATH = 'apps/users/fixtures/initial_users.json'
OUTPUT_PATH = 'apps/users/fixtures/initial_users_hashed.json'

def hash_passwords_in_fixture():
    """Read the fixture file, hash the passwords, and save to a new file"""
    try:
        with open(FIXTURE_PATH, 'r') as f:
            fixtures = json.load(f)
        
        # Get current timestamp for date_joined and last_activity
        current_time = timezone.now().isoformat()
        
        # Process each user fixture
        for fixture in fixtures:
            if fixture['model'] == 'users.customuser':
                # Get the plain text password
                plain_password = fixture['fields']['password']
                
                # Create a proper hash
                hashed_password = make_password(plain_password)
                
                # Update the fixture
                fixture['fields']['password'] = hashed_password
                
                # Add required datetime fields
                fixture['fields']['date_joined'] = current_time
                fixture['fields']['last_activity'] = current_time
                
                # Add is_active field if it doesn't exist
                if 'is_active' not in fixture['fields']:
                    fixture['fields']['is_active'] = True
                
                # Add admin privileges for admin users
                if fixture['fields']['role'] == 'admin':
                    fixture['fields']['is_staff'] = True
                    fixture['fields']['is_superuser'] = True
        
        # Save the updated fixtures
        with open(OUTPUT_PATH, 'w') as f:
            json.dump(fixtures, f, indent=2)
        
        print(f"Successfully created hashed password fixture file at {OUTPUT_PATH}")
        print("\nUser credentials for login:")
        
        # Print the list of usernames and passwords
        for fixture in fixtures:
            if fixture['model'] == 'users.customuser':
                username = fixture['fields']['username']
                password = fixture['fields'].get('_password_plain', username)  # Default to username if not stored
                role = fixture['fields']['role']
                print(f"Username: {username}, Password: {password}, Role: {role}")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    hash_passwords_in_fixture() 