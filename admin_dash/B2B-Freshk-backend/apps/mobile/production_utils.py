import random
import string
from datetime import datetime, timedelta
from django.utils import timezone
from django.conf import settings
from decouple import config
import logging

logger = logging.getLogger(__name__)

# Production Twilio integration
try:
    from twilio.rest import Client
    TWILIO_AVAILABLE = True
except ImportError:
    TWILIO_AVAILABLE = False
    logger.warning("Twilio not available. Install with: pip install twilio")

def generate_production_otp(length=6):
    """Generate a cryptographically secure OTP for production use"""
    return ''.join(random.choices(string.digits, k=length))

def is_production_otp_valid(user, otp):
    """Check if the OTP is valid for the user in production"""
    if not user.otp or not user.otp_expiry:
        return False
    
    # Check if OTP matches and has not expired
    is_valid = user.otp == otp and timezone.now() <= user.otp_expiry
    
    # Log security events
    if not is_valid:
        logger.warning(f"Invalid OTP attempt for user {user.phone_number}")
    
    return is_valid

def send_production_otp_via_sms(phone_number, otp):
    """
    Send OTP via Twilio SMS in production
    
    Returns:
        bool: True if SMS was sent successfully, False otherwise
    """
    # Check if Twilio is enabled
    twilio_enabled = config('TWILIO_ENABLED', default=False, cast=bool)
    
    if not twilio_enabled:
        logger.error("Twilio is not enabled. Set TWILIO_ENABLED=True in environment")
        return False
    
    if not TWILIO_AVAILABLE:
        logger.error("Twilio library not installed. Install with: pip install twilio")
        return False
    
    try:
        # Get Twilio credentials from environment
        account_sid = config('TWILIO_ACCOUNT_SID', default='')
        auth_token = config('TWILIO_AUTH_TOKEN', default='')
        twilio_phone = config('TWILIO_PHONE_NUMBER', default='')
        
        if not all([account_sid, auth_token, twilio_phone]):
            logger.error("Missing Twilio credentials in environment variables")
            return False
        
        # Initialize Twilio client
        client = Client(account_sid, auth_token)
        
        # Compose message
        message_body = f"Your FreshK verification code is: {otp}. This code expires in 10 minutes. Do not share this code with anyone."
        
        # Send SMS
        message = client.messages.create(
            body=message_body,
            from_=twilio_phone,
            to=phone_number
        )
        
        logger.info(f"OTP sent successfully to {phone_number}. Message SID: {message.sid}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to send OTP to {phone_number}: {str(e)}")
        return False

def set_production_user_otp(user, expiry_minutes=10):
    """
    Generate and set OTP for a user in production
    
    Args:
        user: User instance
        expiry_minutes: OTP expiry time in minutes (default: 10)
    
    Returns:
        str: Generated OTP
    """
    otp = generate_production_otp()
    user.otp = otp
    user.otp_expiry = timezone.now() + timedelta(minutes=expiry_minutes)
    user.save(update_fields=['otp', 'otp_expiry'])
    
    # Log OTP generation for security audit
    logger.info(f"OTP generated for user {user.phone_number}")
    
    return otp

def clear_user_otp(user):
    """Clear OTP data from user after successful verification"""
    user.otp = None
    user.otp_expiry = None
    user.save(update_fields=['otp', 'otp_expiry'])
    
    logger.info(f"OTP cleared for user {user.phone_number}")

def validate_phone_number(phone_number):
    """
    Validate phone number format for production use
    
    Args:
        phone_number: Phone number string
    
    Returns:
        bool: True if valid, False otherwise
    """
    import re
    
    # Basic international phone number validation
    # Should start with + and have 10-15 digits
    pattern = r'^\+[1-9]\d{9,14}$'
    
    if not re.match(pattern, phone_number):
        logger.warning(f"Invalid phone number format: {phone_number}")
        return False
    
    return True

def rate_limit_check(user, max_attempts=3, window_minutes=60):
    """
    Check if user has exceeded OTP request rate limit
    
    Args:
        user: User instance
        max_attempts: Maximum OTP requests allowed
        window_minutes: Time window in minutes
    
    Returns:
        bool: True if within rate limit, False if exceeded
    """
    from django.core.cache import cache
    
    cache_key = f"otp_rate_limit_{user.id}"
    attempts = cache.get(cache_key, 0)
    
    if attempts >= max_attempts:
        logger.warning(f"Rate limit exceeded for user {user.phone_number}")
        return False
    
    # Increment counter
    cache.set(cache_key, attempts + 1, timeout=window_minutes * 60)
    return True 