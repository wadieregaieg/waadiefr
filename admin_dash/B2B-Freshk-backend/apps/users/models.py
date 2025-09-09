from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator

class CustomUser(AbstractUser):
    ROLE_CHOICES = (
        ('admin', 'Admin'),
        ('retailer', 'Retailer'),
        ('supplier', 'Supplier'),
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    
    # Phone number validation
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed."
    )
    phone_number = models.CharField(
        validators=[phone_regex],
        max_length=17,
        unique=True,
        null=True,
        blank=True,
        help_text="Phone number in international format"
    )
    phone_verified = models.BooleanField(default=False)
    
    # For OTP verification
    otp = models.CharField(max_length=6, blank=True, null=True)
    otp_expiry = models.DateTimeField(blank=True, null=True)
    
    # Additional fields for dashboard integration
    profile_picture = models.ImageField(upload_to='profile_pictures/', null=True, blank=True)
    last_login_ip = models.GenericIPAddressField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    
    # Additional metadata
    notes = models.TextField(blank=True, null=True)
    preferences = models.JSONField(default=dict, blank=True)

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
    
    class Meta:
        indexes = [
            models.Index(fields=['phone_number']),
            models.Index(fields=['role']),
            models.Index(fields=['email']),
            models.Index(fields=['username']),
        ]


class RetailerProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='retailer_profile')
    company_name = models.CharField(max_length=100)
    contact_number = models.CharField(max_length=20)
    address = models.TextField()
    # Additional retailer-specific fields

    def __str__(self):
        return f"Retailer: {self.company_name}"


class SupplierProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='supplier_profile')
    company_name = models.CharField(max_length=100)
    contact_person = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)
    address = models.TextField()
    additional_info = models.TextField(blank=True, null=True)
    # Additional supplier-specific fields

    def __str__(self):
        return f"Supplier: {self.company_name}"


class Supplier(models.Model):
    """Independent supplier model not tied to user accounts"""
    company_name = models.CharField(max_length=255)
    contact_person = models.CharField(max_length=255, blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    additional_info = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['company_name']),
            models.Index(fields=['email']),
            models.Index(fields=['phone']),
        ]
    
    def __str__(self):
        return self.company_name


class UserAddress(models.Model):
    ADDRESS_TYPE_CHOICES = (
        ('home', 'Home'),
        ('work', 'Work'),
        ('shipping', 'Shipping'),
        ('billing', 'Billing'),
        ('other', 'Other'),
    )
    
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='addresses')
    address_type = models.CharField(max_length=10, choices=ADDRESS_TYPE_CHOICES, default='home')
    street_address = models.CharField(max_length=255)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100, blank=True, null=True)
    postal_code = models.CharField(max_length=20, blank=True, null=True)
    country = models.CharField(max_length=100, default='Tunisia')
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-is_default', '-created_at']
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['address_type']),
            models.Index(fields=['is_default']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.get_address_type_display()}: {self.street_address}"
    
    def save(self, *args, **kwargs):
        # If this is set as default, unset other default addresses for this user
        if self.is_default:
            UserAddress.objects.filter(user=self.user, is_default=True).update(is_default=False)
        super().save(*args, **kwargs)
    
    @property
    def full_address(self):
        """Return formatted full address"""
        parts = [self.street_address, self.city]
        if self.state:
            parts.append(self.state)
        if self.postal_code:
            parts.append(self.postal_code)
        parts.append(self.country)
        return ', '.join(parts)
