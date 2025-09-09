from django.urls import include, path
from rest_framework import routers
from .views import (
    AnalyticsEventViewSet,
    SalesReportViewSet,
    ProductPerformanceViewSet,
    CategoryPerformanceViewSet
)

router = routers.DefaultRouter()
router.register(r'events', AnalyticsEventViewSet)
router.register(r'sales-reports', SalesReportViewSet)
router.register(r'product-performance', ProductPerformanceViewSet)
router.register(r'category-performance', CategoryPerformanceViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
