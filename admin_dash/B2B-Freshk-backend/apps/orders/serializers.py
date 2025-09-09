from rest_framework import serializers
from .models import Order, OrderItem, PaymentTransaction
from decimal import Decimal
import logging

logger = logging.getLogger(__name__)

class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'quantity', 'unit', 'price', 'cost_price']
        extra_kwargs = {
            'price': {'required': False},  # Will use product price if not provided
            'cost_price': {'required': False},  # Optional field for analytics
            'unit': {'required': False},  # Will use product unit if not provided
        }

    def validate(self, data):
        """Validate order item data and set defaults"""
        product = data.get('product')
        if product:
            # Set unit to product's unit if not provided
            if 'unit' not in data or not data['unit']:
                data['unit'] = product.unit
            
            # Set price to product's price if not provided
            if 'price' not in data or not data['price']:
                data['price'] = product.price
                
        return data


class OrderSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    retailer_name = serializers.SerializerMethodField(read_only=True)
    customer_name = serializers.SerializerMethodField(read_only=True)
    company_name = serializers.SerializerMethodField(read_only=True)
    items = OrderItemSerializer(many=True)
    
    # Make these fields read-only since they're auto-calculated
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=3, required=False)
    order_date = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)
    shipping_address = serializers.CharField(source='address', required=False, allow_blank=True)

    class Meta:
        model = Order
        fields = [
            'id', 'user', 'username', 'retailer_name', 'customer_name', 'company_name', 
            'order_date', 'status', 'payment_method', 'total_amount', 'notes', 
            'shipping_address', 'updated_at', 'profit_margin', 'items'
        ]
        extra_kwargs = {
            'status': {'default': 'pending'},
            'payment_method': {'default': 'cash_on_delivery'},
            'total_amount': {'required': False},
            'profit_margin': {'required': False},
        }
        read_only_fields = ('id', 'order_date', 'updated_at')

    def get_retailer_name(self, obj):
        """Get the retailer's display name"""
        user = obj.user
        
        # Try to get full name first (from AbstractUser fields)
        if hasattr(user, 'first_name') and hasattr(user, 'last_name'):
            full_name = f"{user.first_name} {user.last_name}".strip()
            if full_name and full_name != " ":
                return full_name
        
        # Try retailer profile company name as person name
        try:
            if hasattr(user, 'retailer_profile') and user.retailer_profile:
                # If company name looks like a person name, use it
                company_name = user.retailer_profile.company_name
                if company_name and not any(word in company_name.lower() for word in ['ltd', 'inc', 'corp', 'llc', 'company', 'store', 'market']):
                    return company_name
        except:
            pass
            
        # Fall back to username but make it more readable
        username = user.username
        # Convert username like "khchin" to "Khchin" for better display
        return username.title() if username else f"Customer {user.id}"

    def get_customer_name(self, obj):
        """Get customer name for display - same as retailer_name"""
        return self.get_retailer_name(obj)

    def get_company_name(self, obj):
        """Get the company name from the related retailer profile, if it exists"""
        try:
            if hasattr(obj.user, 'retailer_profile') and obj.user.retailer_profile:
                company_name = obj.user.retailer_profile.company_name
                if company_name:
                    return company_name
        except:
            pass
        
        # If no retailer profile, create a business name from user info
        user = obj.user
        if hasattr(user, 'first_name') and hasattr(user, 'last_name'):
            full_name = f"{user.first_name} {user.last_name}".strip()
            if full_name and full_name != " ":
                return f"{full_name} Business"
        
        # Last resort: use username
        username = user.username.title() if user.username else f"User{user.id}"
        return f"{username} Business"

    def validate(self, data):
        """Validate order data and stock availability"""
        items_data = data.get('items', [])
        
        if not items_data:
            raise serializers.ValidationError({'items': 'At least one item is required'})
            
        # Validate each item has required fields and check stock availability
        for i, item_data in enumerate(items_data):
            if 'product' not in item_data:
                raise serializers.ValidationError({f'items[{i}].product': 'Product is required'})
            if 'quantity' not in item_data or not item_data['quantity']:
                raise serializers.ValidationError({f'items[{i}].quantity': 'Quantity is required'})
            
            # Check stock availability
            product = item_data['product']
            requested_qty = float(item_data['quantity'])
            
            if product.stock_quantity < requested_qty:
                raise serializers.ValidationError({
                    f'items[{i}].quantity': f"Insufficient stock for {product.name}. Available: {product.stock_quantity}, Requested: {requested_qty}"
                })
                
        return data

    def validate_shipping_address(self, value):
        """Validate shipping address if provided"""
        if value and len(value.strip()) < 6:
            raise serializers.ValidationError("Shipping address must be at least 10 characters long.")
        return value

    def create(self, validated_data):
        """Create order with nested items"""
        try:
            logger.info(f"Creating order with data: {validated_data}")
            
            items_data = validated_data.pop('items', [])
            
            # Calculate total amount if not provided
            if 'total_amount' not in validated_data or not validated_data['total_amount']:
                total = Decimal('0.000')
                for item_data in items_data:
                    product = item_data['product']
                    quantity = Decimal(str(item_data['quantity']))
                    price = item_data.get('price') or product.price
                    total += quantity * Decimal(str(price))
                validated_data['total_amount'] = total
                logger.info(f"Calculated total amount: {total}")
            
            # Create the order
            order = Order.objects.create(**validated_data)
            logger.info(f"Order created with ID: {order.id}")
            
            # Create order items
            for item_data in items_data:
                product = item_data['product']
                
                # Ensure price is set
                if 'price' not in item_data:
                    item_data['price'] = product.price
                    
                # Ensure unit is set
                if 'unit' not in item_data:
                    item_data['unit'] = product.unit
                
                # Create the order item normally - let the model handle stock updates
                order_item = OrderItem.objects.create(order=order, **item_data)
                logger.info(f"Created order item: {order_item}")
            
            # Refresh order to get updated total and items
            order.refresh_from_db()
            return order
            
        except Exception as e:
            logger.error(f"Error creating order: {str(e)}")
            logger.error(f"Validated data: {validated_data}")
            raise serializers.ValidationError(f"Failed to create order: {str(e)}")

    def update(self, instance, validated_data):
        """Update order with nested items"""
        items_data = validated_data.pop('items', None)
        
        # Update order fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update items if provided
        if items_data is not None:
            # Clear existing items
            instance.items.all().delete()
            
            # Create new items
            for item_data in items_data:
                product = item_data['product']
                if 'price' not in item_data:
                    item_data['price'] = product.price
                if 'unit' not in item_data:
                    item_data['unit'] = product.unit
                OrderItem.objects.create(order=instance, **item_data)
            
            # Recalculate total
            total = sum(item.subtotal for item in instance.items.all())
            instance.total_amount = total
            instance.save()
        
        return instance


class PaymentTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentTransaction
        fields = '__all__'
