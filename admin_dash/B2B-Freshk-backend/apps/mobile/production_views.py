from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from django.db import transaction
import logging

from .production_utils import (
    set_production_user_otp, 
    send_production_otp_via_sms, 
    is_production_otp_valid,
    clear_user_otp,
    validate_phone_number,
    rate_limit_check
)
from .serializers import (
    PhoneAuthSerializer,
    PhoneVerifySerializer,
    MobileUserSerializer
)

User = get_user_model()
logger = logging.getLogger(__name__)

class ProductionOTPThrottle(AnonRateThrottle):
    """Custom throttle for production OTP requests"""
    rate = '5/hour'  # 5 requests per hour per IP
    scope = 'production_otp'

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
@throttle_classes([ProductionOTPThrottle])
def production_phone_auth_request(request):
    """
    Production-ready OTP request endpoint for phone authentication
    
    Features:
    - Rate limiting per IP and per user
    - Phone number validation
    - Proper error handling
    - Security logging
    - Twilio SMS integration
    """
    try:
        serializer = PhoneAuthSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data['phone_number']
        
        # Validate phone number format
        if not validate_phone_number(phone_number):
            logger.warning(f"Invalid phone number format attempted: {phone_number}")
            return Response({
                "error": "Invalid phone number format. Please use international format (+1234567890)"
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check if user exists
        user_exists = User.objects.filter(phone_number=phone_number).exists()

        if user_exists:
            # Login flow
            user = User.objects.get(phone_number=phone_number)
            
            # Check rate limiting for this user
            if not rate_limit_check(user):
                logger.warning(f"Rate limit exceeded for user {phone_number}")
                return Response({
                    "error": "Too many OTP requests. Please try again later."
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)
            
            # Generate and send OTP
            otp = set_production_user_otp(user)
            sms_sent = send_production_otp_via_sms(phone_number, otp)
            
            if not sms_sent:
                logger.error(f"Failed to send SMS to {phone_number}")
                return Response({
                    "error": "Failed to send verification code. Please try again."
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            logger.info(f"Production OTP sent for login: {phone_number}")
            return Response({
                "message": "Verification code sent successfully",
                "is_new_user": False,
                "expires_in": 600  # 10 minutes
            }, status=status.HTTP_200_OK)
            
        else:
            # Registration flow - create a temporary user
            with transaction.atomic():
                username = f"user_{phone_number.replace('+', '').replace(' ', '')}"
                
                # Ensure username is unique
                counter = 1
                original_username = username
                while User.objects.filter(username=username).exists():
                    username = f"{original_username}_{counter}"
                    counter += 1
                
                user = User.objects.create_user(
                    username=username,
                    phone_number=phone_number,
                    role='retailer',  # Default role for mobile users
                    is_active=False  # Will be activated after verification
                )
                
                # Generate and send OTP
                otp = set_production_user_otp(user)
                sms_sent = send_production_otp_via_sms(phone_number, otp)
                
                if not sms_sent:
                    # Rollback user creation if SMS fails
                    user.delete()
                    logger.error(f"Failed to send SMS during registration: {phone_number}")
                    return Response({
                        "error": "Failed to send verification code. Please try again."
                    }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
                
                logger.info(f"Production OTP sent for registration: {phone_number}")
                return Response({
                    "message": "Verification code sent successfully",
                    "is_new_user": True,
                    "expires_in": 600  # 10 minutes
                }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Unexpected error in production_phone_auth_request: {str(e)}")
        return Response({
            "error": "An unexpected error occurred. Please try again."
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
@throttle_classes([ProductionOTPThrottle])
def production_phone_auth_verify(request):
    """
    Production-ready OTP verification endpoint
    
    Features:
    - Secure OTP validation
    - Account activation for new users
    - JWT token generation
    - Security logging
    - Proper error handling
    """
    try:
        serializer = PhoneVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data['phone_number']
        otp = serializer.validated_data['otp']

        # Validate phone number format
        if not validate_phone_number(phone_number):
            logger.warning(f"Invalid phone number format in verification: {phone_number}")
            return Response({
                "error": "Invalid phone number format"
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(phone_number=phone_number)

            if is_production_otp_valid(user, otp):
                with transaction.atomic():
                    # Mark phone as verified
                    user.phone_verified = True

                    # If this is a new user, activate them
                    if not user.is_active:
                        user.is_active = True
                        logger.info(f"New user activated: {phone_number}")

                    # Update last login
                    user.last_login = timezone.now()
                    
                    # Save user changes
                    user.save(update_fields=['phone_verified', 'is_active', 'last_login'])
                    
                    # Clear OTP after successful verification
                    clear_user_otp(user)

                    # Generate JWT tokens
                    refresh = RefreshToken.for_user(user)

                    # Log successful authentication
                    logger.info(f"Successful production authentication: {phone_number}")

                    # Return user data and tokens
                    return Response({
                        'refresh': str(refresh),
                        'access': str(refresh.access_token),
                        'user': MobileUserSerializer(user).data,
                        'message': 'Authentication successful'
                    }, status=status.HTTP_200_OK)
            else:
                logger.warning(f"Invalid OTP attempt for {phone_number}")
                return Response({
                    "error": "Invalid or expired verification code"
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except User.DoesNotExist:
            logger.warning(f"Verification attempted for non-existent user: {phone_number}")
            return Response({
                "error": "No user found with this phone number"
            }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        logger.error(f"Unexpected error in production_phone_auth_verify: {str(e)}")
        return Response({
            "error": "An unexpected error occurred. Please try again."
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def production_resend_otp(request):
    """
    Resend OTP for authenticated users (e.g., for phone number changes)
    """
    try:
        user = request.user
        
        if not user.phone_number:
            return Response({
                "error": "No phone number associated with this account"
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check rate limiting
        if not rate_limit_check(user):
            logger.warning(f"Rate limit exceeded for OTP resend: {user.phone_number}")
            return Response({
                "error": "Too many OTP requests. Please try again later."
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)
        
        # Generate and send new OTP
        otp = set_production_user_otp(user)
        sms_sent = send_production_otp_via_sms(user.phone_number, otp)
        
        if not sms_sent:
            logger.error(f"Failed to resend SMS to {user.phone_number}")
            return Response({
                "error": "Failed to send verification code. Please try again."
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        logger.info(f"OTP resent to authenticated user: {user.phone_number}")
        return Response({
            "message": "Verification code sent successfully",
            "expires_in": 600
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Unexpected error in production_resend_otp: {str(e)}")
        return Response({
            "error": "An unexpected error occurred. Please try again."
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def production_auth_status(request):
    """
    Check authentication status and user details
    """
    try:
        user = request.user
        return Response({
            'authenticated': True,
            'user': MobileUserSerializer(user).data,
            'phone_verified': user.phone_verified,
            'account_active': user.is_active
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Unexpected error in production_auth_status: {str(e)}")
        return Response({
            "error": "An unexpected error occurred"
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR) 