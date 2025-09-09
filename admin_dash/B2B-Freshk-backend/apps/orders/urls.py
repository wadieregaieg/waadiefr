from django.urls import include, path
from rest_framework import routers
from .views import OrderViewSet, OrderItemViewSet, PaymentTransactionViewSet

router = routers.DefaultRouter()
router.register(r'orders', OrderViewSet)
router.register(r'order-items', OrderItemViewSet)
router.register(r'payment-transactions', PaymentTransactionViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
