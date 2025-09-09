from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import AnalyticsEvent, SalesReport, ProductPerformance, CategoryPerformance
from .serializers import (
    AnalyticsEventSerializer, 
    SalesReportSerializer, 
    ProductPerformanceSerializer, 
    CategoryPerformanceSerializer
)
from apps.users.permissions import IsAdmin
from rest_framework.permissions import IsAuthenticated
from apps.products.models import Product, ProductCategory
from django.utils import timezone
from datetime import datetime, timedelta
from django.db.models import Sum, Count, F, Q
from django.db.models.functions import TruncDay, TruncWeek, TruncMonth, TruncYear

class AnalyticsEventViewSet(viewsets.ModelViewSet):
    queryset = AnalyticsEvent.objects.all()
    serializer_class = AnalyticsEventSerializer
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [IsAdmin()]
        # Anyone authenticated can create analytics events
        elif self.action == 'create':
            return [IsAuthenticated()]
        # Only admins can update or delete
        return [IsAdmin()]
    
    def perform_create(self, serializer):
        # Automatically set user_id if authenticated
        if self.request.user and self.request.user.is_authenticated:
            serializer.save(user_id=self.request.user.id)
        else:
            serializer.save()


class SalesReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing sales reports
    """
    queryset = SalesReport.objects.all()
    serializer_class = SalesReportSerializer
    # permission_classes = [IsAdmin]
    
    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate a sales report for the specified period"""
        period_type = request.data.get('period_type', 'monthly')
        start_date_str = request.data.get('start_date')
        end_date_str = request.data.get('end_date')
        
        start_date = None
        end_date = None
        
        if start_date_str:
            try:
                start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response(
                    {"error": "Invalid start_date format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        if end_date_str:
            try:
                end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response(
                    {"error": "Invalid end_date format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        report = SalesReport.generate_report(period_type, start_date, end_date)
        serializer = self.get_serializer(report)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Get dashboard data with key metrics"""
        # Get today's date
        today = timezone.now().date()
        
        # Generate reports for different periods if they don't exist
        daily_report = SalesReport.generate_report('daily', today, today)
        
        # Weekly (current week)
        week_start = today - timedelta(days=today.weekday())
        weekly_report = SalesReport.generate_report('weekly', week_start, today)
        
        # Monthly (current month)
        month_start = today.replace(day=1)
        monthly_report = SalesReport.generate_report('monthly', month_start, today)
        
        # Yearly (current year)
        year_start = today.replace(month=1, day=1)
        yearly_report = SalesReport.generate_report('yearly', year_start, today)
        
        # Serialize all reports
        daily_data = SalesReportSerializer(daily_report).data
        weekly_data = SalesReportSerializer(weekly_report).data
        monthly_data = SalesReportSerializer(monthly_report).data
        yearly_data = SalesReportSerializer(yearly_report).data
        
        # Return combined dashboard data
        return Response({
            'daily': daily_data,
            'weekly': weekly_data,
            'monthly': monthly_data,
            'yearly': yearly_data
        })
    
    @action(detail=False, methods=['get'])
    def trends(self, request):
        """Get sales trends over time"""
        period = request.query_params.get('period', 'monthly')
        months = int(request.query_params.get('months', 12))
        
        # Calculate date range
        end_date = timezone.now().date()
        if period == 'daily':
            start_date = end_date - timedelta(days=30)  # Last 30 days
            trunc_function = TruncDay
            date_field = 'day'
        elif period == 'weekly':
            start_date = end_date - timedelta(weeks=12)  # Last 12 weeks
            trunc_function = TruncWeek
            date_field = 'week'
        elif period == 'yearly':
            start_date = end_date.replace(month=1, day=1) - timedelta(days=365 * 5)  # Last 5 years
            trunc_function = TruncYear
            date_field = 'year'
        else:  # Default to monthly
            start_date = end_date.replace(day=1) - timedelta(days=30 * months)
            trunc_function = TruncMonth
            date_field = 'month'
        
        # Generate reports for each period if they don't exist
        from apps.orders.models import Order
        
        # Query for trend data
        trend_data = (
            Order.objects
            .filter(
                order_date__date__gte=start_date,
                order_date__date__lte=end_date,
                status='completed'
            )
            .annotate(period=trunc_function('order_date'))
            .values('period')
            .annotate(
                total_sales=Sum('total_amount'),
                order_count=Count('id')
            )
            .order_by('period')
        )
        
        # Format the response
        formatted_data = []
        for item in trend_data:
            formatted_data.append({
                'period': item['period'].strftime('%Y-%m-%d'),
                'total_sales': item['total_sales'],
                'order_count': item['order_count']
            })
        
        return Response({
            'period_type': period,
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d'),
            'trend_data': formatted_data
        })


class ProductPerformanceViewSet(viewsets.ModelViewSet):
    queryset = ProductPerformance.objects.all()
    serializer_class = ProductPerformanceSerializer
    # permission_classes = [IsAdmin]
    
    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate performance metrics for a specific product"""
        product_id = request.data.get('product_id')
        start_date_str = request.data.get('start_date')
        end_date_str = request.data.get('end_date')
        
        if not product_id:
            return Response(
                {"error": "product_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            product = Product.objects.get(pk=product_id)
        except Product.DoesNotExist:
            return Response(
                {"error": "Product not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        start_date = None
        end_date = None
        
        if start_date_str:
            try:
                start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response(
                    {"error": "Invalid start_date format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        if end_date_str:
            try:
                end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response(
                    {"error": "Invalid end_date format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        performance = ProductPerformance.generate_for_product(product, start_date, end_date)
        serializer = self.get_serializer(performance)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def top_products(self, request):
        """Get top performing products"""
        period = request.query_params.get('period', 'monthly')
        limit = int(request.query_params.get('limit', 10))
        
        # Calculate date range
        end_date = timezone.now().date()
        if period == 'weekly':
            start_date = end_date - timedelta(weeks=1)
        elif period == 'yearly':
            start_date = end_date - timedelta(days=365)
        else:  # Default to monthly
            start_date = end_date - timedelta(days=30)
        
        # Get top products by sales
        top_products = ProductPerformance.objects.filter(
            period_start__gte=start_date,
            period_end__lte=end_date
        ).order_by('-total_sales')[:limit]
        
        serializer = self.get_serializer(top_products, many=True)
        return Response(serializer.data)


class CategoryPerformanceViewSet(viewsets.ModelViewSet):
    queryset = CategoryPerformance.objects.all()
    serializer_class = CategoryPerformanceSerializer
    # permission_classes = [IsAdmin]
    
    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate performance metrics for a specific category"""
        category_id = request.data.get('category_id')
        start_date_str = request.data.get('start_date')
        end_date_str = request.data.get('end_date')
        
        if not category_id:
            return Response(
                {"error": "category_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            category = ProductCategory.objects.get(pk=category_id)
        except ProductCategory.DoesNotExist:
            return Response(
                {"error": "Category not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        start_date = None
        end_date = None
        
        if start_date_str:
            try:
                start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response(
                    {"error": "Invalid start_date format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        if end_date_str:
            try:
                end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response(
                    {"error": "Invalid end_date format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        performance = CategoryPerformance.generate_for_category(category, start_date, end_date)
        serializer = self.get_serializer(performance)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def category_comparison(self, request):
        """Compare performance across categories"""
        period = request.query_params.get('period', 'monthly')
        
        # Calculate date range
        end_date = timezone.now().date()
        if period == 'weekly':
            start_date = end_date - timedelta(weeks=1)
        elif period == 'yearly':
            start_date = end_date - timedelta(days=365)
        else:  # Default to monthly
            start_date = end_date - timedelta(days=30)
        
        # Get all categories and ensure they have performance data
        categories = ProductCategory.objects.all()
        for category in categories:
            CategoryPerformance.generate_for_category(category, start_date, end_date)
        
        # Get performance data for all categories
        category_performances = CategoryPerformance.objects.filter(
            period_start__gte=start_date,
            period_end__lte=end_date
        ).order_by('-total_sales')
        
        serializer = self.get_serializer(category_performances, many=True)
        return Response(serializer.data)
