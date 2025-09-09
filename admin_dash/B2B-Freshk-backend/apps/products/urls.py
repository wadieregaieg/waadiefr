from django.urls import include, path
from rest_framework import routers
from .views import ProductCategoryViewSet, ProductViewSet

router = routers.DefaultRouter()
router.register(r'categories', ProductCategoryViewSet)
router.register(r'products', ProductViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
