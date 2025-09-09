from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    UserViewSet,
    CustomTokenObtainPairView,
    RetailerProfileViewSet,
    SupplierProfileViewSet,
    SupplierViewSet,
    UserAddressViewSet
)
from .dashboard_views import DashboardUserViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'retailers', RetailerProfileViewSet)
# Old supplier profiles tied to users
router.register(r'suppliers', SupplierProfileViewSet,
                basename='supplier-profiles')
router.register(r'supplier-data', SupplierViewSet,
                basename='suppliers')  # New independent suppliers
router.register(r'addresses', UserAddressViewSet, basename='user-addresses')

# Dashboard specific router
dashboard_router = DefaultRouter()
dashboard_router.register(r'users', DashboardUserViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', include(dashboard_router.urls)),
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    # Phone authentication endpoints
    path('phone-verification-request/', UserViewSet.as_view(
        {'post': 'phone_verification_request'}), name='phone_verification_request'),
    path('phone-verification-confirm/', UserViewSet.as_view(
        {'post': 'phone_verification_confirm'}), name='phone_verification_confirm'),
    path('phone-login/',
         UserViewSet.as_view({'post': 'phone_login'}), name='phone_login'),
    # Password reset endpoints
    path('password-reset-request/', UserViewSet.as_view(
        {'post': 'password_reset_request'}), name='password_reset_request'),
    path('password-reset-confirm/', UserViewSet.as_view(
        {'post': 'password_reset_confirm'}), name='password_reset_confirm'),
]
