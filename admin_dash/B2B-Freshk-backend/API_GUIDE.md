# FreshK API Guide for Frontend Developers

This guide provides essential information for frontend developers working with the FreshK API.

## Getting Started

### API Base URL

- **Development**: `http://localhost:8000/api/`
- **Production**: `https://api.freshk.com/api/` (Replace with your actual production URL)

### Authentication

The API uses JWT (JSON Web Token) for authentication:

1. **Obtain Access and Refresh Tokens**:
   ```
   POST /api/token/
   ```
   Request Body:
   ```json
   {
     "username": "user@example.com",
     "password": "password"
   }
   ```

2. **Refresh Token**:
   ```
   POST /api/token/refresh/
   ```
   Request Body:
   ```json
   {
     "refresh": "your_refresh_token"
   }
   ```

3. **Including the Token in Requests**:
   Add the following header to authenticated requests:
   ```
   Authorization: Bearer your_access_token
   ```

### Mobile-Specific Authentication

For mobile applications, phone-based authentication is available:

1. **Request OTP**:
   ```
   POST /api/mobile/auth/request/
   ```
   Request Body:
   ```json
   {
     "phone_number": "+1234567890"
   }
   ```

2. **Verify OTP and Get Token**:
   ```
   POST /api/mobile/auth/verify/
   ```
   Request Body:
   ```json
   {
     "phone_number": "+1234567890",
     "otp": "123456"
   }
   ```

## API Documentation

Interactive API documentation is available at:
- Swagger UI: `/api/docs/`
- ReDoc: `/api/redoc/`

## Endpoint Structure

The API is organized into the following sections:

### General Endpoints

These endpoints are available for both web and mobile applications:

- **Users**: `/api/users/`
- **Products**: `/api/products/`
- **Orders**: `/api/orders/`
- **Cart**: `/api/cart/`
- **Inventory**: `/api/inventory/`
- **Analytics**: `/api/analytics/`

### Mobile-Specific Endpoints

These endpoints are optimized for mobile applications:

- **Products**: `/api/mobile/products/`
- **Categories**: `/api/mobile/categories/`
- **Cart**: `/api/mobile/cart/`
- **Orders**: `/api/mobile/orders/`
- **Authentication**: 
  - `/api/mobile/auth/request/`
  - `/api/mobile/auth/verify/`

### Admin Dashboard Endpoints

These endpoints are specifically for the admin dashboard:

- **Users**: `/api/admin/users/`
- **Products**: `/api/admin/products/`
- **Orders**: `/api/admin/orders/`
- **Inventory**: `/api/admin/inventory/`
- **Analytics**: `/api/admin/analytics/`

## Key Concepts

### User Types

- **Admin**: Full access to all endpoints
- **Retailer**: Can browse products, manage their cart, place orders
- **Supplier**: Can manage their products and view orders for their products

### Media Files

Product images are stored at `/media/products/` and can be accessed directly via the URL.

## Examples

### Flutter Integration Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> login(String username, String password) async {
  final response = await http.post(
    Uri.parse('http://localhost:8000/api/token/'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'username': username,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['access'];
  } else {
    throw Exception('Failed to login');
  }
}

Future<List<dynamic>> getProducts(String token) async {
  final response = await http.get(
    Uri.parse('http://localhost:8000/api/mobile/products/'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['results'];
  } else {
    throw Exception('Failed to load products');
  }
}
```

### Admin Dashboard (React) Integration Example

```javascript
import axios from 'axios';

const API_URL = 'http://localhost:8000/api';

// Create axios instance with auth header
const api = axios.create({
  baseURL: API_URL,
});

// Add authorization header
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Authentication
export const login = async (username, password) => {
  const response = await axios.post(`${API_URL}/token/`, { username, password });
  return response.data;
};

// Admin API example
export const getUsers = async () => {
  const response = await api.get(`/admin/users/`);
  return response.data;
};

export const getSalesReport = async () => {
  const response = await api.get(`/admin/analytics/sales-reports/dashboard/`);
  return response.data;
};
```

## Testing Credentials

For testing purposes, the following users are available:

- **Admin**: admin1/admin1
- **Retailer**: retailer1/retailer1
- **Supplier**: supplier1/supplier1

## Common Issues and Solutions

### CORS Issues

If you encounter CORS issues, make sure your frontend application's domain is added to the `CORS_ALLOWED_ORIGINS` setting in the Django settings.

### JWT Token Expiration

Access tokens expire after 60 minutes. Implement token refresh logic in your frontend app to obtain a new access token using the refresh token.

### API Rate Limiting

The API may have rate limiting in production. Handle 429 Too Many Requests responses appropriately.

## Support

For any API-related issues, please contact the backend team at backend@freshk.com. 