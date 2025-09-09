from django.urls import include, path
from rest_framework import routers
from .views import (
    MobileProductViewSet,
    MobileCategoryViewSet,
    MobileCartViewSet,
    MobileOrderViewSet,
    MobileAddressViewSet,
    phone_auth_request,
    phone_auth_verify,
    get_current_user,
)

router = routers.DefaultRouter()
router.register(r'products', MobileProductViewSet, basename='mobile-products')
router.register(r'categories', MobileCategoryViewSet)
router.register(r'cart', MobileCartViewSet, basename='mobile-cart')
router.register(r'orders', MobileOrderViewSet, basename='mobile-orders')
router.register(r'addresses', MobileAddressViewSet,
                basename='mobile-addresses')

urlpatterns = [
    path('', include(router.urls)),

    # User profile endpoint
    path('me/', get_current_user, name='mobile-current-user'),

    # Testing Authentication endpoints (for development/testing only)
    path('auth/request/', phone_auth_request, name='mobile-auth-request'),
    path('auth/verify/', phone_auth_verify, name='mobile-auth-verify'),

    # Production Authentication endpoints (include production URLs)
    path('', include('apps.mobile.production_urls')),
]
