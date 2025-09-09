from rest_framework import viewsets, status, serializers
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from django.conf import settings
from django.core.files.storage import default_storage
from django.http import FileResponse
from django.db.models import Count
import os
import hashlib

from .models import APKVersion, UpdateLog
from .serializers import APKVersionSerializer
from apps.users.permissions import IsAdmin


class AdminAPKViewSet(viewsets.ModelViewSet):
    """Admin viewset for APK management"""
    queryset = APKVersion.objects.all().order_by('-created_at')
    serializer_class = APKVersionSerializer
    permission_classes = [IsAdmin]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_queryset(self):
        """Filter APK versions for admin"""
        return APKVersion.objects.all().order_by('-created_at')
    
    def create(self, request, *args, **kwargs):
        """Create new APK version with file upload"""
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            # Handle file upload and validation
            apk_file = request.FILES.get('apk_file')
            if apk_file:
                # Validate file extension
                if not apk_file.name.endswith('.apk'):
                    return Response(
                        {'error': 'Only APK files are allowed'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Calculate file size and checksum
                file_size = apk_file.size
                checksum = self._calculate_checksum(apk_file)
                
                # Create APK version
                apk_version = serializer.save(
                    apk_file=apk_file,
                    file_size=file_size,
                    checksum=checksum
                )
                
                # Set as latest if requested
                if request.data.get('is_latest', False):
                    APKVersion.objects.filter(is_latest=True).update(is_latest=False)
                    apk_version.is_latest = True
                    apk_version.save()
                
                return Response(
                    self.get_serializer(apk_version).data,
                    status=status.HTTP_201_CREATED
                )
            else:
                return Response(
                    {'error': 'APK file is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def update(self, request, *args, **kwargs):
        """Update APK version"""
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=True)
        
        if serializer.is_valid():
            # Handle file replacement if new file is provided
            if 'apk_file' in request.FILES:
                apk_file = request.FILES['apk_file']
                if not apk_file.name.endswith('.apk'):
                    return Response(
                        {'error': 'Only APK files are allowed'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Delete old file
                if instance.apk_file:
                    default_storage.delete(instance.apk_file.name)
                
                # Calculate new file properties
                file_size = apk_file.size
                checksum = self._calculate_checksum(apk_file)
                
                serializer.save(
                    apk_file=apk_file,
                    file_size=file_size,
                    checksum=checksum
                )
            else:
                serializer.save()
            
            # Handle latest flag
            if request.data.get('is_latest', False):
                APKVersion.objects.exclude(id=instance.id).update(is_latest=False)
                instance.is_latest = True
                instance.save()
            
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get APK download statistics"""
        # Basic stats
        total_versions = APKVersion.objects.count()
        active_versions = APKVersion.objects.filter(is_active=True).count()
        
        # Download stats from logs
        total_downloads = UpdateLog.objects.filter(action='download').count()
        total_update_checks = UpdateLog.objects.filter(action='check').count()
        
        # Version download breakdown
        version_downloads = {}
        download_logs = UpdateLog.objects.filter(action='download').values('target_version').annotate(
            count=Count('id')
        ).order_by('-count')
        
        for log in download_logs:
            version_downloads[log['target_version']] = log['count']
        
        # Recent activity (last 7 days)
        from datetime import datetime, timedelta
        seven_days_ago = datetime.now() - timedelta(days=7)
        recent_downloads = UpdateLog.objects.filter(
            action='download',
            timestamp__gte=seven_days_ago
        ).count()
        
        recent_checks = UpdateLog.objects.filter(
            action='check',
            timestamp__gte=seven_days_ago
        ).count()
        
        return Response({
            'total_downloads': total_downloads,
            'total_update_checks': total_update_checks,
            'total_versions': total_versions,
            'active_versions': active_versions,
            'version_downloads': version_downloads,
            'recent_activity': {
                'downloads_last_7_days': recent_downloads,
                'checks_last_7_days': recent_checks
            },
            'conversion_rate': (
                round((total_downloads / total_update_checks) * 100, 2)
                if total_update_checks > 0 else 0
            )
        })
    
    @action(detail=False, methods=['post'])
    def upload(self, request):
        """Upload new APK version (duplicate of create for dashboard compatibility)"""
        return self.create(request)
    
    @action(detail=True, methods=['post'])
    def set_latest(self, request, pk=None):
        """Set a version as the latest"""
        apk_version = self.get_object()
        
        # Unmark all other versions as latest
        APKVersion.objects.filter(is_latest=True).update(is_latest=False)
        
        # Mark this version as latest
        apk_version.is_latest = True
        apk_version.save()
        
        return Response({
            'success': True,
            'message': f'Version {apk_version.version} set as latest'
        })
    
    @action(detail=True, methods=['post'])
    def toggle_active(self, request, pk=None):
        """Toggle active status of a version"""
        apk_version = self.get_object()
        apk_version.is_active = not apk_version.is_active
        apk_version.save()
        
        return Response({
            'success': True,
            'is_active': apk_version.is_active,
            'message': f'Version {apk_version.version} {"activated" if apk_version.is_active else "deactivated"}'
        })
    
    @action(detail=False, methods=['get'])
    def latest(self, request):
        """Get the latest version info"""
        try:
            latest = APKVersion.objects.get(is_latest=True)
            serializer = self.get_serializer(latest)
            return Response(serializer.data)
        except APKVersion.DoesNotExist:
            return Response(
                {'error': 'No latest version found'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    def _calculate_checksum(self, file):
        """Calculate SHA256 checksum of uploaded file"""
        sha256_hash = hashlib.sha256()
        for chunk in file.chunks():
            sha256_hash.update(chunk)
        return sha256_hash.hexdigest()


class AdminAPKUploadSerializer(APKVersionSerializer):
    """Serializer for APK upload with file validation"""
    apk_file = serializers.FileField(required=True)
    
    class Meta(APKVersionSerializer.Meta):
        fields = APKVersionSerializer.Meta.fields + ['apk_file']
        read_only_fields = ['id', 'file_size', 'checksum', 'created_at']
    
    def validate_apk_file(self, value):
        """Validate APK file"""
        if not value.name.endswith('.apk'):
            raise serializers.ValidationError("Only APK files are allowed")
        
        # Check file size (limit to 100MB)
        if value.size > 100 * 1024 * 1024:
            raise serializers.ValidationError("APK file too large. Maximum size is 100MB")
        
        return value 