from rest_framework import viewsets, status
from .models import Order, OrderItem, PaymentTransaction
from .serializers import OrderSerializer, OrderItemSerializer, PaymentTransactionSerializer
from apps.users.permissions import IsAdmin, IsAdminOrRetailer, IsOwnerOrAdmin
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from apps.products.models import Product
from rest_framework import serializers
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
import logging

logger = logging.getLogger(__name__)

class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['status', 'order_date']
    ordering_fields = ['order_date', 'total_amount']
    
    def get_permissions(self):
        if self.action in ['create']:
            return [IsAdminOrRetailer()]
        elif self.action in ['update', 'partial_update', 'destroy']:
            return [IsAdmin()]
        return [IsAuthenticated()]
    
    def get_queryset(self):
        # Admins see all orders, non-admins see only their own
        if self.request.user.is_staff:
            return Order.objects.all()
        return Order.objects.filter(user=self.request.user)
    
    def create(self, request, *args, **kwargs):
        """Enhanced create method with better error handling"""
        logger.info(f"Order creation request from user {request.user.id}: {request.data}")
        
        try:
            # Log the request data for debugging
            logger.info(f"Request data: {request.data}")
            
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            
            logger.info(f"Serializer validated data: {serializer.validated_data}")
            
            # Create the order
            order = serializer.save()
            
            logger.info(f"Order created successfully: {order.id}")
            
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except serializers.ValidationError as e:
            logger.error(f"Validation error creating order: {e}")
            return Response(e.detail, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Unexpected error creating order: {str(e)}")
            logger.error(f"Request data: {request.data}")
            return Response(
                {"error": f"Failed to create order: {str(e)}"}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def perform_create(self, serializer):
        # Do not override user; use the user from the payload
        serializer.save()
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """
        Cancel an order if it's in 'pending' status
        """
        order = self.get_object()
        if order.status != 'pending':
            return Response(
                {"error": "Only pending orders can be cancelled."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update order status to cancelled
        order.status = 'cancelled'
        order.save()
        
        # Return updated order
        serializer = self.get_serializer(order)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """
        Mark an order as complete and update inventory
        """
        order = self.get_object()
        if order.status != 'pending':
            return Response(
                {"error": "Only pending orders can be completed."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Use transaction to ensure atomicity
        with transaction.atomic():
            # Update order status
            order.status = 'completed'
            order.save()
            
            # Update inventory for each item
            for item in order.items.all():
                product = item.product
                product.stock_quantity -= item.quantity
                product.save()
                
                # Create inventory log entry
                from apps.inventory.models import InventoryLog
                InventoryLog.objects.create(
                    product=product,
                    change=-item.quantity,
                    reason=f"Order #{order.id} completion"
                )
        
        # Return updated order
        serializer = self.get_serializer(order)
        return Response(serializer.data)

    def destroy(self, request, *args, **kwargs):
        """Delete an order only if it's in pending status"""
        order = self.get_object()
        
        # Check if user owns the order (unless admin)
        if not request.user.is_staff and order.user != request.user:
            return Response(
                {"error": "You don't have permission to delete this order."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Check if order can be deleted (only pending orders)
        if order.status != 'pending':
            return Response(
                {"error": "Only pending orders can be deleted."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Use transaction to ensure atomicity
        with transaction.atomic():
            # Restore product stock for each item before deleting
            for item in order.items.all():
                product = item.product
                
                # Convert units if necessary
                quantity_in_product_unit = item.quantity
                if product.unit != item.unit:
                    if item.unit == 'kg' and product.unit == 'ton':
                        quantity_in_product_unit = item.quantity / 1000
                    elif item.unit == 'ton' and product.unit == 'kg':
                        quantity_in_product_unit = item.quantity * 1000
                
                # Restore stock
                product.stock_quantity += quantity_in_product_unit
                product.save(update_fields=['stock_quantity', 'updated_at'])
                
                # Create inventory log entry
                from apps.inventory.models import InventoryLog
                InventoryLog.objects.create(
                    product=product,
                    change=quantity_in_product_unit,
                    reason=f"Order #{order.id} deletion - stock restored"
                )
            
            # Delete the order (this will cascade delete order items)
            order.delete()
        
        return Response(status=status.HTTP_204_NO_CONTENT)


class OrderItemViewSet(viewsets.ModelViewSet):
    queryset = OrderItem.objects.all()
    serializer_class = OrderItemSerializer
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['order', 'product']
    ordering_fields = ['price', 'quantity']
    
    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminOrRetailer()]
        return [IsAuthenticated()]
    
    def get_queryset(self):
        # Admin can see all order items, retailers can only see their own
        if self.request.user.role == 'admin':
            return OrderItem.objects.all()
        return OrderItem.objects.filter(order__user=self.request.user)
    
    def perform_create(self, serializer):
        # Get the product price at the time of ordering
        product = serializer.validated_data['product']
        quantity = serializer.validated_data['quantity']
        
        # Check if there's enough stock
        if product.stock_quantity < quantity:
            raise serializers.ValidationError(
                {"quantity": f"Not enough stock. Available: {product.stock_quantity}"}
            )
        
        # Save with the current product price
        serializer.save(price=product.price)


class PaymentTransactionViewSet(viewsets.ModelViewSet):
    queryset = PaymentTransaction.objects.all()
    serializer_class = PaymentTransactionSerializer
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['order', 'payment_method', 'status']
    ordering_fields = ['timestamp', 'amount']
    
    def get_permissions(self):
        if self.action in ['create']:
            return [IsAdminOrRetailer()]
        elif self.action in ['update', 'partial_update', 'destroy']:
            return [IsAdmin()]
        return [IsAuthenticated()]
    
    def get_queryset(self):
        # Admin can see all transactions, retailers can only see their own
        if self.request.user.role == 'admin':
            return PaymentTransaction.objects.all()
        return PaymentTransaction.objects.filter(order__user=self.request.user)
