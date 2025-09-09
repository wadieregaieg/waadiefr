from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Product

@receiver(post_save, sender=Product)
def create_initial_inventory(sender, instance, created, **kwargs):
    """Create initial inventory when a new product is created"""
    if created:
        initial_stock = 100  # Set your default initial stock
        instance.update_stock(
            quantity_change=initial_stock,
            reason="Initial stock for new product"
        ) 