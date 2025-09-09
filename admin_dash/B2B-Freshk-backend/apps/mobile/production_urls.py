from django.urls import path
from .production_views import (
    production_phone_auth_request,
    production_phone_auth_verify,
    production_resend_otp,
    production_auth_status
)

# Production-ready mobile authentication URLs
# These endpoints are isolated from testing endpoints and include:
# - Rate limiting
# - Proper security measures
# - Twilio SMS integration
# - Comprehensive logging

urlpatterns = [
    # Production OTP Authentication Endpoints
    path('auth/production/request/', production_phone_auth_request, name='mobile-production-auth-request'),
    path('auth/production/verify/', production_phone_auth_verify, name='mobile-production-auth-verify'),
    path('auth/production/resend/', production_resend_otp, name='mobile-production-resend-otp'),
    path('auth/production/status/', production_auth_status, name='mobile-production-auth-status'),
] 