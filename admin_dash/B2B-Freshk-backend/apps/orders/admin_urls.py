from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .admin_views import AdminOrderViewSet, AdminOrderItemViewSet, AdminPaymentViewSet

# Create a router for admin order viewsets
router = DefaultRouter()
router.register(r'orders', AdminOrderViewSet)
router.register(r'items', AdminOrderItemViewSet)
router.register(r'payments', AdminPaymentViewSet)

urlpatterns = [
    path('', include(router.urls)),
] 
