from django.contrib import admin
from .models import CustomUser, RetailerProfile, SupplierProfile, Supplier


@admin.register(CustomUser)
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'role', 'phone_number', 'phone_verified', 'is_active', 'date_joined')
    list_filter = ('role', 'phone_verified', 'is_active', 'date_joined')
    search_fields = ('username', 'email', 'phone_number', 'first_name', 'last_name')
    readonly_fields = ('date_joined', 'last_activity', 'last_login_ip')


@admin.register(RetailerProfile)
class RetailerProfileAdmin(admin.ModelAdmin):
    list_display = ('company_name', 'user', 'contact_number')
    search_fields = ('company_name', 'user__username', 'contact_number')


@admin.register(SupplierProfile)
class SupplierProfileAdmin(admin.ModelAdmin):
    list_display = ('company_name', 'user', 'contact_person', 'phone')
    search_fields = ('company_name', 'user__username', 'contact_person', 'phone')


@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    list_display = ('company_name', 'contact_person', 'phone', 'email', 'created_at')
    list_filter = ('created_at', 'updated_at')
    search_fields = ('company_name', 'contact_person', 'phone', 'email')
    readonly_fields = ('created_at', 'updated_at')
    
    fieldsets = (
        ('Company Information', {
            'fields': ('company_name', 'contact_person')
        }),
        ('Contact Information', {
            'fields': ('phone', 'email', 'address')
        }),
        ('Additional Information', {
            'fields': ('additional_info',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    ) 