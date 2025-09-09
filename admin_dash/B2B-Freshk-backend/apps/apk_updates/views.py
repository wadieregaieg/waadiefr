from django.http import JsonResponse, FileResponse, Http404
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status, viewsets
from rest_framework.decorators import action
from django.db import ProgrammingError, OperationalError
import os
import hashlib
import logging

from .models import APKVersion, UpdateLog
from .serializers import UpdateCheckSerializer, APKVersionSerializer
from apps.users.permissions import IsAdmin

logger = logging.getLogger(__name__)

def get_client_ip(request):
    """Get client IP address from request"""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

def log_update_action(request, action, current_version=None, target_version=None):
    """Log update check or download action"""
    try:
        UpdateLog.objects.create(
            action=action,
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            ip_address=get_client_ip(request),
            current_version=current_version or '',
            target_version=target_version or ''
        )
    except (ProgrammingError, OperationalError) as e:
        logger.warning(f"UpdateLog table not available, skipping log: {e}")
    except Exception as e:
        logger.error(f"Failed to log update action: {e}")

@api_view(['GET'])
@permission_classes([AllowAny])
def check_update(request):
    """
    Check if an update is available for the mobile app
    
    Query Parameters:
    - version: Current app version (required)
    - platform: Platform (android/ios) - optional
    
    Returns:
    - update_available: boolean
    - latest_version: string
    - download_url: string
    - release_notes: string
    - apk_size: integer (bytes)
    - formatted_size: string (human readable)
    - force_update: boolean
    """
    current_version = request.GET.get('version')
    platform = request.GET.get('platform', 'android')
    
    if not current_version:
        return Response({
            'error': 'version parameter is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Log the update check
    log_update_action(request, 'check', current_version=current_version)
    
    try:
        # Get the latest active version
        latest_version_obj = APKVersion.objects.filter(
            is_active=True,
            is_latest=True
        ).first()
        
        if not latest_version_obj:
            # No versions available
            return Response({
                'update_available': False,
                'latest_version': current_version,
                'message': 'No updates available'
            })
        
        latest_version = latest_version_obj.version
        
        # Compare versions
        version_comparison = APKVersion.compare_versions(current_version, latest_version)
        update_available = version_comparison < 0  # current_version < latest_version
        
        # Check if current version is supported
        min_supported = latest_version_obj.minimum_supported_version
        if min_supported and APKVersion.compare_versions(current_version, min_supported) < 0:
            # Current version is too old
            force_update = True
        else:
            force_update = latest_version_obj.force_update and update_available
        
        # Build download URL
        download_url = request.build_absolute_uri(
            f'/api/apk/download/{latest_version}/'
        )
        
        response_data = {
            'update_available': update_available,
            'latest_version': latest_version,
            'current_version': current_version,
            'download_url': download_url,
            'release_notes': latest_version_obj.release_notes,
            'apk_size': latest_version_obj.file_size or 0,
            'formatted_size': latest_version_obj.formatted_size,
            'force_update': force_update,
            'checksum': latest_version_obj.checksum or ''
        }
        
        serializer = UpdateCheckSerializer(data=response_data)
        if serializer.is_valid():
            return Response(serializer.data)
        else:
            logger.error(f"Serializer errors: {serializer.errors}")
            return Response(response_data)  # Return raw data if serializer fails
            
    except Exception as e:
        logger.error(f"Error checking for updates: {e}")
        return Response({
            'error': 'Internal server error',
            'update_available': False,
            'latest_version': current_version
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def download_apk(request, version=None):
    """
    Download APK file for specified version
    If no version specified, download latest version
    """
    try:
        if version:
            # Download specific version
            apk_version = APKVersion.objects.filter(
                version=version,
                is_active=True
            ).first()
        else:
            # Download latest version
            apk_version = APKVersion.objects.filter(
                is_active=True,
                is_latest=True
            ).first()
        
        if not apk_version:
            raise Http404("APK version not found or not available")
        
        # Log the download
        log_update_action(
            request, 
            'download', 
            target_version=apk_version.version
        )
        
        # Check if file exists
        if not apk_version.apk_file or not os.path.exists(apk_version.apk_file.path):
            logger.error(f"APK file not found for version {apk_version.version}")
            raise Http404("APK file not found on server")
        
        # Serve the file
        response = FileResponse(
            open(apk_version.apk_file.path, 'rb'),
            as_attachment=True,
            filename=f"freshk-v{apk_version.version}.apk"
        )
        
        # Add headers
        response['Content-Type'] = 'application/vnd.android.package-archive'
        response['Content-Length'] = apk_version.file_size
        
        if apk_version.checksum:
            response['X-Checksum-SHA256'] = apk_version.checksum
        
        return response
        
    except Http404:
        raise
    except Exception as e:
        logger.error(f"Error downloading APK: {e}")
        return Response({
            'error': 'Failed to download APK file'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

from rest_framework.parsers import MultiPartParser, FormParser
from django.core.files.uploadedfile import InMemoryUploadedFile
import hashlib

class APKVersionViewSet(viewsets.ReadOnlyModelViewSet):
    """
    APK version management for mobile clients
    """
    serializer_class = APKVersionSerializer
    queryset = APKVersion.objects.filter(is_active=True)
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]  # Allow mobile clients to check for updates
        return [IsAdmin()]  # All other actions require admin
    
    permission_classes = [AllowAny]  # Default for list/retrieve actions

    @action(detail=False, methods=['get'])
    def latest(self, request):
        """Get the latest active APK version"""
        latest = APKVersion.objects.filter(is_active=True, is_latest=True).first()
        if latest:
            return Response(APKVersionSerializer(latest).data)
        return Response({"error": "No active APK version found"}, status=404)
    
    @action(detail=False, methods=['get'])
    def check_update(self, request):
        """Check if update is available for given version"""
        current_version = request.query_params.get('version')
        if not current_version:
            return Response({"error": "Version parameter is required"}, status=400)
        
        try:
            current_version_obj = APKVersion.objects.get(version=current_version)
            latest = APKVersion.objects.filter(is_active=True, is_latest=True).first()
            
            if latest and latest.id != current_version_obj.id:
                return Response({
                    "update_available": True,
                    "latest_version": APKVersionSerializer(latest).data,
                    "force_update": latest.force_update
                })
            else:
                return Response({
                    "update_available": False,
                    "current_version": APKVersionSerializer(current_version_obj).data
                })
        except APKVersion.DoesNotExist:
            return Response({"error": "Version not found"}, status=404)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get APK download statistics - Admin only"""
        self.permission_classes = [IsAdmin]  # Override to admin-only
        
        return Response({
            'total_versions': APKVersion.objects.filter(is_active=True).count(),
            'total_downloads': sum(apk.download_count for apk in APKVersion.objects.filter(is_active=True)),
            'latest_version': APKVersion.objects.filter(is_active=True, is_latest=True).first().version if APKVersion.objects.filter(is_active=True, is_latest=True).exists() else None
        })
    
    @action(detail=True, methods=['get'])
    def download_stats(self, request, pk=None):
        """Get download statistics for specific version - Admin only"""
        self.permission_classes = [IsAdmin]  # Override to admin-only
        
        version = self.get_object()
        return Response({
            'version': version.version,
            'download_count': version.download_count,
            'total_versions': APKVersion.objects.filter(is_active=True).count(),
            'latest_version': APKVersion.objects.filter(is_active=True, is_latest=True).first().version if APKVersion.objects.filter(is_active=True, is_latest=True).exists() else None
        })

# Legacy endpoint for backward compatibility
@require_http_methods(["GET"])
@csrf_exempt
def legacy_check_update(request):
    """Legacy endpoint for backward compatibility"""
    return check_update(request)

@require_http_methods(["GET"])
@csrf_exempt
def legacy_download_apk(request):
    """Legacy endpoint for backward compatibility"""
    return download_apk(request)
