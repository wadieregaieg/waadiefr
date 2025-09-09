from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import SalesReportViewSet, ProductPerformanceViewSet, CategoryPerformanceViewSet
from .admin_views import AdminAnalyticsViewSet, AdminEventLogViewSet

# Create a router for admin analytics viewsets
router = DefaultRouter()
router.register(r'sales', SalesReportViewSet)
router.register(r'products', ProductPerformanceViewSet)
router.register(r'categories', CategoryPerformanceViewSet)
router.register(r'dashboard', AdminAnalyticsViewSet, basename='admin-analytics')
router.register(r'events', AdminEventLogViewSet)

urlpatterns = [
    path('', include(router.urls)),
] 