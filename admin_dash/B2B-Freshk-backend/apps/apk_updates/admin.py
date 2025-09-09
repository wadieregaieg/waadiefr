from django.contrib import admin
from django.utils.html import format_html
from .models import APKVersion, UpdateLog

@admin.register(APKVersion)
class APKVersionAdmin(admin.ModelAdmin):
    list_display = [
        'version', 'is_latest', 'is_active', 'force_update', 
        'formatted_size', 'created_at', 'download_count'
    ]
    list_filter = ['is_active', 'is_latest', 'force_update', 'created_at']
    search_fields = ['version', 'release_notes']
    readonly_fields = ['file_size', 'checksum', 'created_at', 'updated_at']
    
    fieldsets = [
        ('Version Information', {
            'fields': ['version', 'release_notes']
        }),
        ('APK File', {
            'fields': ['apk_file', 'file_size', 'checksum']
        }),
        ('Update Settings', {
            'fields': ['is_active', 'is_latest', 'force_update', 'minimum_supported_version']
        }),
        ('Timestamps', {
            'fields': ['created_at', 'updated_at'],
            'classes': ['collapse']
        })
    ]
    
    actions = ['mark_as_latest', 'activate_versions', 'deactivate_versions']
    
    def mark_as_latest(self, request, queryset):
        if queryset.count() == 1:
            version = queryset.first()
            APKVersion.objects.update(is_latest=False)
            version.is_latest = True
            version.save()
            self.message_user(request, f"Version {version.version} marked as latest")
        else:
            self.message_user(request, "Please select exactly one version", level='error')
    mark_as_latest.short_description = "Mark selected version as latest"
    
    def activate_versions(self, request, queryset):
        count = queryset.update(is_active=True)
        self.message_user(request, f"{count} versions activated")
    activate_versions.short_description = "Activate selected versions"
    
    def deactivate_versions(self, request, queryset):
        count = queryset.update(is_active=False)
        self.message_user(request, f"{count} versions deactivated")
    deactivate_versions.short_description = "Deactivate selected versions"
    
    def download_count(self, obj):
        count = UpdateLog.objects.filter(
            action='download',
            target_version=obj.version
        ).count()
        return count
    download_count.short_description = "Downloads"

@admin.register(UpdateLog)
class UpdateLogAdmin(admin.ModelAdmin):
    list_display = ['action', 'ip_address', 'current_version', 'target_version', 'timestamp']
    list_filter = ['action', 'timestamp']
    search_fields = ['ip_address', 'current_version', 'target_version']
    readonly_fields = ['timestamp']
    date_hierarchy = 'timestamp'
    
    def has_add_permission(self, request):
        return False  # Don't allow manual creation of logs
