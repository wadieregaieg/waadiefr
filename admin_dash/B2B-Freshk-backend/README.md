# FreshK B2B Platform

FreshK is a B2B platform connecting retailers with suppliers of fresh products. The platform enables retailers to browse and order products from suppliers, while giving suppliers tools to manage their inventory and fulfill orders.

## Project Structure

- **Users App**: Handles user authentication, authorization, and profiles (retailer/supplier)
- **Products App**: Manages product catalog, categories, and inventory
- **Orders App**: Handles order creation, processing, and fulfillment
- **Cart App**: Manages shopping cart functionality
- **Mobile App**: Provides optimized APIs for mobile clients
- **Analytics App**: Tracks and analyzes platform usage and sales data

## Tech Stack

- **Backend**: Django 5.1 with Django REST Framework
- **Database**: PostgreSQL (Neon cloud service)
- **Authentication**: JWT with SimpleJWT
- **Mobile Auth**: Phone-based OTP authentication
- **API Documentation**: Swagger/OpenAPI with drf-yasg

## Setup Instructions

### Option 1: Using Docker (Recommended)

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd freshk
   ```

2. Run the Docker setup script
   ```bash
   chmod +x docker-build.sh
   ./docker-build.sh
   ```

3. Access the services:
   - API: http://localhost:8000/api/
   - Swagger documentation: http://localhost:8000/api/docs/
   - pgAdmin: http://localhost:5050/ (login: admin@freshk.com / pgadmin)

4. To stop the services:
   ```bash
   docker-compose down
   ```

### Option 2: Manual Setup

### Prerequisites

- Python 3.10+
- PostgreSQL 14+

### Environment Setup

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd freshk
   ```

2. Create a virtual environment
   ```bash
   python -m venv env
   source env/bin/activate  # On Windows: env\Scripts\activate
   ```

3. Install dependencies
   ```bash
   pip install -r requirements.txt
   ```

4. Create a `.env` file in the project root with the following variables:
   ```
   DEBUG=True
   SECRET_KEY=<your-secret-key>
   ALLOWED_HOSTS=localhost,127.0.0.1
   
   # Database
   DATABASE_URL=<your-database-url>
   
   # Optional: Individual database settings (used if DATABASE_URL not provided)
   DB_NAME=freshk_db
   DB_USER=<db-username>
   DB_PASSWORD=<db-password>
   DB_HOST=localhost
   DB_PORT=5432
   
   # CORS settings
   CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000
   
   # Twilio (for SMS)
   TWILIO_ACCOUNT_SID=<your-twilio-sid>
   TWILIO_AUTH_TOKEN=<your-twilio-token>
   TWILIO_PHONE_NUMBER=<your-twilio-phone>
   ```

5. Run migrations and load seed data
   ```bash
   python manage.py migrate
   python generate_password_hashes.py
   python manage.py loaddata apps/users/fixtures/initial_users_hashed.json
   python manage.py loaddata apps/products/fixtures/initial_products.json
   python manage.py loaddata apps/cart/fixtures/initial_carts.json
   python manage.py loaddata apps/orders/fixtures/initial_orders.json
   python manage.py loaddata apps/inventory/fixtures/initial_inventory.json
   python manage.py loaddata apps/analytics/fixtures/initial_analytics.json
   ```
   Or use our all-in-one script:
   ```bash
   chmod +x load_seed_data.sh
   ./load_seed_data.sh
   ```

6. Run the development server
   ```bash
   python manage.py runserver
   ```

7. Access the API at `http://localhost:8000/api/`

## For Frontend Developers

### API Documentation

The API documentation is available at `/api/docs/` when the server is running.

### Authentication

- **Web/Admin**: Use JWT authentication via `/api/token/` endpoint
- **Mobile**: Use phone-based authentication via `/api/mobile/auth/request/` and `/api/mobile/auth/verify/`

### Test Credentials

For testing purposes, the following users are available:

- **Admin**: admin1/admin1
- **Retailer**: retailer1/retailer1
- **Supplier**: supplier1/supplier1

### API Guides

- See `API_GUIDE.md` for detailed information on how to integrate with the API
- Mobile developers: Focus on the `/api/mobile/` endpoints
- Admin dashboard developers: Focus on the `/api/admin/` endpoints

## Development Guidelines

1. Use the provided fixture data for testing
2. Follow the application structure and naming conventions
3. Add proper docstrings and comments to your code
4. Write tests for new functionality
5. Keep the API documentation up to date

## Project Status

See `PROJECT_STATUS.md` for current project status and upcoming tasks.

## Test Mode

### SMS Authentication

The project is currently configured in **test mode** for SMS authentication:

- Twilio integration is disabled
- OTP codes are logged to the console and to `logs/debug.log` instead of being sent via SMS
- This allows testing the authentication flow without requiring Twilio credentials

When you see a message like `TEST MODE: OTP for +1234567890: 123456` in the console, use that OTP code to complete the authentication flow.

### Enabling SMS in Production

To enable actual SMS functionality in production:

1. Uncomment the Twilio dependency in `requirements.txt`
2. Install the dependency: `pip install twilio`
3. Update `settings.py` to set `TWILIO_ENABLED = True`
4. Configure your Twilio credentials in `.env`
5. Modify `apps/users/utils.py` to use the actual Twilio client

## License

[License information] 