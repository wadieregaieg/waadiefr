from django.db import models
from apps.products.models import Product

class InventoryLog(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='inventory_logs')
    change = models.IntegerField()  # Positive for addition, negative for reduction
    timestamp = models.DateTimeField(auto_now_add=True)
    reason = models.CharField(max_length=255, help_text="Reason for the stock change (e.g., restock, sale, adjustment)")

    def __str__(self):
        return f"{self.change} for {self.product.name} on {self.timestamp}"
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['product']),
            models.Index(fields=['timestamp']),
        ]
