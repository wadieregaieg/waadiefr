from django.db import models
from apps.users.models import CustomUser
from apps.products.models import Product
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
import uuid
from decimal import Decimal

class Order(models.Model):
    ORDER_STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('out_for_delivery', 'Out for Delivery'),
        ('delivered', 'Delivered'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('returned', 'Returned'),
    )
    
    PAYMENT_METHOD_CHOICES = (
        ('cash_on_delivery', 'Cash on Delivery'),
        ('bank_transfer', 'Bank Transfer'),
        ('card', 'Credit/Debit Card'),
    )
    
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='orders')
    order_date = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=ORDER_STATUS_CHOICES, default='pending')
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES, default='cash_on_delivery')
    total_amount = models.DecimalField(
        max_digits=12, 
        decimal_places=3,  # TND uses 3 decimal places
        validators=[MinValueValidator(0.001, message="Total amount must be greater than zero")]
    )
    notes = models.TextField(blank=True, null=True)
    address = models.CharField(max_length=255, blank=True, null=True)  # New field for delivery address
    updated_at = models.DateTimeField(auto_now=True)
    
    # Add fields for analytics
    profit_margin = models.DecimalField(
        max_digits=5,
        decimal_places=2,  # Percentage
        null=True,
        blank=True,
        help_text="Profit margin percentage for this order"
    )
    
    def __str__(self):
        return f"Order {self.id} by {self.user.username}"
    
    def clean(self):
        # Validate that the total amount matches the sum of order items
        if self.id:  # Only check for existing orders
            items_total = sum(item.subtotal for item in self.items.all())
            if abs(items_total - self.total_amount) > 0.001:  # Allow for small float precision differences
                raise ValidationError({'total_amount': f'Total amount ({self.total_amount}) does not match sum of items ({items_total})'})
    
    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)
    
    def set_status(self, new_status):
        """
        Validate and perform order status transitions
        """
        valid_transitions = {
            'pending': ['processing', 'cancelled'],
            'processing': ['out_for_delivery', 'cancelled'],
            'out_for_delivery': ['delivered', 'returned'],
            'delivered': ['completed', 'returned'],
            'completed': [],  # Terminal state
            'cancelled': [],  # Terminal state
            'returned': ['completed'],
        }
        
        if new_status in valid_transitions.get(self.status, []):
            self.status = new_status
            self.save(update_fields=['status', 'updated_at'])
            return True
        return False
    
    @property
    def total_quantity_kg(self):
        """Calculate total quantity in kg"""
        total = 0
        for item in self.items.all():
            if item.product.unit == 'ton':
                total += item.quantity * 1000  # Convert tons to kg
            else:
                total += item.quantity
        return total
    
    @property
    def total_quantity_ton(self):
        """Calculate total quantity in tons"""
        return self.total_quantity_kg / 1000
    
    @property
    def total_display(self):
        """Return formatted total with currency"""
        return f"{self.total_amount} TND"
    
    class Meta:
        ordering = ['-order_date']
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['status']),
            models.Index(fields=['order_date']),
        ]


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        validators=[MinValueValidator(Decimal('0.001'), message="Quantity must be greater than zero")]
    )
    price = models.DecimalField(
        max_digits=10, 
        decimal_places=3,  # TND uses 3 decimal places
        validators=[MinValueValidator(Decimal('0.001'), message="Price must be greater than zero")]
    )  # Price at the time of ordering
    unit = models.CharField(max_length=3, choices=Product.UNIT_CHOICES, default='kg')
    
    # Add fields for analytics
    cost_price = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        null=True,
        blank=True,
        help_text="Cost price at time of ordering (for profit calculation)"
    )

    def __str__(self):
        return f"{self.quantity} {self.unit} of {self.product.name}"
    
    def clean(self):
        # Validate that the product has enough stock
        product_quantity_in_item_unit = self.product.stock_quantity
        if self.product.unit != self.unit:
            # Convert between units if necessary
            if self.product.unit == 'kg' and self.unit == 'ton':
                product_quantity_in_item_unit = self.product.stock_quantity / 1000
            elif self.product.unit == 'ton' and self.unit == 'kg':
                product_quantity_in_item_unit = self.product.stock_quantity * 1000
                
        if product_quantity_in_item_unit < self.quantity:
            raise ValidationError({'quantity': f'Not enough stock. Available: {product_quantity_in_item_unit} {self.unit}'})
    
    def save(self, *args, **kwargs):
        # Set the price to the current product price if not provided
        if not self.price and self.product:
            self.price = self.product.price
            
        # Set the unit to match the product if not specified
        if not self.unit:
            self.unit = self.product.unit
        
        # Track if this is a new item
        is_new = self.pk is None
        
        # Validate before saving
        self.clean()
        
        # Save the item first
        super().save(*args, **kwargs)
        
        # Update the order total (only if order exists and has items)
        try:
            if self.order and self.order.pk:
                # Recalculate order total from all items
                total = sum(item.subtotal for item in self.order.items.all())
                if self.order.total_amount != total:
                    self.order.total_amount = total
                    self.order.save(update_fields=['total_amount', 'updated_at'])
        except Exception:
            pass  # Don't fail if order total update fails
        
        # Update product stock for new items only
        if is_new and self.product:
            try:
                # Convert units if necessary
                quantity_in_product_unit = self.quantity
                if self.product.unit != self.unit:
                    if self.unit == 'kg' and self.product.unit == 'ton':
                        quantity_in_product_unit = self.quantity / 1000
                    elif self.unit == 'ton' and self.product.unit == 'kg':
                        quantity_in_product_unit = self.quantity * 1000
                        
                # Check if enough stock is available
                if self.product.stock_quantity >= quantity_in_product_unit:
                    # Reduce stock
                    self.product.stock_quantity -= quantity_in_product_unit
                    self.product.save(update_fields=['stock_quantity', 'updated_at'])
            except Exception:
                pass  # Don't fail if stock update fails
    
    @property
    def subtotal(self):
        """Calculate the subtotal for this item"""
        return self.price * self.quantity
    
    @property
    def quantity_in_kg(self):
        """Return quantity converted to kg"""
        if self.unit == 'ton':
            return self.quantity * 1000
        return self.quantity
    
    @property
    def quantity_in_ton(self):
        """Return quantity converted to tons"""
        if self.unit == 'kg':
            return self.quantity / 1000
        return self.quantity
    
    @property
    def profit(self):
        """Calculate profit if cost price is available"""
        if self.cost_price:
            return (self.price - self.cost_price) * self.quantity
        return None
    
    @property
    def profit_margin_percentage(self):
        """Calculate profit margin percentage if cost price is available"""
        if self.cost_price and self.cost_price > 0:
            return ((self.price - self.cost_price) / self.cost_price) * 100
        return None
    
    class Meta:
        unique_together = ['order', 'product']
        indexes = [
            models.Index(fields=['order']),
            models.Index(fields=['product']),
            models.Index(fields=['unit']),
        ]


