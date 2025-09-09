from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Avg, F
from django.utils import timezone
from datetime import timedelta, datetime

from .models import AnalyticsEvent, SalesReport, ProductPerformance, CategoryPerformance
from .serializers import AnalyticsEventSerializer, SalesReportSerializer, ProductPerformanceSerializer, CategoryPerformanceSerializer
from apps.orders.models import Order, OrderItem
from apps.products.models import Product, ProductCategory
from apps.users.models import CustomUser
from apps.users.permissions import IsAdmin


class AdminAnalyticsViewSet(viewsets.ViewSet):
    """Admin viewset for analytics and reporting"""
    permission_classes = [IsAdmin]
    
    def list(self, request):
        """Get overview analytics data"""
        return self.dashboard(request)
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Get dashboard analytics overview"""
        # Time period selection
        period = request.query_params.get('period', 'month')
        
        if period == 'week':
            start_date = timezone.now() - timedelta(days=7)
        elif period == 'year':
            start_date = timezone.now() - timedelta(days=365)
        elif period == 'day':
            start_date = timezone.now() - timedelta(days=1)
        else:  # default to month
            start_date = timezone.now() - timedelta(days=30)
        
        # Get basic metrics
        total_orders = Order.objects.filter(
            order_date__gte=start_date
        ).count()
        
        completed_orders = Order.objects.filter(
            order_date__gte=start_date,
            status='completed'
        )
        
        total_sales = completed_orders.aggregate(
            total=Sum('total_amount')
        )['total'] or 0
        
        average_order_value = completed_orders.aggregate(
            avg=Avg('total_amount')
        )['avg'] or 0
        
        # Get user stats
        total_users = CustomUser.objects.count()
        new_users = CustomUser.objects.filter(
            date_joined__gte=start_date
        ).count()
        
        # Get product stats
        total_products = Product.objects.filter(is_active=True).count()
        low_stock_products = Product.objects.filter(
            stock_quantity__lte=F('minimum_stock'),
            is_active=True
        ).count()
        
        # Get recent activity
        recent_orders = Order.objects.filter(
            order_date__gte=start_date
        ).order_by('-order_date')[:5].values(
            'id', 'order_date', 'status', 'total_amount', 'user__username'
        )
        
        # Top products by sales
        top_products = OrderItem.objects.filter(
            order__order_date__gte=start_date,
            order__status='completed'
        ).values(
            'product__name'
        ).annotate(
            total_sales=Sum(F('price') * F('quantity')),
            total_quantity=Sum('quantity')
        ).order_by('-total_sales')[:5]
        
        return Response({
            'period': period,
            'start_date': start_date.strftime('%Y-%m-%d'),
            'overview': {
                'total_orders': total_orders,
                'total_sales': float(total_sales),
                'average_order_value': float(average_order_value),
                'total_users': total_users,
                'new_users': new_users,
                'total_products': total_products,
                'low_stock_alerts': low_stock_products,
            },
            'recent_orders': list(recent_orders),
            'top_products': list(top_products),
        })
    
    @action(detail=False, methods=['get'])
    def sales_reports(self, request):
        """Get sales reports with various time periods"""
        period_type = request.query_params.get('period', 'weekly')
        
        # Generate report if it doesn't exist
        report = SalesReport.generate_report(period_type)
        
        # Get recent reports of this type
        recent_reports = SalesReport.objects.filter(
            period_type=period_type
        ).order_by('-start_date')[:10]
        
        serializer = SalesReportSerializer(recent_reports, many=True)
        
        return Response({
            'current_report': SalesReportSerializer(report).data,
            'recent_reports': serializer.data,
            'period_type': period_type
        })
    
    @action(detail=False, methods=['get'])
    def product_performance(self, request):
        """Get product performance analytics"""
        # Get query parameters
        product_id = request.query_params.get('product_id')
        days = int(request.query_params.get('days', 30))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        if product_id:
            # Get performance for specific product
            try:
                product = Product.objects.get(id=product_id)
                performance = ProductPerformance.generate_for_product(
                    product, start_date, end_date
                )
                return Response(ProductPerformanceSerializer(performance).data)
            except Product.DoesNotExist:
                return Response(
                    {'error': 'Product not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
        else:
            # Get top performing products
            top_products = OrderItem.objects.filter(
                order__order_date__date__gte=start_date,
                order__order_date__date__lte=end_date,
                order__status='completed'
            ).values(
                'product__id',
                'product__name',
                'product__category__name'
            ).annotate(
                total_sales=Sum(F('price') * F('quantity')),
                total_quantity=Sum('quantity'),
                total_orders=Count('order', distinct=True)
            ).order_by('-total_sales')[:20]
            
            return Response({
                'period': f'{days} days',
                'start_date': start_date.strftime('%Y-%m-%d'),
                'end_date': end_date.strftime('%Y-%m-%d'),
                'top_products': list(top_products)
            })
    
    @action(detail=False, methods=['get'])
    def category_performance(self, request):
        """Get category performance analytics"""
        days = int(request.query_params.get('days', 30))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        # Get category performance
        category_stats = OrderItem.objects.filter(
            order__order_date__date__gte=start_date,
            order__order_date__date__lte=end_date,
            order__status='completed'
        ).values(
            'product__category__id',
            'product__category__name'
        ).annotate(
            total_sales=Sum(F('price') * F('quantity')),
            total_quantity=Sum('quantity'),
            total_orders=Count('order', distinct=True),
            unique_products=Count('product', distinct=True)
        ).order_by('-total_sales')
        
        return Response({
            'period': f'{days} days',
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d'),
            'categories': list(category_stats)
        })
    
    @action(detail=False, methods=['get'])
    def revenue_trends(self, request):
        """Get revenue trends over time"""
        period = request.query_params.get('period', 'daily')  # daily, weekly, monthly
        days_back = int(request.query_params.get('days', 30))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days_back)
        
        # Group by period and calculate revenue
        if period == 'daily':
            from django.db.models.functions import TruncDay
            trunc_func = TruncDay
        elif period == 'weekly':
            from django.db.models.functions import TruncWeek
            trunc_func = TruncWeek
        else:  # monthly
            from django.db.models.functions import TruncMonth
            trunc_func = TruncMonth
        
        revenue_data = Order.objects.filter(
            order_date__date__gte=start_date,
            order_date__date__lte=end_date,
            status='completed'
        ).annotate(
            period=trunc_func('order_date')
        ).values('period').annotate(
            revenue=Sum('total_amount'),
            order_count=Count('id')
        ).order_by('period')
        
        # Format data for frontend
        formatted_data = []
        for item in revenue_data:
            formatted_data.append({
                'date': item['period'].strftime('%Y-%m-%d'),
                'revenue': float(item['revenue']),
                'orders': item['order_count']
            })
        
        return Response({
            'period': period,
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d'),
            'data': formatted_data
        })
    
    @action(detail=False, methods=['get'])
    def user_analytics(self, request):
        """Get user analytics and behavior data"""
        days = int(request.query_params.get('days', 30))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        # User registration trends
        new_users = CustomUser.objects.filter(
            date_joined__date__gte=start_date,
            date_joined__date__lte=end_date
        ).extra(
            select={'day': 'date(date_joined)'}
        ).values('day').annotate(
            count=Count('id')
        ).order_by('day')
        
        # Active users (users who placed orders)
        active_users = CustomUser.objects.filter(
            orders__order_date__date__gte=start_date,
            orders__order_date__date__lte=end_date
        ).distinct().count()
        
        # User role distribution
        user_roles = CustomUser.objects.values('role').annotate(
            count=Count('id')
        ).order_by('role')
        
        # Top customers by orders
        top_customers = CustomUser.objects.filter(
            orders__order_date__date__gte=start_date,
            orders__status='completed'
        ).annotate(
            total_orders=Count('orders'),
            total_spent=Sum('orders__total_amount')
        ).order_by('-total_spent')[:10].values(
            'id', 'username', 'role', 'total_orders', 'total_spent'
        )
        
        return Response({
            'period': f'{days} days',
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d'),
            'new_users_trend': list(new_users),
            'active_users': active_users,
            'user_roles': list(user_roles),
            'top_customers': list(top_customers)
        })


class AdminEventLogViewSet(viewsets.ModelViewSet):
    """Admin viewset for analytics event logs"""
    queryset = AnalyticsEvent.objects.all().order_by('-timestamp')
    serializer_class = AnalyticsEventSerializer
    permission_classes = [IsAdmin]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by event type
        event_type = self.request.query_params.get('event_type')
        if event_type:
            queryset = queryset.filter(event_type=event_type)
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(timestamp__date__gte=start_date)
        if end_date:
            queryset = queryset.filter(timestamp__date__lte=end_date)
        
        return queryset 