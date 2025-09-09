from django.db import models
import json
from django.utils import timezone
from django.db.models import Sum, Avg, Count, F, ExpressionWrapper, DecimalField
from django.db.models.functions import TruncDay, TruncWeek, TruncMonth, TruncYear
from apps.orders.models import Order, OrderItem
from apps.products.models import Product, ProductCategory
from apps.users.models import CustomUser

class AnalyticsEvent(models.Model):
    EVENT_TYPE_CHOICES = (
        ('view', 'Product View'),
        ('click', 'Click'),
        ('order', 'Order Placement'),
        ('search', 'Search'),
        ('cart_add', 'Add to Cart'),
        ('cart_remove', 'Remove from Cart'),
        ('checkout', 'Checkout'),
        ('payment', 'Payment'),
    )
    event_type = models.CharField(max_length=50, choices=EVENT_TYPE_CHOICES)
    user_id = models.IntegerField(null=True, blank=True, help_text="Reference to the CustomUser id if available")
    timestamp = models.DateTimeField(auto_now_add=True)
    metadata = models.JSONField(blank=True, null=True, help_text="Additional data as JSON")

    def __str__(self):
        return f"{self.event_type} event at {self.timestamp}"
    
    class Meta:
        indexes = [
            models.Index(fields=['event_type']),
            models.Index(fields=['user_id']),
            models.Index(fields=['timestamp']),
        ]


