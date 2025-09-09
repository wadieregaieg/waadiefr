from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from django.db import transaction
from decimal import Decimal

from apps.users.utils import set_user_otp, send_otp_via_sms, is_otp_valid
from apps.products.models import Product, ProductCategory
from apps.orders.models import Order, OrderItem, PaymentTransaction
from apps.cart.models import Cart, CartItem
from apps.users.models import UserAddress
from .serializers import (
    MobileUserSerializer,
    MobileProductSerializer,
    MobileProductCategorySerializer,
    MobileCartSerializer,
    MobileOrderSerializer,
    MobileOrderItemSerializer,
    MobileAddressSerializer,
    PhoneAuthSerializer,
    PhoneVerifySerializer
)

User = get_user_model()


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_current_user(request):
    """Get current authenticated user data"""
    serializer = MobileUserSerializer(request.user)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def phone_auth_request(request):
    """
    Request OTP for phone authentication (login or registration)
    """
    serializer = PhoneAuthSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    phone_number = serializer.validated_data['phone_number']

    # Check if user exists
    user_exists = User.objects.filter(phone_number=phone_number).exists()

    if user_exists:
        # Login flow
        user = User.objects.get(phone_number=phone_number)
        otp = set_user_otp(user)
        send_otp_via_sms(phone_number, otp)
        return Response({
            "message": "OTP sent successfully",
            "is_new_user": False
        }, status=status.HTTP_200_OK)
    else:
        # Registration flow - create a temporary user
        username = f"user_{phone_number.replace('+', '')}"
        user = User.objects.create_user(
            username=username,
            phone_number=phone_number,
            role='retailer',  # Default role for mobile users is retailer
            is_active=False  # Will be activated after verification
        )
        otp = set_user_otp(user)
        send_otp_via_sms(phone_number, otp)
        return Response({
            "message": "OTP sent successfully",
            "is_new_user": True
        }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def phone_auth_verify(request):
    """
    Verify OTP and complete authentication
    """
    serializer = PhoneVerifySerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    phone_number = serializer.validated_data['phone_number']
    otp = serializer.validated_data['otp']

    try:
        user = User.objects.get(phone_number=phone_number)

        if is_otp_valid(user, otp):
            # Mark phone as verified
            user.phone_verified = True

            # If this is a new user, activate them
            if not user.is_active:
                user.is_active = True

            # Clear OTP
            user.otp = None
            user.otp_expiry = None
            user.save(update_fields=['phone_verified',
                      'is_active', 'otp', 'otp_expiry'])

            # Generate tokens
            refresh = RefreshToken.for_user(user)

            # Return user data and tokens
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': MobileUserSerializer(user).data
            }, status=status.HTTP_200_OK)
        else:
            return Response(
                {"error": "Invalid or expired OTP"},
                status=status.HTTP_400_BAD_REQUEST
            )
    except User.DoesNotExist:
        return Response(
            {"error": "No user found with this phone number"},
            status=status.HTTP_404_NOT_FOUND
        )


class MobileProductViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Mobile-optimized product endpoints for retailers to browse supplier products
    """
    serializer_class = MobileProductSerializer
    permission_classes = [permissions.AllowAny]  # Products can be viewed by anyone

    def get_queryset(self):
        # Filter only active products
        queryset = Product.objects.filter(is_active=True)

        # Filter by category if provided
        category_id = self.request.query_params.get('category')
        if category_id:
            queryset = queryset.filter(category_id=category_id)

        # Filter by search term if provided
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(name__icontains=search)

        # Filter by supplier if provided
        supplier_id = self.request.query_params.get('supplier')
        if supplier_id:
            queryset = queryset.filter(supplier_id=supplier_id)

        return queryset

    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Get featured products for the home screen"""
        # For now, just return the most recent products
        products = self.get_queryset().order_by('-created_at')[:10]
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)


class MobileCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """Mobile viewset for product categories"""
    queryset = ProductCategory.objects.all()
    serializer_class = MobileProductCategorySerializer
    permission_classes = [permissions.AllowAny]  # Categories can be viewed by anyone


class MobileAddressViewSet(viewsets.ReadOnlyModelViewSet):
    """Mobile viewset for user addresses"""
    serializer_class = MobileAddressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserAddress.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get'])
    def default(self, request):
        """Get the default address for the user"""
        try:
            default_address = UserAddress.objects.get(
                user=request.user, is_default=True)
            serializer = self.get_serializer(default_address)
            return Response(serializer.data)
        except UserAddress.DoesNotExist:
            return Response(
                {"message": "No default address found"},
                status=status.HTTP_404_NOT_FOUND
            )


class MobileCartViewSet(viewsets.ModelViewSet):
    """Mobile-specific cart operations"""
    serializer_class = MobileCartSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Short-circuit for schema generation
        if getattr(self, 'swagger_fake_view', False):
            return Cart.objects.none()
            
        return Cart.objects.filter(user=self.request.user)

    def get_object(self):
        # Get or create cart for the current user
        cart, created = Cart.objects.get_or_create(user=self.request.user)
        return cart
    
    def list(self, request):
        """Get user's cart - return as single object, not list"""
        cart = self.get_object()
        serializer = self.get_serializer(cart)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def add_item(self, request):
        """Add an item to the cart"""
        cart = self.get_object()
        product_id = request.data.get('product_id')
        quantity = Decimal(request.data.get('quantity', '1.000'))

        try:
            product = Product.objects.get(id=product_id)

            # Check if item already exists in cart
            cart_item, created = CartItem.objects.get_or_create(
                cart=cart,
                product=product,
                defaults={'quantity': quantity}
            )

            if not created:
                # Update quantity if item already exists
                cart_item.quantity += quantity
                cart_item.save()

            # Recalculate cart total
            cart.update_total()

            return Response(self.get_serializer(cart).data)
        except Product.DoesNotExist:
            return Response(
                {"error": "Product not found"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['post'])
    def remove_item(self, request):
        """Remove an item from the cart"""
        cart = self.get_object()
        item_id = request.data.get('item_id')

        try:
            item = CartItem.objects.get(id=item_id, cart=cart)
            item.delete()

            # Recalculate cart total
            cart.update_total()

            return Response(self.get_serializer(cart).data)
        except CartItem.DoesNotExist:
            return Response(
                {"error": "Item not found in cart"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['post'])
    def update_item(self, request):
        """Update item quantity in the cart"""
        cart = self.get_object()
        item_id = request.data.get('item_id')
        quantity = Decimal(request.data.get('quantity', '1.000'))

        try:
            item = CartItem.objects.get(id=item_id, cart=cart)
            item.quantity = quantity
            item.save()

            # Recalculate cart total
            cart.update_total()

            return Response(self.get_serializer(cart).data)
        except CartItem.DoesNotExist:
            return Response(
                {"error": "Item not found in cart"},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['post'])
    @transaction.atomic
    def checkout(self, request):
        """Convert cart to order with transaction safety"""
        cart = self.get_object()

        # Verify user is a retailer
        if self.request.user.role != 'retailer':
            return Response(
                {"error": "Only retailers can place orders"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Check if cart is empty
        if cart.items.count() == 0:
            return Response(
                {"error": "Cannot checkout with empty cart"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if items are in stock
        for cart_item in cart.items.all():
            product = cart_item.product
            quantity_in_product_unit = cart_item.quantity

            if product.stock_quantity < quantity_in_product_unit:
                return Response({
                    "error": f"Not enough stock for {product.name}. Available: {product.stock_quantity} {product.unit}"
                }, status=status.HTTP_400_BAD_REQUEST)

        # Get payment method (default to cash_on_delivery)
        payment_method = request.data.get('payment_method', 'cash_on_delivery')

        # Handle address selection
        address_id = request.data.get('address_id')
        delivery_address = None

        if address_id:
            try:
                user_address = UserAddress.objects.get(
                    id=address_id,
                    user=request.user
                )
                delivery_address = user_address.full_address
            except UserAddress.DoesNotExist:
                return Response({
                    "error": "Selected address not found or doesn't belong to you"
                }, status=status.HTTP_400_BAD_REQUEST)
        else:
            # Try to use default address if no address_id provided
            try:
                default_address = UserAddress.objects.get(
                    user=request.user,
                    is_default=True
                )
                delivery_address = default_address.full_address
            except UserAddress.DoesNotExist:
                return Response({
                    "error": "No address selected and no default address found. Please select an address or set a default address."
                }, status=status.HTTP_400_BAD_REQUEST)

        # Create order
        order = Order.objects.create(
            user=request.user,
            total_amount=cart.total_amount,
            status='pending',
            payment_method=payment_method,
            address=delivery_address,
        )

        # Create order items
        for cart_item in cart.items.all():
            OrderItem.objects.create(
                order=order,
                product=cart_item.product,
                quantity=cart_item.quantity,
                price=cart_item.product.price,
                unit=cart_item.product.unit
            )

        # Create payment transaction
        transaction = PaymentTransaction.objects.create(
            order=order,
            payment_method=payment_method,
            amount=order.total_amount,
            status='pending'
        )

        # Clear cart
        cart.items.all().delete()
        cart.total_amount = 0
        cart.save()

        return Response(
            MobileOrderSerializer(order).data,
            status=status.HTTP_201_CREATED
        )


class MobileOrderViewSet(viewsets.ReadOnlyModelViewSet):
    """Mobile-specific order operations"""
    serializer_class = MobileOrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Order.objects.filter(user=self.request.user).prefetch_related(
            'items__product'
        ).order_by('-order_date')

    def list(self, request, *args, **kwargs):
        """
        List orders. Use ?include_items=false to exclude items from response for better performance
        """
        include_items = request.query_params.get(
            'include_items', 'true').lower() == 'true'

        queryset = self.filter_queryset(self.get_queryset())

        if not include_items:
            # Use a simpler serializer without items for better performance
            from apps.mobile.serializers import MobileOrderSerializer

            class SimpleOrderSerializer(MobileOrderSerializer):
                class Meta(MobileOrderSerializer.Meta):
                    fields = (
                        'id', 'order_date', 'status', 'status_display',
                        'total_amount', 'formatted_total', 'item_count', 'delivery_address'
                    )

            page = self.paginate_queryset(queryset)
            if page is not None:
                serializer = SimpleOrderSerializer(
                    page, many=True, context={'request': request})
                return self.get_paginated_response(serializer.data)

            serializer = SimpleOrderSerializer(
                queryset, many=True, context={'request': request})
            return Response(serializer.data)

        # Default behavior - include items
        return super().list(request, *args, **kwargs)

    @action(detail=False, methods=['get'])
    def items(self, request):
        """Get all order items for the user (mobile app expects this at /api/mobile/orders/items/)"""
        orders = self.get_queryset()
        order_items = OrderItem.objects.filter(order__in=orders).select_related('product').order_by('-order__order_date')
        serializer = MobileOrderItemSerializer(
            order_items, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def order_items(self, request, pk=None):
        """Get items for a specific order"""
        order = self.get_object()
        items = order.items.all().select_related('product')
        serializer = MobileOrderItemSerializer(
            items, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel an order if it's in a cancellable state"""
        order = self.get_object()

        if order.set_status('cancelled'):
            return Response({
                "message": "Order cancelled successfully",
                "order": MobileOrderSerializer(order, context={'request': request}).data
            })
        else:
            return Response({
                "error": f"Cannot cancel order in {order.status} status"
            }, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def detail(self, request, pk=None):
        """Get detailed order information with all items"""
        order = self.get_object()
        serializer = MobileOrderSerializer(order, context={'request': request})
        return Response(serializer.data)


