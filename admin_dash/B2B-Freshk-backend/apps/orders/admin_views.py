from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction

from .models import Order, OrderItem, PaymentTransaction
from .serializers import OrderSerializer, OrderItemSerializer, PaymentTransactionSerializer
from apps.users.permissions import IsAdmin


class AdminOrderViewSet(viewsets.ModelViewSet):
    """
    Admin-only order management API
    """
    queryset = Order.objects.all().order_by('-order_date')
    serializer_class = OrderSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'user', 'payment_method']
    search_fields = ['id', 'user__username', 'user__email']
    ordering_fields = ['order_date', 'total_amount', 'status']
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """Update the status of an order"""
        order = self.get_object()
        status_value = request.data.get('status')
        
        if not status_value:
            return Response(
                {"error": "Status is required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        valid_statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned']
        if status_value not in valid_statuses:
            return Response(
                {"error": f"Invalid status. Options: {valid_statuses}"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Use transaction to ensure atomicity when updating inventory
        with transaction.atomic():
            previous_status = order.status
            
            # If order was cancelled and now it's being processed
            if previous_status == 'cancelled' and status_value in ['processing', 'shipped', 'delivered']:
                # Check if there's enough stock
                for item in order.items.all():
                    if item.quantity > item.product.stock_quantity:
                        return Response(
                            {"error": f"Not enough stock for {item.product.name}. Available: {item.product.stock_quantity}"},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                        
                # Reduce inventory when reactivating a cancelled order
                for item in order.items.all():
                    product = item.product
                    product.stock_quantity -= item.quantity
                    product.save()
                    
                    # Create inventory log entry
                    from apps.inventory.models import InventoryLog
                    InventoryLog.objects.create(
                        product=product,
                        change=-item.quantity,
                        reason=f"Order #{order.id} reactivated"
                    )
            
            # If order is being cancelled and was previously in progress
            elif status_value == 'cancelled' and previous_status in ['pending', 'processing']:
                # Return items to inventory
                for item in order.items.all():
                    product = item.product
                    product.stock_quantity += item.quantity
                    product.save()
                    
                    # Create inventory log entry
                    from apps.inventory.models import InventoryLog
                    InventoryLog.objects.create(
                        product=product,
                        change=item.quantity,
                        reason=f"Order #{order.id} cancelled"
                    )
            
            # Update the order status
            order.status = status_value
            order.save(update_fields=['status'])
        
        return Response({
            "status": "success", 
            "message": f"Order status updated from {previous_status} to {status_value}",
            "order": OrderSerializer(order).data
        })


class AdminOrderItemViewSet(viewsets.ModelViewSet):
    """
    Admin-only order item management API
    """
    queryset = OrderItem.objects.all()
    serializer_class = OrderItemSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['order', 'product']
    search_fields = ['order__id', 'product__name']


class AdminPaymentViewSet(viewsets.ModelViewSet):
    """
    Admin-only payment transaction management API
    """
    queryset = PaymentTransaction.objects.all().order_by('-timestamp')
    serializer_class = PaymentTransactionSerializer
    permission_classes = [IsAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['order', 'status', 'payment_method']
    search_fields = ['order__id', 'transaction_id']
    ordering_fields = ['timestamp', 'amount']
    
    @action(detail=True, methods=['post'])
    def update_payment_status(self, request, pk=None):
        """Update the status of a payment transaction"""
        transaction = self.get_object()
        status_value = request.data.get('status')
        
        if not status_value:
            return Response(
                {"error": "Status is required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        valid_statuses = ['pending', 'processing', 'completed', 'failed', 'refunded']
        if status_value not in valid_statuses:
            return Response(
                {"error": f"Invalid status. Options: {valid_statuses}"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Update the payment status
        transaction.status = status_value
        transaction.save(update_fields=['status'])
        
        # If payment is completed, update the order status to processing
        if status_value == 'completed' and transaction.order.status == 'pending':
            transaction.order.status = 'processing'
            transaction.order.save(update_fields=['status'])
        
        # If payment is refunded, update the order status to returned
        elif status_value == 'refunded' and transaction.order.status in ['delivered', 'shipped']:
            transaction.order.status = 'returned'
            transaction.order.save(update_fields=['status'])
        
        return Response({
            "status": "success", 
            "message": f"Payment status updated to {status_value}",
            "transaction": PaymentTransactionSerializer(transaction).data
        }) 