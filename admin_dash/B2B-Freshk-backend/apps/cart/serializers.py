from rest_framework import serializers
from .models import Cart, CartItem
from apps.products.serializers import ProductSerializer
from apps.products.models import Product

class CartItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        source='product', 
        queryset=Product.objects.all(),
        write_only=True
    )
    subtotal = serializers.DecimalField(
        max_digits=10, 
        decimal_places=3, 
        read_only=True
    )
    
    class Meta:
        model = CartItem
        fields = ['id', 'product', 'product_id', 'quantity', 'subtotal', 'added_at', 'updated_at']
        read_only_fields = ['id', 'added_at', 'updated_at']
    
    def validate_quantity(self, value):
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than 0")
        return value
    
    def validate(self, data):
        # Check if there's enough stock
        product = data.get('product')
        quantity = data.get('quantity', 1)
        
        if product and product.stock_quantity < quantity:
            raise serializers.ValidationError(
                {"quantity": f"Not enough stock. Available: {product.stock_quantity}"}
            )
        return data


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total = serializers.DecimalField(max_digits=12, decimal_places=3, read_only=True)
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=3, read_only=True)
    item_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Cart
        fields = ['id', 'user', 'items', 'total', 'total_amount', 'item_count', 'created_at', 'updated_at']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
