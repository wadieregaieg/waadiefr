"""
URL configuration for freshk project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView, TokenVerifyView

# Swagger documentation
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
    openapi.Info(
        title="FreshK API",
        default_version='v1',
        description="API for FreshK B2B platform connecting retailers with suppliers of fresh products",
        terms_of_service="https://www.freshk.com/terms/",
        contact=openapi.Contact(email="contact@freshk.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # API Documentation
    path('api/docs/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('api/redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    
    # Authentication
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    
    # General API endpoints
    path('api/users/', include('apps.users.urls')),
    path('api/products/', include('apps.products.urls')),
    path('api/orders/', include('apps.orders.urls')),
    path('api/inventory/', include('apps.inventory.urls')),
    path('api/analytics/', include('apps.analytics.urls')),
    path('api/cart/', include('apps.cart.urls')),
    
    # Mobile app endpoints
    path('api/mobile/', include('apps.mobile.urls')),
    
    # APK Update endpoints
    path('api/apk/', include('apps.apk_updates.urls')),
    
    # Admin dashboard API endpoints
    path('api/admin/users/', include('apps.users.admin_urls')),
    path('api/admin/products/', include('apps.products.admin_urls')),
    path('api/admin/orders/', include('apps.orders.admin_urls')),
    path('api/admin/inventory/', include('apps.inventory.admin_urls')),
    path('api/admin/analytics/', include('apps.analytics.admin_urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)