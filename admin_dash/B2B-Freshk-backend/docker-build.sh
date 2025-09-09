 #!/bin/bash

# Stop and remove existing containers
docker-compose down

# Build and start containers
docker-compose up --build -d

# Show logs
echo "Services are starting up. To view logs, run: docker-compose logs -f"
echo "API will be available at: http://localhost:8000/api/"
echo "Swagger documentation at: http://localhost:8000/api/docs/"
echo "pgAdmin interface at: http://localhost:5050/"
echo ""
echo "pgAdmin login: admin@freshk.com / pgadmin"
echo "Test users:"
echo "- Admin: admin1/admin1"
echo "- Retailer: retailer1/retailer1"
echo "- Supplier: supplier1/supplier1"