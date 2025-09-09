from django.db import models
from django.core.validators import RegexValidator
import os

class APKVersion(models.Model):
    """Model to track APK versions and files"""
    
    version = models.CharField(
        max_length=20,
        unique=True,
        validators=[RegexValidator(
            regex=r'^\d+\.\d+\.\d+$',
            message='Version must be in format X.Y.Z (e.g., 1.0.0)'
        )],
        help_text="Version in format X.Y.Z"
    )
    
    apk_file = models.FileField(
        upload_to='apk_files/',
        help_text="APK file for this version"
    )
    
    release_notes = models.TextField(
        blank=True,
        help_text="What's new in this version"
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this version is available for download"
    )
    
    is_latest = models.BooleanField(
        default=False,
        help_text="Whether this is the latest version"
    )
    
    force_update = models.BooleanField(
        default=False,
        help_text="Whether to force users to update to this version"
    )
    
    minimum_supported_version = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        help_text="Minimum version that can update to this version"
    )
    
    file_size = models.BigIntegerField(
        blank=True,
        null=True,
        help_text="File size in bytes"
    )
    
    checksum = models.CharField(
        max_length=64,
        blank=True,
        help_text="SHA256 checksum of the APK file"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-version']
        verbose_name = "APK Version"
        verbose_name_plural = "APK Versions"
    
    def __str__(self):
        return f"Version {self.version} {'(Latest)' if self.is_latest else ''}"
    
    def save(self, *args, **kwargs):
        # Calculate file size if not set
        if self.apk_file and not self.file_size:
            self.file_size = self.apk_file.size
        
        # If this is marked as latest, unmark others
        if self.is_latest:
            APKVersion.objects.exclude(id=self.id).update(is_latest=False)
        
        super().save(*args, **kwargs)
    
    @property
    def formatted_size(self):
        """Return human-readable file size"""
        if not self.file_size:
            return "Unknown"
        
        for unit in ['B', 'KB', 'MB', 'GB']:
            if self.file_size < 1024.0:
                return f"{self.file_size:.1f} {unit}"
            self.file_size /= 1024.0
        return f"{self.file_size:.1f} TB"
    
    @staticmethod
    def compare_versions(version1, version2):
        """Compare two version strings. Returns: -1 if v1<v2, 0 if equal, 1 if v1>v2"""
        v1_parts = [int(x) for x in version1.split('.')]
        v2_parts = [int(x) for x in version2.split('.')]
        
        # Pad shorter version with zeros
        max_len = max(len(v1_parts), len(v2_parts))
        v1_parts.extend([0] * (max_len - len(v1_parts)))
        v2_parts.extend([0] * (max_len - len(v2_parts)))
        
        for i in range(max_len):
            if v1_parts[i] < v2_parts[i]:
                return -1
            elif v1_parts[i] > v2_parts[i]:
                return 1
        return 0


class UpdateLog(models.Model):
    """Log of update checks and downloads"""
    
    ACTION_CHOICES = [
        ('check', 'Update Check'),
        ('download', 'APK Download'),
    ]
    
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)
    user_agent = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField()
    current_version = models.CharField(max_length=20, blank=True)
    target_version = models.CharField(max_length=20, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
        verbose_name = "Update Log"
        verbose_name_plural = "Update Logs"
    
    def __str__(self):
        return f"{self.action} - {self.ip_address} at {self.timestamp}"