class SalesReport(models.Model):
    """Model to store pre-calculated sales reports"""
    PERIOD_CHOICES = (
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('yearly', 'Yearly'),
    )
    period_type = models.CharField(max_length=10, choices=PERIOD_CHOICES)
    start_date = models.DateField()
    end_date = models.DateField()
    total_sales = models.DecimalField(max_digits=12, decimal_places=3, default=0)
    total_orders = models.IntegerField(default=0)
    total_quantity_kg = models.DecimalField(max_digits=12, decimal_places=3, default=0)
    average_order_value = models.DecimalField(max_digits=12, decimal_places=3, default=0)
    total_profit = models.DecimalField(max_digits=12, decimal_places=3, default=0, null=True, blank=True)
    profit_margin = models.DecimalField(max_digits=5, decimal_places=2, default=0, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['period_type', 'start_date', 'end_date']
        ordering = ['-start_date']
        indexes = [
            models.Index(fields=['period_type']),
            models.Index(fields=['start_date']),
            models.Index(fields=['end_date']),
        ]
    
    def __str__(self):
        return f"{self.get_period_type_display()} Report: {self.start_date} to {self.end_date}"
    
    @classmethod
    def generate_report(cls, period_type, start_date=None, end_date=None):
        """Generate a sales report for the specified period"""
        if not start_date:
            # Default to appropriate period if not specified
            today = timezone.now().date()
            if period_type == 'daily':
                start_date = today
                end_date = today
            elif period_type == 'weekly':
                # Start from the beginning of the current week
                start_date = today - timezone.timedelta(days=today.weekday())
                end_date = today
            elif period_type == 'monthly':
                # Start from the beginning of the current month
                start_date = today.replace(day=1)
                end_date = today
            elif period_type == 'yearly':
                # Start from the beginning of the current year
                start_date = today.replace(month=1, day=1)
                end_date = today
        
        if not end_date:
            end_date = timezone.now().date()
        
        # Query orders for the period
        orders = Order.objects.filter(
            order_date__date__gte=start_date,
            order_date__date__lte=end_date,
            status='completed'  # Only count completed orders
        )
        
        # Calculate metrics
        total_sales = orders.aggregate(total=Sum('total_amount'))['total'] or 0
        total_orders = orders.count()
        
        # Calculate total quantity in kg
        order_items = OrderItem.objects.filter(order__in=orders)
        total_quantity_kg = 0
        for item in order_items:
            if item.unit == 'ton':
                total_quantity_kg += item.quantity * 1000
            else:
                total_quantity_kg += item.quantity
        
        # Calculate average order value
        average_order_value = total_sales / total_orders if total_orders > 0 else 0
        
        # Calculate profit if cost_price is available
        total_profit = 0
        items_with_cost = order_items.exclude(cost_price__isnull=True)
        for item in items_with_cost:
            total_profit += (item.price - item.cost_price) * item.quantity
        
        # Calculate profit margin
        profit_margin = (total_profit / total_sales * 100) if total_sales > 0 else 0
        
        # Create or update the report
        report, created = cls.objects.update_or_create(
            period_type=period_type,
            start_date=start_date,
            end_date=end_date,
            defaults={
                'total_sales': total_sales,
                'total_orders': total_orders,
                'total_quantity_kg': total_quantity_kg,
                'average_order_value': average_order_value,
                'total_profit': total_profit,
                'profit_margin': profit_margin,
            }
        )
        
        return report


class ProductPerformance(models.Model):
    """Model to track product performance metrics"""
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='performance_metrics')
    period_start = models.DateField()
    period_end = models.DateField()
    total_sales = models.DecimalField(max_digits=12, decimal_places=3, default=0)
    total_quantity_sold_kg = models.DecimalField(max_digits=12, decimal_places=3, default=0)
    total_orders = models.IntegerField(default=0)
    profit = models.DecimalField(max_digits=12, decimal_places=3, default=0, null=True, blank=True)
    profit_margin = models.DecimalField(max_digits=5, decimal_places=2, default=0, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['product', 'period_start', 'period_end']
        ordering = ['-period_start', 'product']
        indexes = [
            models.Index(fields=['product']),
            models.Index(fields=['period_start']),
            models.Index(fields=['period_end']),
            models.Index(fields=['total_sales']),
        ]
    
    def __str__(self):
        return f"{self.product.name} Performance: {self.period_start} to {self.period_end}"
    
    @classmethod
    def generate_for_product(cls, product, start_date=None, end_date=None):
        """Generate performance metrics for a specific product"""
        if not start_date:
            # Default to the last 30 days
            end_date = timezone.now().date()
            start_date = end_date - timezone.timedelta(days=30)
        
        if not end_date:
            end_date = timezone.now().date()
        
        # Query order items for this product in the period
        order_items = OrderItem.objects.filter(
            product=product,
            order__order_date__date__gte=start_date,
            order__order_date__date__lte=end_date,
            order__status='completed'  # Only count completed orders
        )
        
        # Calculate metrics
        total_sales = order_items.aggregate(
            total=Sum(F('price') * F('quantity'))
        )['total'] or 0
        
        total_orders = order_items.values('order').distinct().count()
        
        # Calculate total quantity in kg
        total_quantity_kg = 0
        for item in order_items:
            if item.unit == 'ton':
                total_quantity_kg += item.quantity * 1000
            else:
                total_quantity_kg += item.quantity
        
        # Calculate profit if cost_price is available
        total_profit = 0
        items_with_cost = order_items.exclude(cost_price__isnull=True)
        for item in items_with_cost:
            total_profit += (item.price - item.cost_price) * item.quantity
        
        # Calculate profit margin
        profit_margin = (total_profit / total_sales * 100) if total_sales > 0 else 0
        
        # Create or update the performance record
        performance, created = cls.objects.update_or_create(
            product=product,
            period_start=start_date,
            period_end=end_date,
            defaults={
                'total_sales': total_sales,
                'total_quantity_sold_kg': total_quantity_kg,
                'total_orders': total_orders,
                'profit': total_profit,
                'profit_margin': profit_margin,
            }
        )
        
        return performance


class CategoryPerformance(models.Model):
    """Model to track category performance metrics"""
    category = models.ForeignKey(ProductCategory, on_delete=models.CASCADE, related_name='performance_metrics')
    period_start = models.DateField()
    period_end = models.DateField()
    total_sales = models.DecimalField(max_digits=12, decimal_places=3, default=0)
    total_quantity_sold_kg = models.DecimalField(max_digits=12, decimal_places=3, default=0)
    total_orders = models.IntegerField(default=0)
    profit = models.DecimalField(max_digits=12, decimal_places=3, default=0, null=True, blank=True)
    profit_margin = models.DecimalField(max_digits=5, decimal_places=2, default=0, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['category', 'period_start', 'period_end']
        ordering = ['-period_start', 'category']
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['period_start']),
            models.Index(fields=['period_end']),
            models.Index(fields=['total_sales']),
        ]
    
    def __str__(self):
        return f"{self.category.name} Performance: {self.period_start} to {self.period_end}"
    
    @classmethod
    def generate_for_category(cls, category, start_date=None, end_date=None):
        """Generate performance metrics for a specific category"""
        if not start_date:
            # Default to the last 30 days
            end_date = timezone.now().date()
            start_date = end_date - timezone.timedelta(days=30)
        
        if not end_date:
            end_date = timezone.now().date()
        
        # Query order items for products in this category in the period
        order_items = OrderItem.objects.filter(
            product__category=category,
            order__order_date__date__gte=start_date,
            order__order_date__date__lte=end_date,
            order__status='completed'  # Only count completed orders
        )
        
        # Calculate metrics
        total_sales = order_items.aggregate(
            total=Sum(F('price') * F('quantity'))
        )['total'] or 0
        
        total_orders = order_items.values('order').distinct().count()
        
        # Calculate total quantity in kg
        total_quantity_kg = 0
        for item in order_items:
            if item.unit == 'ton':
                total_quantity_kg += item.quantity * 1000
            else:
                total_quantity_kg += item.quantity
        
        # Calculate profit if cost_price is available
        total_profit = 0
        items_with_cost = order_items.exclude(cost_price__isnull=True)
        for item in items_with_cost:
            total_profit += (item.price - item.cost_price) * item.quantity
        
        # Calculate profit margin
        profit_margin = (total_profit / total_sales * 100) if total_sales > 0 else 0
        
        # Create or update the performance record
        performance, created = cls.objects.update_or_create(
            category=category,
            period_start=start_date,
            period_end=end_date,
            defaults={
                'total_sales': total_sales,
                'total_quantity_sold_kg': total_quantity_kg,
                'total_orders': total_orders,
                'profit': total_profit,
                'profit_margin': profit_margin,
            }
        )
        
        return performance
