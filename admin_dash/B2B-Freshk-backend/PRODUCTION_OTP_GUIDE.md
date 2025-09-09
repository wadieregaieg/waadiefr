# Production OTP Authentication Guide

## Overview

The FreshK mobile app now has **production-ready OTP authentication endpoints** that are completely isolated from testing endpoints. These endpoints include proper security measures, rate limiting, and Twilio SMS integration.

## Endpoint Structure

### Testing Endpoints (Development Only)
- `POST /api/mobile/auth/request/` - Test OTP request (logs to console)
- `POST /api/mobile/auth/verify/` - Test OTP verification

### Production Endpoints (Live Use)
- `POST /api/mobile/auth/production/request/` - Production OTP request (sends real SMS)
- `POST /api/mobile/auth/production/verify/` - Production OTP verification
- `POST /api/mobile/auth/production/resend/` - Resend OTP for authenticated users
- `GET /api/mobile/auth/production/status/` - Check authentication status

## Production Features

### 🔒 Security Features
- **Rate Limiting**: 5 OTP requests per hour per IP address
- **User Rate Limiting**: 3 OTP requests per hour per user
- **Phone Number Validation**: International format validation
- **Transaction Safety**: Database rollback on SMS failures
- **Security Logging**: Comprehensive audit trail
- **OTP Expiry**: 10-minute expiration time

### 📱 SMS Integration
- **Twilio Integration**: Real SMS delivery via Twilio
- **Fallback Handling**: Graceful error handling if SMS fails
- **Message Template**: Professional SMS message format
- **Delivery Confirmation**: SMS delivery status tracking

### 🛡️ Error Handling
- **Graceful Failures**: User-friendly error messages
- **Security**: No information leakage about user existence
- **Logging**: Detailed error logging for debugging
- **Rollback**: Automatic cleanup on failures

## Setup Instructions

### 1. Install Dependencies
```bash
pip install twilio
```

### 2. Environment Configuration

Create a production environment file (`.env.production`) or update your existing `.env`:

```env
# Twilio Configuration (REQUIRED for production)
TWILIO_ENABLED=True
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number

# Security Settings
DEBUG=False
SECRET_KEY=your-production-secret-key
ALLOWED_HOSTS=your-domain.com,api.your-domain.com

# Database (PostgreSQL recommended)
DATABASE_URL=postgres://user:password@localhost:5432/freshk_production
```

### 3. Twilio Setup

1. **Create Twilio Account**: Sign up at [twilio.com](https://www.twilio.com)
2. **Get Phone Number**: Purchase a phone number for SMS
3. **Get Credentials**: Copy Account SID and Auth Token
4. **Configure Environment**: Add credentials to your `.env` file

### 4. Test Production Endpoints

```bash
# Test OTP request
curl -X POST http://localhost:8000/api/mobile/auth/production/request/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+1234567890"}'

# Test OTP verification
curl -X POST http://localhost:8000/api/mobile/auth/production/verify/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+1234567890", "otp": "123456"}'
```

## API Documentation

### Request OTP

**Endpoint**: `POST /api/mobile/auth/production/request/`

**Request Body**:
```json
{
  "phone_number": "+1234567890"
}
```

**Response (Success)**:
```json
{
  "message": "Verification code sent successfully",
  "is_new_user": false,
  "expires_in": 600
}
```

**Response (Error)**:
```json
{
  "error": "Invalid phone number format. Please use international format (+1234567890)"
}
```

### Verify OTP

**Endpoint**: `POST /api/mobile/auth/production/verify/`

**Request Body**:
```json
{
  "phone_number": "+1234567890",
  "otp": "123456"
}
```

**Response (Success)**:
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "username": "user_1234567890",
    "phone_number": "+1234567890",
    "role": "retailer",
    "phone_verified": true
  },
  "message": "Authentication successful"
}
```

### Resend OTP

**Endpoint**: `POST /api/mobile/auth/production/resend/`
**Authentication**: Required (Bearer token)

**Response**:
```json
{
  "message": "Verification code sent successfully",
  "expires_in": 600
}
```

### Check Auth Status

**Endpoint**: `GET /api/mobile/auth/production/status/`
**Authentication**: Required (Bearer token)

**Response**:
```json
{
  "authenticated": true,
  "user": {
    "id": 1,
    "username": "user_1234567890",
    "phone_number": "+1234567890",
    "role": "retailer"
  },
  "phone_verified": true,
  "account_active": true
}
```

## Rate Limiting

### IP-Based Rate Limiting
- **Limit**: 5 requests per hour per IP address
- **Scope**: All production OTP endpoints
- **Response**: HTTP 429 Too Many Requests

### User-Based Rate Limiting
- **Limit**: 3 requests per hour per user
- **Scope**: Per user account
- **Storage**: Django cache (Redis recommended)

## Error Codes

| HTTP Code | Error | Description |
|-----------|-------|-------------|
| 400 | Invalid phone number format | Phone number doesn't match international format |
| 400 | Invalid or expired OTP | OTP is incorrect or has expired |
| 404 | No user found | Phone number not registered |
| 429 | Too many requests | Rate limit exceeded |
| 500 | SMS delivery failed | Twilio SMS sending failed |

## Security Considerations

### Phone Number Validation
- Must start with `+` followed by country code
- Must be 10-15 digits total
- No spaces or special characters allowed

### OTP Security
- 6-digit numeric codes
- 10-minute expiration
- Single-use (cleared after verification)
- Cryptographically secure generation

### Logging
- All authentication attempts logged
- Failed attempts tracked
- Rate limit violations logged
- SMS delivery status logged

## Monitoring

### Key Metrics to Monitor
- OTP request rate
- SMS delivery success rate
- Authentication success rate
- Rate limit violations
- Failed authentication attempts

### Log Files
- Application logs: `logs/debug.log`
- Django logs: Console output
- Twilio logs: Twilio dashboard

## Deployment Checklist

- [ ] Twilio account created and configured
- [ ] Environment variables set correctly
- [ ] Rate limiting configured
- [ ] Logging configured
- [ ] SSL/HTTPS enabled
- [ ] Database backups configured
- [ ] Monitoring alerts set up
- [ ] Error tracking configured

## Troubleshooting

### Common Issues

1. **SMS Not Sending**
   - Check Twilio credentials
   - Verify phone number format
   - Check Twilio account balance
   - Review Twilio logs

2. **Rate Limiting Issues**
   - Check cache configuration
   - Verify Redis connection
   - Review rate limit settings

3. **Authentication Failures**
   - Check OTP expiration
   - Verify phone number format
   - Review user account status

### Debug Mode

To enable debug logging for production endpoints:

```python
# In settings.py
LOGGING = {
    'loggers': {
        'apps.mobile.production_views': {
            'level': 'DEBUG',
            'handlers': ['console', 'file'],
        }
    }
}
```

## Migration from Testing to Production

1. **Update Mobile App**: Change endpoint URLs from `/auth/` to `/auth/production/`
2. **Configure Twilio**: Set up Twilio account and credentials
3. **Test Thoroughly**: Test all endpoints in staging environment
4. **Monitor**: Set up monitoring and alerts
5. **Deploy**: Deploy to production with proper environment variables

## Support

For issues with the production OTP system:
1. Check the logs first
2. Verify Twilio configuration
3. Test with curl commands
4. Review rate limiting status
5. Check database connectivity 