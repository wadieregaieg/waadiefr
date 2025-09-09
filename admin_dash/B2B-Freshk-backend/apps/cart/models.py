from django.db import models
from apps.users.models import CustomUser
from apps.products.models import Product
from decimal import Decimal

class Cart(models.Model):
    """
    Shopping cart model to store items before checkout
    """
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='cart')
    total_amount = models.DecimalField(max_digits=12, decimal_places=3, default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Cart for {self.user.username}"
    
    @property
    def total(self):
        """Calculate the total price of all items in the cart"""
        return sum(item.subtotal for item in self.items.all())
    
    @property
    def item_count(self):
        """Count the total number of items in the cart"""
        return self.items.count()
    
    def update_total(self):
        """Update cart total_amount based on items"""
        self.total_amount = sum(item.subtotal for item in self.items.all())
        self.save(update_fields=['total_amount', 'updated_at'])


class CartItem(models.Model):
    """
    Individual items in a shopping cart
    """
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.DecimalField(max_digits=10, decimal_places=3, default=Decimal('1.000'))
    added_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('cart', 'product')
        ordering = ['-added_at']
    
    def __str__(self):
        return f"{self.quantity} x {self.product.name} in {self.cart}"
    
    @property
    def subtotal(self):
        """Calculate the subtotal for this cart item"""
        return self.product.price * self.quantity
