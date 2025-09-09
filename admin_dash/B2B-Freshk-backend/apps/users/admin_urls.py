from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .admin_views import AdminUserViewSet, AdminRetailerViewSet, AdminSupplierViewSet

# Create a router for admin viewsets
router = DefaultRouter()
router.register(r'users', AdminUserViewSet)
router.register(r'retailers', AdminRetailerViewSet)
router.register(r'suppliers', AdminSupplierViewSet)

urlpatterns = [
    path('', include(router.urls)),
] 