from rest_framework import serializers
from .models import APKVersion

class UpdateCheckSerializer(serializers.Serializer):
    """Serializer for update check response"""
    update_available = serializers.BooleanField()
    latest_version = serializers.CharField()
    current_version = serializers.CharField()
    download_url = serializers.URLField()
    release_notes = serializers.CharField()
    apk_size = serializers.IntegerField()
    formatted_size = serializers.CharField()
    force_update = serializers.BooleanField()
    checksum = serializers.CharField(required=False)

class APKVersionSerializer(serializers.ModelSerializer):
    """Serializer for APK version information"""
    formatted_size = serializers.ReadOnlyField()
    download_url = serializers.SerializerMethodField()
    
    class Meta:
        model = APKVersion
        fields = [
            'id', 'version', 'release_notes', 'is_active', 
            'is_latest', 'force_update', 'file_size', 
            'formatted_size', 'checksum', 'created_at', 'download_url'
        ]
        read_only_fields = ['id', 'file_size', 'checksum', 'created_at']
    
    def get_download_url(self, obj):
        request = self.context.get('request')
        if request and obj.apk_file:
            return request.build_absolute_uri(f'/api/apk/download/{obj.version}/')
        return None
