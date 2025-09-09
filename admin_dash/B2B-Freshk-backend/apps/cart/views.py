from rest_framework import viewsets, status, mixins
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Cart, CartItem
from .serializers import CartSerializer, CartItemSerializer
from apps.products.models import Product
from django.shortcuts import get_object_or_404
from django.db import transaction

class CartViewSet(mixins.RetrieveModelMixin,
                 mixins.DestroyModelMixin,
                 viewsets.GenericViewSet):
    """
    ViewSet for managing the shopping cart.
    """
    serializer_class = CartSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Users can only see their own cart
        return Cart.objects.filter(user=self.request.user)
    
    def get_object(self):
        """
        Get the user's cart, creating it if it doesn't exist
        """
        cart, created = Cart.objects.get_or_create(user=self.request.user)
        return cart
    
    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        """
        Add an item to the cart or update its quantity if it already exists
        """
        cart = self.get_object()
        
        # Validate input
        product_id = request.data.get('product_id')
        quantity = int(request.data.get('quantity', 1))
        
        if not product_id:
            return Response(
                {"error": "Product ID is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if quantity < 1:
            return Response(
                {"error": "Quantity must be at least 1"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Get the product
        try:
            product = Product.objects.get(pk=product_id)
        except Product.DoesNotExist:
            return Response(
                {"error": "Product not found"},
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Check stock
        if product.stock_quantity < quantity:
            return Response(
                {"error": f"Not enough stock. Available: {product.stock_quantity}"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Add to cart
        cart_item, created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            defaults={'quantity': quantity}
        )
        
        # If the item already existed, update the quantity
        if not created:
            cart_item.quantity += quantity
            # Check stock again after adding quantities
            if cart_item.quantity > product.stock_quantity:
                return Response(
                    {"error": f"Not enough stock. Available: {product.stock_quantity}"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            cart_item.save()
            
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def remove_item(self, request, pk=None):
        """
        Remove an item from the cart
        """
        cart = self.get_object()
        product_id = request.data.get('product_id')
        
        if not product_id:
            return Response(
                {"error": "Product ID is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            cart_item = CartItem.objects.get(cart=cart, product_id=product_id)
            cart_item.delete()
            serializer = CartSerializer(cart)
            return Response(serializer.data)
        except CartItem.DoesNotExist:
            return Response(
                {"error": "Item not in cart"},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=True, methods=['post'])
    def update_quantity(self, request, pk=None):
        """
        Update the quantity of an item in the cart
        """
        cart = self.get_object()
        product_id = request.data.get('product_id')
        quantity = request.data.get('quantity')
        
        if not product_id or not quantity:
            return Response(
                {"error": "Product ID and quantity are required"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            quantity = int(quantity)
            if quantity < 1:
                return Response(
                    {"error": "Quantity must be at least 1"},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            cart_item = CartItem.objects.get(cart=cart, product_id=product_id)
            
            # Check stock
            if quantity > cart_item.product.stock_quantity:
                return Response(
                    {"error": f"Not enough stock. Available: {cart_item.product.stock_quantity}"},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            cart_item.quantity = quantity
            cart_item.save()
            
            serializer = CartSerializer(cart)
            return Response(serializer.data)
        except CartItem.DoesNotExist:
            return Response(
                {"error": "Item not in cart"},
                status=status.HTTP_404_NOT_FOUND
            )
        except ValueError:
            return Response(
                {"error": "Quantity must be a number"},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=True, methods=['post'])
    def clear(self, request, pk=None):
        """
        Remove all items from the cart
        """
        cart = self.get_object()
        cart.items.all().delete()
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def checkout(self, request, pk=None):
        """
        Convert cart to order
        """
        cart = self.get_object()
        
        # Check if cart is empty
        if cart.items.count() == 0:
            return Response(
                {"error": "Cannot checkout an empty cart"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Check stock for all items
        for item in cart.items.all():
            if item.quantity > item.product.stock_quantity:
                return Response(
                    {
                        "error": f"Not enough stock for {item.product.name}. Available: {item.product.stock_quantity}"
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
                
        # Create order
        with transaction.atomic():
            from apps.orders.models import Order, OrderItem
            
            order = Order.objects.create(
                retailer=request.user,
                total_amount=cart.total
            )
            
            # Create order items
            for cart_item in cart.items.all():
                OrderItem.objects.create(
                    order=order,
                    product=cart_item.product,
                    quantity=cart_item.quantity,
                    price=cart_item.product.price
                )
                
            # Clear the cart
            cart.items.all().delete()
            
        return Response(
            {"message": "Order created successfully", "order_id": order.id},
            status=status.HTTP_201_CREATED
        )
