from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from .models import RetailerProfile, SupplierProfile, Supplier, UserAddress
from .serializers import (
    CustomUserSerializer,
    CustomUserRegistrationSerializer,
    CustomTokenObtainPairSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
    PhoneVerificationRequestSerializer,
    PhoneVerificationConfirmSerializer,
    PhoneLoginSerializer,
    RetailerProfileSerializer,
    SupplierProfileSerializer,
    SupplierSerializer,
    UserAddressSerializer,
    UserDetailUpdateSerializer
)
from .utils import set_user_otp, send_otp_via_sms, is_otp_valid

User = get_user_model()


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = CustomUserSerializer

    def get_permissions(self):
        # Public endpoints - no authentication required
        if self.action in ['create', 'phone_verification_request', 'phone_verification_confirm', 'phone_login', 'password_reset_request', 'password_reset_confirm']:
            permission_classes = [permissions.AllowAny]
        # User profile endpoints - authenticated users only
        elif self.action in ['retrieve', 'update', 'partial_update', 'profile']:
            permission_classes = [permissions.IsAuthenticated]
        # Admin-only endpoints
        else:
            permission_classes = [permissions.IsAdminUser]
        return [permission() for permission in permission_classes]

    def create(self, request, *args, **kwargs):
        serializer = CustomUserRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # If phone number is provided, send verification OTP
        if user.phone_number:
            otp = set_user_otp(user)
            send_otp_via_sms(user.phone_number, otp)

        return Response(
            {"message": "User created successfully. Please verify your account."},
            status=status.HTTP_201_CREATED
        )

    @action(detail=False, methods=['post'])
    def phone_verification_request(self, request):
        serializer = PhoneVerificationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data['phone_number']

        try:
            user = User.objects.get(phone_number=phone_number)
            otp = set_user_otp(user)
            send_otp_via_sms(phone_number, otp)
            return Response({"message": "OTP sent successfully"}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response(
                {"error": "No user found with this phone number"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['post'])
    def phone_verification_confirm(self, request):
        serializer = PhoneVerificationConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data['phone_number']
        otp = serializer.validated_data['otp']

        try:
            user = User.objects.get(phone_number=phone_number)

            if is_otp_valid(user, otp):
                user.phone_verified = True
                user.otp = None
                user.otp_expiry = None
                user.save(update_fields=[
                          'phone_verified', 'otp', 'otp_expiry'])

                return Response({"message": "Phone number verified successfully"}, status=status.HTTP_200_OK)
            else:
                return Response(
                    {"error": "Invalid or expired OTP"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except User.DoesNotExist:
            return Response(
                {"error": "No user found with this phone number"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['post'])
    def phone_login(self, request):
        serializer = PhoneLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data['phone_number']
        otp = serializer.validated_data['otp']

        try:
            user = User.objects.get(phone_number=phone_number)

            if not user.phone_verified:
                return Response(
                    {"error": "Phone number not verified"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            if is_otp_valid(user, otp):
                # Clear OTP after successful login
                user.otp = None
                user.otp_expiry = None
                user.save(update_fields=['otp', 'otp_expiry'])

                # Generate tokens
                refresh = RefreshToken.for_user(user)

                return Response({
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                    'user': CustomUserSerializer(user).data
                }, status=status.HTTP_200_OK)
            else:
                return Response(
                    {"error": "Invalid or expired OTP"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except User.DoesNotExist:
            return Response(
                {"error": "No user found with this phone number"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['post'])
    def password_reset_request(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data.get('email')
        phone_number = serializer.validated_data.get('phone_number')

        # Handle email-based reset
        if email:
            try:
                user = User.objects.get(email=email)
                # Send password reset email (implementation not shown)
                return Response({"message": "Password reset email sent"}, status=status.HTTP_200_OK)
            except User.DoesNotExist:
                pass  # Don't reveal if email exists or not

        # Handle phone-based reset
        if phone_number:
            try:
                user = User.objects.get(phone_number=phone_number)
                otp = set_user_otp(user)
                send_otp_via_sms(phone_number, otp)
                return Response({"message": "OTP sent for password reset"}, status=status.HTTP_200_OK)
            except User.DoesNotExist:
                pass  # Don't reveal if phone number exists or not

        # Always return success to prevent user enumeration
        return Response({"message": "If an account exists, a reset link/OTP has been sent"}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'])
    def password_reset_confirm(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        token = serializer.validated_data.get('token')
        password = serializer.validated_data.get('password')

        # For phone-based reset, the token is actually the OTP
        # Try to find a user with this OTP
        try:
            user = User.objects.get(otp=token)

            if is_otp_valid(user, token):
                # Reset the password
                user.set_password(password)
                # Clear OTP after password reset
                user.otp = None
                user.otp_expiry = None
                user.save(update_fields=['password', 'otp', 'otp_expiry'])

                return Response({"message": "Password reset successful"}, status=status.HTTP_200_OK)
            else:
                return Response(
                    {"error": "Invalid or expired token"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except User.DoesNotExist:
            return Response(
                {"error": "Invalid token"},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['get', 'put', 'patch'])
    def profile(self, request):
        """Get or update current user's profile"""
        user = request.user

        if request.method == 'GET':
            serializer = CustomUserSerializer(user)
            return Response(serializer.data)

        elif request.method in ['PUT', 'PATCH']:
            partial = request.method == 'PATCH'
            serializer = UserDetailUpdateSerializer(
                user, data=request.data, partial=partial)
            serializer.is_valid(raise_exception=True)
            serializer.save()

            # Return updated user data
            response_serializer = CustomUserSerializer(user)
            return Response(response_serializer.data)


class RetailerProfileViewSet(viewsets.ModelViewSet):
    queryset = RetailerProfile.objects.all()
    serializer_class = RetailerProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Admin can see all profiles, retailers can only see their own
        if self.request.user.role == 'admin':
            return RetailerProfile.objects.all()
        return RetailerProfile.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        # Allow admin to specify user, otherwise use current user
        if self.request.user.role == 'admin' and 'user' in self.request.data:
            serializer.save()  # User specified in data
        else:
            serializer.save(user=self.request.user)


class SupplierProfileViewSet(viewsets.ModelViewSet):
    queryset = SupplierProfile.objects.all()
    serializer_class = SupplierProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Admin can see all profiles, suppliers can only see their own
        if self.request.user.role == 'admin':
            return SupplierProfile.objects.all()
        return SupplierProfile.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        # Allow admin to specify user, otherwise use current user
        if self.request.user.role == 'admin' and 'user' in self.request.data:
            serializer.save()  # User specified in data
        else:
            serializer.save(user=self.request.user)


class SupplierViewSet(viewsets.ModelViewSet):
    """ViewSet for independent Supplier model"""
    queryset = Supplier.objects.all()
    serializer_class = SupplierSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Return all suppliers for admin users, all suppliers for regular users too since it's just data"""
        return Supplier.objects.all()

    def perform_create(self, serializer):
        """Create a new supplier"""
        serializer.save()

    def perform_update(self, serializer):
        """Update an existing supplier"""
        serializer.save()

    def destroy(self, request, *args, **kwargs):
        """Delete a supplier"""
        try:
            instance = self.get_object()
            instance.delete()
            return Response(
                {"message": "Supplier deleted successfully"},
                status=status.HTTP_204_NO_CONTENT
            )
        except Exception as e:
            return Response(
                {"error": f"Error deleting supplier: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST
            )


class UserAddressViewSet(viewsets.ModelViewSet):
    """ViewSet for managing user addresses"""
    serializer_class = UserAddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Users can only see their own addresses
        return UserAddress.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        # Set the user to the current authenticated user
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def set_default(self, request, pk=None):
        """Set an address as the default address"""
        address = self.get_object()

        # Unset other default addresses for this user
        UserAddress.objects.filter(
            user=request.user, is_default=True).update(is_default=False)

        # Set this address as default
        address.is_default = True
        address.save()

        serializer = self.get_serializer(address)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def default(self, request):
        """Get the default address for the user"""
        try:
            default_address = UserAddress.objects.get(
                user=request.user, is_default=True)
            serializer = self.get_serializer(default_address)
            return Response(serializer.data)
        except UserAddress.DoesNotExist:
            return Response(
                {"message": "No default address found"},
                status=status.HTTP_404_NOT_FOUND
            )
