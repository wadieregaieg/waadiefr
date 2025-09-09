from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db.models import Count, Q
from .models import RetailerProfile, SupplierProfile
from .serializers import CustomUserSerializer

User = get_user_model()

class DashboardUserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = CustomUserSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Get user statistics for dashboard"""
        total_users = User.objects.count()
        active_users = User.objects.filter(is_active=True).count()
        retailers = User.objects.filter(role='retailer').count()
        suppliers = User.objects.filter(role='supplier').count()
        
        # New users in last 30 days
        thirty_days_ago = timezone.now() - timezone.timedelta(days=30)
        new_users = User.objects.filter(date_joined__gte=thirty_days_ago).count()
        
        # Users by role
        users_by_role = User.objects.values('role').annotate(count=Count('id'))
        
        return Response({
            'total_users': total_users,
            'active_users': active_users,
            'retailers': retailers,
            'suppliers': suppliers,
            'new_users_30d': new_users,
            'users_by_role': users_by_role
        })

    @action(detail=False, methods=['get'])
    def search(self, request):
        """Search users with various filters"""
        query = request.query_params.get('q', '')
        role = request.query_params.get('role', None)
        is_active = request.query_params.get('is_active', None)
        
        queryset = User.objects.all()
        
        if query:
            queryset = queryset.filter(
                Q(username__icontains=query) |
                Q(email__icontains=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query) |
                Q(phone_number__icontains=query)
            )
        
        if role:
            queryset = queryset.filter(role=role)
            
        if is_active is not None:
            is_active = is_active.lower() == 'true'
            queryset = queryset.filter(is_active=is_active)
            
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def toggle_active(self, request, pk=None):
        """Toggle user active status"""
        user = self.get_object()
        user.is_active = not user.is_active
        user.save()
        return Response({
            'id': user.id,
            'is_active': user.is_active
        })

    @action(detail=True, methods=['post'])
    def update_role(self, request, pk=None):
        """Update user role"""
        user = self.get_object()
        new_role = request.data.get('role')
        
        if new_role not in dict(User.ROLE_CHOICES):
            return Response(
                {'error': 'Invalid role'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        user.role = new_role
        user.save()
        return Response({
            'id': user.id,
            'role': user.role
        }) 