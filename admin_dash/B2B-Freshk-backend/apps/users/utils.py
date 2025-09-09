import random
import string
from datetime import datetime, timedelta
from django.utils import timezone
from django.conf import settings
from decouple import config
import logging

# Set up logger
logger = logging.getLogger(__name__)

# Don't try to import Twilio at all for testing purposes
TWILIO_AVAILABLE = False

def generate_otp(length=6):
    """Generate a random OTP of specified length"""
    return ''.join(random.choices(string.digits, k=length))

def is_otp_valid(user, otp):
    """Check if the OTP is valid for the user"""
    if not user.otp or not user.otp_expiry:
        return False
    
    # Check if OTP matches and has not expired
    return user.otp == otp and timezone.now() <= user.otp_expiry

def send_otp_via_sms(phone_number, otp):
    """
    Mock sending OTP via SMS
    
    For testing purposes, this function just logs the OTP and returns success.
    In production, this would use Twilio to send actual SMS messages.
    """
    # Log the OTP for development and testing
    logger.info(f"TEST MODE: OTP for {phone_number}: {otp}")
    print(f"TEST MODE: OTP for {phone_number}: {otp}")
    
    # Always return success for testing
    return True

def set_user_otp(user, expiry_minutes=10):
    """Generate and set OTP for a user"""
    otp = generate_otp()
    user.otp = otp
    user.otp_expiry = timezone.now() + timedelta(minutes=expiry_minutes)
    user.save(update_fields=['otp', 'otp_expiry'])
    return otp