class PaymentTransaction(models.Model):
    PAYMENT_METHOD_CHOICES = (
        ('cash_on_delivery', 'Cash on Delivery'),
        ('bank_transfer', 'Bank Transfer'),
        ('card', 'Credit/Debit Card'),
        # Additional methods can be added later
    )
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='transactions')
    transaction_id = models.CharField(max_length=100, unique=True, blank=True, null=True)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES, default='cash_on_delivery')
    amount = models.DecimalField(
        max_digits=12, 
        decimal_places=3,  # TND uses 3 decimal places
        validators=[MinValueValidator(Decimal('0.001'), message="Amount must be greater than zero")]
    )
    currency = models.CharField(max_length=3, default='TND')  # Set default to TND
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    timestamp = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"Transaction for Order {self.order.id}"
    
    def save(self, *args, **kwargs):
        # Generate a unique transaction ID if not provided
        if not self.transaction_id:
            self.transaction_id = f"TXN-{uuid.uuid4().hex[:12].upper()}"
        super().save(*args, **kwargs)
    
    @property
    def amount_display(self):
        """Return formatted amount with currency"""
        return f"{self.amount} {self.currency}"
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['order']),
            models.Index(fields=['status']),
            models.Index(fields=['payment_method']),
            models.Index(fields=['timestamp']),
        ]
