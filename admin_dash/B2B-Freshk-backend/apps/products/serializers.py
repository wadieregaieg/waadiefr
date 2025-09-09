from rest_framework import serializers
from .models import ProductCategory, Product
from .fields import Base64ImageField

class ProductCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductCategory
        fields = '__all__'

class ProductSerializer(serializers.ModelSerializer):
    image = Base64ImageField(required=False, allow_null=True)

    class Meta:
        model = Product
        fields = '__all__'
