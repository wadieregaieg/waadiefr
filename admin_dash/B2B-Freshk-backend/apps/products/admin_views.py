from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend

from .models import Product, ProductCategory
from .serializers import ProductSerializer, ProductCategorySerializer
from apps.users.permissions import IsAdmin
from apps.inventory.models import InventoryLog


class AdminProductViewSet(viewsets.ModelViewSet):
    """
    Admin-only product management API
    """
    serializer_class = ProductSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'supplier', 'is_active', 'unit']
    search_fields = ['name', 'description', 'sku']
    ordering_fields = ['name', 'price', 'stock_quantity']
    
    queryset = Product.objects.all()


class AdminCategoryViewSet(viewsets.ModelViewSet):
    """
    Admin-only category management API
    """
    serializer_class = ProductCategorySerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name']
    
    queryset = ProductCategory.objects.all() 