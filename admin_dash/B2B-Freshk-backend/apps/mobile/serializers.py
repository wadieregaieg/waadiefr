from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.products.models import Product, ProductCategory
from apps.orders.models import Order, OrderItem
from apps.cart.models import Cart, CartItem
from apps.products.fields import Base64ImageField
from apps.users.models import UserAddress


User = get_user_model()


class MobileUserSerializer(serializers.ModelSerializer):
    """Simplified user serializer for mobile app"""
    class Meta:
        model = User
        fields = ('id', 'username', 'phone_number', 'phone_verified', 'role')
        read_only_fields = ('id', 'username', 'phone_verified', 'role')


class MobileAddressSerializer(serializers.ModelSerializer):
    """Simplified address serializer for mobile app"""
    class Meta:
        model = UserAddress
        fields = ('id', 'address_type', 'street_address', 'city', 'state',
                  'postal_code', 'country', 'is_default', 'full_address')
        read_only_fields = ('full_address',)


class MobileProductCategorySerializer(serializers.ModelSerializer):
    """Simplified category serializer for mobile app"""
    product_count = serializers.SerializerMethodField()

    class Meta:
        model = ProductCategory
        fields = ('id', 'name', 'description', 'product_count')

    def get_product_count(self, obj):
        return obj.products.filter(is_active=True).count()


class MobileProductSerializer(serializers.ModelSerializer):
    """Simplified product serializer for mobile app"""
    category_name = serializers.ReadOnlyField(source='category.name')
    formatted_price = serializers.SerializerMethodField()
    image = Base64ImageField(read_only=True)


    class Meta:
        model = Product
        fields = (
            'id', 'name', 'description', 'price', 'formatted_price',
            'stock_quantity', 'category', 'category_name', 'image'
        )

    def get_formatted_price(self, obj):
        # Format price with TND currency
        return f"{obj.price} TND"

    def get_image(self, obj):
        """Safely get product image URL"""
        try:
            if obj.image and hasattr(obj.image, 'url'):
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(obj.image.url)
                return obj.image.url
        except (AttributeError, ValueError):
            pass
        return None


class MobileCartItemSerializer(serializers.ModelSerializer):
    """Simplified cart item serializer for mobile app"""
    product = MobileProductSerializer(read_only=True)
    item_total = serializers.SerializerMethodField()

    class Meta:
        model = CartItem
        fields = ('id', 'product', 'quantity', 'item_total')

    def get_item_total(self, obj):
        return obj.quantity * obj.product.price


class MobileCartSerializer(serializers.ModelSerializer):
    """Simplified cart serializer for mobile app"""
    items = MobileCartItemSerializer(many=True, read_only=True)
    item_count = serializers.SerializerMethodField()
    formatted_total = serializers.SerializerMethodField()

    class Meta:
        model = Cart
        fields = ('id', 'items', 'total_amount',
                  'formatted_total', 'item_count')

    def get_item_count(self, obj):
        return obj.items.count()

    def get_formatted_total(self, obj):
        return f"{obj.total_amount} TND"


class MobileOrderItemSerializer(serializers.ModelSerializer):
    """Simplified order item serializer for mobile app"""
    product_name = serializers.ReadOnlyField(source='product.name')
    product_image = serializers.SerializerMethodField()
    item_total = serializers.SerializerMethodField()
    formatted_price = serializers.SerializerMethodField()
    formatted_total = serializers.SerializerMethodField()

    class Meta:
        model = OrderItem
        fields = ('id', 'product_id', 'product_name', 'product_image',
                  'quantity', 'price', 'formatted_price', 'unit',
                  'item_total', 'formatted_total')

    def get_product_image(self, obj):
        """Safely get product image URL"""
        try:
            if obj.product.image and hasattr(obj.product.image, 'url'):
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(obj.product.image.url)
                return obj.product.image.url
        except (AttributeError, ValueError):
            pass
        return None

    def get_item_total(self, obj):
        return obj.quantity * obj.price

    def get_formatted_price(self, obj):
        return f"{obj.price} TND"

    def get_formatted_total(self, obj):
        return f"{obj.quantity * obj.price} TND"


class MobileOrderSerializer(serializers.ModelSerializer):
    """Simplified order serializer for mobile app"""
    items = MobileOrderItemSerializer(many=True, read_only=True)
    item_count = serializers.SerializerMethodField()
    formatted_total = serializers.SerializerMethodField()
    status_display = serializers.SerializerMethodField()
    delivery_address = serializers.ReadOnlyField(source='address')

    class Meta:
        model = Order
        fields = (
            'id', 'order_date', 'status', 'status_display',
            'total_amount', 'formatted_total', 'item_count',
            'delivery_address', 'items'
        )

    def get_item_count(self, obj):
        return obj.items.count()

    def get_formatted_total(self, obj):
        return f"{obj.total_amount} TND"

    def get_status_display(self, obj):
        return dict(Order.ORDER_STATUS_CHOICES).get(obj.status, obj.status)


class PhoneAuthSerializer(serializers.Serializer):
    """Serializer for phone authentication request"""
    phone_number = serializers.CharField(required=True)


class PhoneVerifySerializer(serializers.Serializer):
    """Serializer for phone verification"""
    phone_number = serializers.CharField(required=True)
    otp = serializers.CharField(required=True)


class ProductionProductSerializer(serializers.ModelSerializer):
    """Serializer for production-related product data, including image uploads"""
    image = Base64ImageField(required=False, allow_null=True)

    class Meta:
        model = Product
        fields = (
            'id', 'name', 'description', 'price',
            'stock_quantity', 'category', 'image'
        )
        read_only_fields = ('id',)
