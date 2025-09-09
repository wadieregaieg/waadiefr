from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .admin_views import AdminInventoryLogViewSet, AdminStockAlertViewSet

# Create a router for admin inventory viewsets
router = DefaultRouter()
router.register(r'logs', AdminInventoryLogViewSet)
router.register(r'alerts', AdminStockAlertViewSet, basename='stock-alerts')

urlpatterns = [
    path('', include(router.urls)),
] 