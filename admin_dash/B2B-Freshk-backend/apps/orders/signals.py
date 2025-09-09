from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Order

@receiver(post_save, sender=Order)
def handle_order_completion(sender, instance, created, **kwargs):
    """Auto-deduct stock when order is completed"""
    if not created and instance.status == 'completed':
        # Simple approach - deduct stock for completed orders
        # Only deduct if this is a status change to completed
        for item in instance.items.all():
            # Check if inventory log already exists for this order item
            existing_logs = item.product.inventory_logs.filter(
                reason__contains=f"Order #{instance.id} completion"
            )
            
            # Only deduct if no log exists (prevents double deduction)
            if not existing_logs.exists():
                item.product.update_stock(
                    quantity_change=-int(float(item.quantity)),
                    reason=f"Order #{instance.id} completion"
                ) 