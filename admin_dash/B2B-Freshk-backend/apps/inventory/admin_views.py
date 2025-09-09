from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta

from .models import InventoryLog
from .serializers import InventoryLogSerializer
from apps.users.permissions import IsAdmin
from apps.products.models import Product


class AdminInventoryLogViewSet(viewsets.ModelViewSet):
    """
    Admin-only inventory log management API
    """
    serializer_class = InventoryLogSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['product', 'change', 'reason']
    search_fields = ['product__name', 'reason']
    ordering_fields = ['timestamp', 'change']
    
    queryset = InventoryLog.objects.all().select_related('product').order_by('-timestamp')
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get inventory summary statistics"""
        # Time period selection
        period = request.query_params.get('period', 'week')
        
        if period == 'day':
            start_date = timezone.now() - timedelta(days=1)
        elif period == 'month':
            start_date = timezone.now() - timedelta(days=30)
        elif period == 'year':
            start_date = timezone.now() - timedelta(days=365)
        else:  # default to week
            start_date = timezone.now() - timedelta(days=7)
        
        # Get aggregated stats
        stats = InventoryLog.objects.filter(
            timestamp__gte=start_date
        ).aggregate(
            total_changes=Count('id'),
            total_increase=Sum('change', filter=Q(change__gt=0)),
            total_decrease=Sum('change', filter=Q(change__lt=0))
        )
        
        # Handle None values
        if stats['total_increase'] is None:
            stats['total_increase'] = 0
        if stats['total_decrease'] is None:
            stats['total_decrease'] = 0
        
        # Add net change
        stats['net_change'] = stats['total_increase'] + stats['total_decrease']
        
        # Get top products with inventory changes
        top_products = InventoryLog.objects.filter(
            timestamp__gte=start_date
        ).values(
            'product__id', 
            'product__name'
        ).annotate(
            total_changes=Count('id'),
            net_change=Sum('change')
        ).order_by('-total_changes')[:5]
        
        return Response({
            'period': period,
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': timezone.now().strftime('%Y-%m-%d'),
            'statistics': stats,
            'top_products': top_products
        })


class AdminStockAlertViewSet(viewsets.ViewSet):
    """
    Admin-only stock alert management API
    """
    permission_classes = [IsAdmin]
    
    def list(self, request):
        """List products with low stock"""
        threshold = int(request.query_params.get('threshold', 10))
        
        # Find products with low stock
        low_stock_products = Product.objects.filter(
            stock_quantity__lte=threshold,
            is_active=True
        ).select_related('category', 'supplier').order_by('stock_quantity')
        
        # Format response
        result = []
        for product in low_stock_products:
            result.append({
                'id': product.id,
                'name': product.name,
                'sku': product.sku,
                'stock_quantity': product.stock_quantity,
                'unit': product.unit,
                'category': product.category.name if product.category else None,
                'supplier': product.supplier.company_name if product.supplier else None,
                'status': 'critical' if product.stock_quantity <= threshold/2 else 'warning'
            })
        
        return Response({
            'threshold': threshold,
            'total_alerts': len(result),
            'products': result
        })
    
    @action(detail=False, methods=['post'])
    def adjust_stock(self, request):
        """Adjust stock for multiple products in a batch"""
        products_data = request.data.get('products', [])
        
        if not products_data:
            return Response(
                {"error": "No products provided"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        results = []
        errors = []
        
        for item in products_data:
            product_id = item.get('product_id')
            quantity = item.get('quantity')
            reason = item.get('reason', 'Admin stock adjustment')
            
            if not product_id or quantity is None:
                errors.append({
                    "error": "Both product_id and quantity are required",
                    "data": item
                })
                continue
                
            try:
                product = Product.objects.get(pk=product_id)
                
                # Calculate change
                previous_quantity = product.stock_quantity
                change = float(quantity) - previous_quantity
                
                # Update product stock
                product.stock_quantity = quantity
                product.save(update_fields=['stock_quantity', 'updated_at'])
                
                # Create inventory log
                log = InventoryLog.objects.create(
                    product=product,
                    change=change,
                    reason=reason
                )
                
                results.append({
                    "product_id": product_id,
                    "name": product.name,
                    "previous_quantity": previous_quantity,
                    "new_quantity": product.stock_quantity,
                    "change": change
                })
                
            except Product.DoesNotExist:
                errors.append({
                    "error": f"Product with ID {product_id} not found",
                    "data": item
                })
            except ValueError:
                errors.append({
                    "error": "Invalid quantity value",
                    "data": item
                })
        
        return Response({
            "success": len(results) > 0,
            "results": results,
            "errors": errors
        }) 