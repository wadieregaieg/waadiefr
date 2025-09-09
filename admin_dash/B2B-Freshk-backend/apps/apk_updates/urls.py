from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Router for ViewSets
router = DefaultRouter()
router.register(r'versions', views.APKVersionViewSet)

urlpatterns = [
    # Main API endpoints
    path('check-update/', views.check_update, name='apk-check-update'),
    path('download/<str:version>/', views.download_apk, name='apk-download-version'),
    path('download/', views.download_apk, name='apk-download-latest'),
    
    # ViewSet endpoints (for admin/management)
    path('', include(router.urls)),
    
    # Legacy endpoints (for backward compatibility)
    path('legacy/check-update/', views.legacy_check_update, name='legacy-check-update'),
    path('legacy/download-apk/', views.legacy_download_apk, name='legacy-download-apk'),
]
