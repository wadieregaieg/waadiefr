from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .admin_views import AdminAPKViewSet

# Create a router for admin APK viewsets
router = DefaultRouter()
router.register(r'versions', AdminAPKViewSet)

urlpatterns = [
    path('', include(router.urls)),
    # Additional admin-specific APK endpoints
    path('stats/', AdminAPKViewSet.as_view({'get': 'stats'}), name='admin-apk-stats'),
    path('upload/', AdminAPKViewSet.as_view({'post': 'upload'}), name='admin-apk-upload'),
] 