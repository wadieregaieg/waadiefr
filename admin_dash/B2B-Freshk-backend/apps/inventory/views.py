from rest_framework import viewsets
from .models import InventoryLog
from .serializers import InventoryLogSerializer
from apps.users.permissions import IsAdmin, IsAdminOrSupplier
from rest_framework.permissions import IsAuthenticated

class InventoryLogViewSet(viewsets.ModelViewSet):
    queryset = InventoryLog.objects.all()
    serializer_class = InventoryLogSerializer
    
    """
    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminOrSupplier()]
        return [IsAuthenticated()]
    """
    
    def get_queryset(self):
        # Short-circuit for schema generation
        if getattr(self, 'swagger_fake_view', False):
            return InventoryLog.objects.none()
            
        # Admin can see all inventory logs
        if self.request.user.role == 'admin':
            return InventoryLog.objects.all()
        # Suppliers can only see logs for their products
        elif self.request.user.role == 'supplier' and hasattr(self.request.user, 'supplier_profile'):
            return InventoryLog.objects.filter(product__supplier=self.request.user.supplier_profile)
        # Retailers can see logs for products they've ordered
        elif self.request.user.role == 'retailer':
            return InventoryLog.objects.filter(
                product__in=self.request.user.orders.values_list('items__product', flat=True).distinct()
            )
        return InventoryLog.objects.none()
