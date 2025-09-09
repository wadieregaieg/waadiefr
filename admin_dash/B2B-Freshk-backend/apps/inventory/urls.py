from django.urls import include, path
from rest_framework import routers
from .views import InventoryLogViewSet

router = routers.DefaultRouter()
router.register(r'inventory-logs', InventoryLogViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
