from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .admin_views import AdminProductViewSet, AdminCategoryViewSet

# Create a router for admin product viewsets
router = DefaultRouter()
router.register(r'products', AdminProductViewSet)
router.register(r'categories', AdminCategoryViewSet)

urlpatterns = [
    path('', include(router.urls)),
] 