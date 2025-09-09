from rest_framework import permissions

class IsAdmin(permissions.BasePermission):
    """
    Custom permission to only allow admin users to access the view.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'admin'

class IsRetailer(permissions.BasePermission):
    """
    Custom permission to only allow retailer users to access the view.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'retailer'

class IsSupplier(permissions.BasePermission):
    """
    Custom permission to only allow supplier users to access the view.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'supplier'

class IsAdminOrSupplier(permissions.BasePermission):
    """
    Custom permission to only allow admin or supplier users to access the view.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.role in ['admin', 'supplier']

class IsAdminOrRetailer(permissions.BasePermission):
    """
    Custom permission to only allow admin or retailer users to access the view.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.role in ['admin', 'retailer']

class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object or admins to edit it.
    """
    def has_object_permission(self, request, view, obj):
        # Admin can access any object
        if request.user.role == 'admin':
            return True
            
        # Check if the object has a user attribute that matches the request user
        if hasattr(obj, 'user'):
            return obj.user == request.user
            
        # For retailer and supplier profiles
        if hasattr(obj, 'retailer_profile') and hasattr(request.user, 'retailer_profile'):
            return obj.retailer_profile.user == request.user
            
        if hasattr(obj, 'supplier_profile') and hasattr(request.user, 'supplier_profile'):
            return obj.supplier_profile.user == request.user
            
        return False
