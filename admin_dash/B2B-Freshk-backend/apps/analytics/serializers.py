from rest_framework import serializers
from .models import AnalyticsEvent, SalesReport, ProductPerformance, CategoryPerformance
from apps.products.serializers import ProductSerializer, ProductCategorySerializer

class AnalyticsEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = AnalyticsEvent
        fields = '__all__'


class SalesReportSerializer(serializers.ModelSerializer):
    period_type_display = serializers.CharField(source='get_period_type_display', read_only=True)
    
    class Meta:
        model = SalesReport
        fields = [
            'id', 'period_type', 'period_type_display', 'start_date', 'end_date',
            'total_sales', 'total_orders', 'total_quantity_kg', 'average_order_value',
            'total_profit', 'profit_margin', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class ProductPerformanceSerializer(serializers.ModelSerializer):
    product_details = ProductSerializer(source='product', read_only=True)
    
    class Meta:
        model = ProductPerformance
        fields = [
            'id', 'product', 'product_details', 'period_start', 'period_end',
            'total_sales', 'total_quantity_sold_kg', 'total_orders',
            'profit', 'profit_margin', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class CategoryPerformanceSerializer(serializers.ModelSerializer):
    category_details = ProductCategorySerializer(source='category', read_only=True)
    
    class Meta:
        model = CategoryPerformance
        fields = [
            'id', 'category', 'category_details', 'period_start', 'period_end',
            'total_sales', 'total_quantity_sold_kg', 'total_orders',
            'profit', 'profit_margin', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
