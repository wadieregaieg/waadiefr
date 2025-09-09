from django.db import models
from apps.users.models import SupplierProfile
from django.core.validators import MinValueValidator, RegexValidator
from django.core.exceptions import ValidationError
import os
from decimal import Decimal
from django.utils import timezone

def validate_image_extension(value):
    ext = os.path.splitext(value.name)[1]
    valid_extensions = ['.jpg', '.jpeg', '.png', '.webp']
    if not ext.lower() in valid_extensions:
        raise ValidationError('Unsupported file extension. Allowed extensions are: .jpg, .jpeg, .png, .webp')

def validate_image_size(value):
    # 5MB limit
    filesize = value.size
    if filesize > 5 * 1024 * 1024:
        raise ValidationError("The maximum file size allowed is 5MB")

class ProductCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.name
    
    class Meta:
        verbose_name_plural = "Product Categories"


class Product(models.Model):
    UNIT_CHOICES = (
        ('kg', 'Kilogram'),
        ('ton', 'Ton'),
    )
    
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    price = models.DecimalField(
        max_digits=10, 
        decimal_places=3,  # TND uses 3 decimal places
        validators=[MinValueValidator(Decimal('0.001'), message="Price must be greater than zero")]
    )
    unit = models.CharField(max_length=3, choices=UNIT_CHOICES, default='kg')
    stock_quantity = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        validators=[MinValueValidator(Decimal('0'), message="Stock quantity cannot be negative")]
    )
    minimum_stock = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        default=Decimal('10.000'),
        validators=[MinValueValidator(Decimal('0'), message="Minimum stock cannot be negative")],
        help_text="Minimum stock level for alerts"
    )
    is_active = models.BooleanField(default=True, help_text="Inactive products won't appear in listings")
    sku = models.CharField(
        max_length=50, 
        unique=True,
        validators=[
            RegexValidator(
                regex=r'^[A-Za-z0-9\-\_]+$',
                message="SKU can only contain letters, numbers, hyphens, and underscores"
            )
        ]
    )
    image = models.ImageField(
        upload_to='products/', 
        blank=True, 
        null=True,
        validators=[validate_image_extension, validate_image_size]
    )
    category = models.ForeignKey(ProductCategory, on_delete=models.CASCADE, related_name='products')
    supplier = models.ForeignKey(SupplierProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return self.name
    
    def clean(self):
        # Additional cross-field validation can be added here
        if self.price <= 0:
            raise ValidationError({'price': 'Price must be greater than zero'})
        
        if self.stock_quantity < 0:
            raise ValidationError({'stock_quantity': 'Stock quantity cannot be negative'})
        
        if self.minimum_stock < 0:
            raise ValidationError({'minimum_stock': 'Minimum stock cannot be negative'})
    
    def update_stock(self, quantity_change, reason=""):
        """Update stock and create inventory log"""
        from apps.inventory.models import InventoryLog
        
        # Update stock quantity
        old_quantity = self.stock_quantity
        self.stock_quantity += Decimal(str(quantity_change))
        
        # Ensure stock doesn't go negative
        if self.stock_quantity < 0:
            self.stock_quantity = Decimal('0')
        
        self.updated_at = timezone.now()
        self.save(update_fields=['stock_quantity', 'updated_at'])
        
        # Create inventory log
        InventoryLog.objects.create(
            product=self,
            change=int(quantity_change),
            reason=reason or f"Stock adjustment"
        )
        
        return self.stock_quantity
    
    @property
    def is_low_stock(self):
        """Check if product is below minimum stock level"""
        return self.stock_quantity <= self.minimum_stock
    
    @property
    def stock_status(self):
        """Return stock status string"""
        if self.stock_quantity <= 0:
            return "out_of_stock"
        elif self.stock_quantity <= self.minimum_stock / 2:
            return "critical"
        elif self.stock_quantity <= self.minimum_stock:
            return "low"
        else:
            return "good"
    
    @property
    def stock_display(self):
        """Return formatted stock with unit"""
        return f"{self.stock_quantity} {self.unit}"
    
    @property
    def price_display(self):
        """Return formatted price with currency"""
        return f"{self.price} TND"
    
    def convert_to_kg(self):
        """Convert stock to kg if stored in tons"""
        if self.unit == 'ton':
            return self.stock_quantity * 1000
        return self.stock_quantity
    
    def convert_to_ton(self):
        """Convert stock to tons if stored in kg"""
        if self.unit == 'kg':
            return self.stock_quantity / 1000
        return self.stock_quantity
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['sku']),
            models.Index(fields=['category']),
            models.Index(fields=['supplier']),
            models.Index(fields=['price']),
            models.Index(fields=['unit']),
            models.Index(fields=['is_active']),
        ]
