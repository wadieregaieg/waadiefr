from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import CustomUser, RetailerProfile, SupplierProfile, Supplier, UserAddress

User = get_user_model()

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Add custom claims
        token['username'] = user.username
        token['role'] = user.role
        return token


class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'phone_number', 'phone_verified', 'profile_picture',
            'last_login_ip', 'is_active', 'date_joined', 'last_activity',
            'notes', 'preferences'
        )
        read_only_fields = ('id', 'date_joined', 'last_activity', 'last_login_ip')


class CustomUserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = (
            'username', 'email', 'password', 'confirm_password',
            'first_name', 'last_name', 'role', 'phone_number',
            'profile_picture', 'preferences'
        )

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")
        return data

    def create(self, validated_data):
        validated_data.pop('confirm_password')
        user = User.objects.create_user(**validated_data)
        return user


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=False)
    phone_number = serializers.CharField(required=False)

    def validate(self, attrs):
        email = attrs.get('email')
        phone_number = attrs.get('phone_number')
        
        if not email and not phone_number:
            raise serializers.ValidationError("Either email or phone_number must be provided")
        
        return attrs


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs


class PhoneVerificationRequestSerializer(serializers.Serializer):
    phone_number = serializers.CharField(required=True)


class PhoneVerificationConfirmSerializer(serializers.Serializer):
    phone_number = serializers.CharField(required=True)
    otp = serializers.CharField(required=True)


class PhoneLoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField(required=True)
    otp = serializers.CharField(required=True)


class RetailerProfileSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all(), required=False)
    username = serializers.CharField(source='user.username', read_only=True)
    companies = serializers.SerializerMethodField()

    class Meta:
        model = RetailerProfile
        fields = ('id', 'user', 'username', 'company_name', 'contact_number', 'address', 'companies')

    def get_companies(self, obj):
        return [{
            'id': obj.id,
            'name': obj.company_name,
            'contact_number': obj.contact_number,
            'address': obj.address
        }]

    def validate(self, data):
        # If user is not provided, set it to the current user
        if not data.get('user') and self.context['request'].user.is_authenticated:
            data['user'] = self.context['request'].user
        return data


class SupplierProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupplierProfile
        fields = ('company_name', 'contact_person', 'phone', 'address', 'additional_info')


class SupplierSerializer(serializers.ModelSerializer):
    """Serializer for the independent Supplier model"""
    
    class Meta:
        model = Supplier
        fields = (
            'id', 'company_name', 'contact_person', 'phone', 
            'email', 'address', 'additional_info', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def validate_company_name(self, value):
        """Ensure company name is not empty after stripping whitespace"""
        if not value.strip():
            raise serializers.ValidationError("Company name cannot be empty.")
        return value.strip()
    
    def validate_email(self, value):
        """Validate email format if provided"""
        if value and value.strip():
            return value.strip()
        return None
    
    def validate_phone(self, value):
        """Clean phone number if provided"""
        if value and value.strip():
            return value.strip()
        return None


class UserAddressSerializer(serializers.ModelSerializer):
    full_address = serializers.ReadOnlyField()
    
    class Meta:
        model = UserAddress
        fields = (
            'id', 'address_type', 'street_address', 'city', 'state', 
            'postal_code', 'country', 'is_default', 'full_address',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def validate(self, data):
        # Ensure street_address and city are not empty
        if not data.get('street_address', '').strip():
            raise serializers.ValidationError({'street_address': 'Street address cannot be empty.'})
        if not data.get('city', '').strip():
            raise serializers.ValidationError({'city': 'City cannot be empty.'})
        return data
    
    def create(self, validated_data):
        # Set the user to the current authenticated user
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class UserDetailUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating user profile details"""
    
    class Meta:
        model = User
        fields = (
            'first_name', 'last_name', 'email', 'phone_number',
            'profile_picture', 'preferences'
        )
    
    def validate_email(self, value):
        """Ensure email is unique if provided"""
        if value:
            user = self.instance
            if User.objects.filter(email=value).exclude(pk=user.pk).exists():
                raise serializers.ValidationError("A user with this email already exists.")
        return value
    
    def validate_phone_number(self, value):
        """Ensure phone number is unique if provided"""
        if value:
            user = self.instance
            if User.objects.filter(phone_number=value).exclude(pk=user.pk).exists():
                raise serializers.ValidationError("A user with this phone number already exists.")
        return value