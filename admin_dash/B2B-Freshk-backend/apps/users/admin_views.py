from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django_filters.rest_framework import DjangoFilterBackend

from .models import CustomUser, RetailerProfile, SupplierProfile
from .serializers import CustomUserSerializer, RetailerProfileSerializer, SupplierProfileSerializer
from .permissions import IsAdmin


class AdminUserViewSet(viewsets.ModelViewSet):
    """
    Admin-only user management API
    """
    serializer_class = CustomUserSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['role', 'is_active', 'phone_verified']
    search_fields = ['username', 'email', 'phone_number']
    ordering_fields = ['date_joined', 'last_login']
    
    queryset = CustomUser.objects.all()


class AdminRetailerViewSet(viewsets.ModelViewSet):
    """
    Admin-only retailer management API
    """
    serializer_class = RetailerProfileSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['user__username', 'user__email', 'business_name']
    ordering_fields = ['user__date_joined']
    
    queryset = RetailerProfile.objects.all().select_related('user')


class AdminSupplierViewSet(viewsets.ModelViewSet):
    """
    Admin-only supplier management API
    """
    serializer_class = SupplierProfileSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['user__username', 'user__email', 'business_name']
    ordering_fields = ['user__date_joined']
    
    queryset = SupplierProfile.objects.all().select_related('user') 