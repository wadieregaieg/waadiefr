
# APK Updates System Documentation

The APK Updates system provides automatic update functionality for the FreshK mobile application. It allows the backend to manage APK versions, track downloads, and provide update notifications to mobile clients.

## Overview

This system enables:
- Version management for Android APK files
- Automatic update checks from mobile apps
- Secure APK file downloads
- Update statistics and logging
- Force update capabilities
- Backward compatibility support

## Architecture

### Models

#### APKVersion
Main model for managing APK versions and files.

**Fields:**
- `version`: Version string in X.Y.Z format (e.g., "1.0.0")
- `apk_file`: FileField storing the actual APK file
- `release_notes`: Description of changes in this version
- `is_active`: Whether this version is available for download
- `is_latest`: Whether this is the current latest version
- `force_update`: Whether users must update to this version
- `minimum_supported_version`: Oldest version that can update to this one
- `file_size`: Size of APK file in bytes (auto-calculated)
- `checksum`: SHA256 hash of the APK file (auto-calculated)

#### UpdateLog
Tracks all update-related activities.

**Fields:**
- `action`: Type of action ('check' or 'download')
- `user_agent`: Browser/app user agent string
- `ip_address`: Client IP address
- `current_version`: Version the client currently has
- `target_version`: Version being downloaded
- `timestamp`: When the action occurred

### API Endpoints

#### Update Check
**GET** `/api/apk/check-update/`

Checks if an update is available for the given version.

**Parameters:**
- `version` (required): Current app version
- `platform` (optional): Platform type (default: 'android')

**Response:**
```json
{
  "update_available": true,
  "latest_version": "1.2.0",
  "current_version": "1.1.0",
  "download_url": "http://localhost:8000/api/apk/download/1.2.0/",
  "release_notes": "Bug fixes and performance improvements",
  "apk_size": 25165824,
  "formatted_size": "24.0 MB",
  "force_update": false,
  "checksum": "a1b2c3d4..."
}
```

#### APK Download
**GET** `/api/apk/download/<version>/` or `/api/apk/download/`

Downloads the APK file for a specific version or the latest version.

**Response:** APK file with appropriate headers

#### Version Management (Admin)
**GET** `/api/apk/versions/` - List all versions
**GET** `/api/apk/versions/latest/` - Get latest version info
**GET** `/api/apk/versions/stats/` - Get download statistics
**POST** `/api/apk/versions/upload/` - Upload new APK version

### Management Commands

#### Upload APK Command
Upload and register a new APK version via command line.

```bash
python manage.py upload_apk <version> <apk_path> [options]
```

**Arguments:**
- `version`: Version number (e.g., 1.0.0)
- `apk_path`: Path to the APK file

**Options:**
- `--release-notes`: Description of changes
- `--set-latest`: Mark as the latest version
- `--force-update`: Mark as requiring forced update

**Examples:**
```bash
# Basic upload
python manage.py upload_apk 1.0.0 /path/to/app.apk

# Upload with notes and mark as latest
python manage.py upload_apk 1.0.1 /path/to/app.apk \
  --release-notes "Bug fixes and performance improvements" \
  --set-latest

# Upload with forced update
python manage.py upload_apk 2.0.0 /path/to/app.apk \
  --release-notes "Major update with breaking changes" \
  --set-latest --force-update
```

## Setup Instructions

### 1. Run Migrations
```bash
cd /home/zied/development/flutter_projects/B2B-Freshk-backend
python manage.py makemigrations apk_updates
python manage.py migrate apk_updates
```

### 2. Create Directory Structure
The system will automatically create the necessary directories:
- `media/apk_files/` - Stores uploaded APK files

### 3. Configure Settings
The system uses existing Django settings:
- `MEDIA_URL` and `MEDIA_ROOT` for file storage
- `ALLOWED_HOSTS` for download URLs
- `CORS_ALLOWED_ORIGINS` for cross-origin requests

## Usage Examples

### Adding an APK Version

#### Method 1: Django Admin
1. Go to `/admin/`
2. Navigate to "APK UPDATES" → "APK Versions"
3. Click "Add APK Version"
4. Fill in the form and upload your APK file

#### Method 2: Management Command
```bash
python manage.py upload_apk 1.0.0 /path/to/freshk-v1.0.0.apk \
  --release-notes "Initial release" \
  --set-latest
```

#### Method 3: API Upload
```bash
curl -X POST http://localhost:8000/api/apk/versions/upload/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "version=1.0.0" \
  -F "apk_file=@/path/to/app.apk" \
  -F "release_notes=Initial release" \
  -F "is_latest=true"
```

### Mobile App Integration

#### Check for Updates
```dart
// Flutter/Dart example
Future<UpdateInfo> checkForUpdates(String currentVersion) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/apk/check-update/?version=$currentVersion')
  );
  
  if (response.statusCode == 200) {
    return UpdateInfo.fromJson(json.decode(response.body));
  }
  throw Exception('Failed to check for updates');
}
```

#### Download APK
```dart
Future<void> downloadApk(String downloadUrl, String version) async {
  final response = await http.get(Uri.parse(downloadUrl));
  
  if (response.statusCode == 200) {
    final file = File('/path/to/downloads/freshk-v$version.apk');
    await file.writeAsBytes(response.bodyBytes);
    // Install APK using platform-specific code
  }
}
```

## Security Considerations

### File Validation
- APK files are validated for format and integrity
- SHA256 checksums are automatically calculated and verified
- File size limits can be configured in Django settings

### Access Control
- Update checks are public (no authentication required)
- APK downloads are public for ease of use
- Admin endpoints require authentication (configure in production)
- Upload endpoints should be restricted to administrators

### HTTPS Recommendation
Always use HTTPS in production to prevent man-in-the-middle attacks during APK downloads.

## Monitoring and Analytics

### Download Statistics
Access via `/api/apk/versions/stats/`:
```json
{
  "total_downloads": 150,
  "total_update_checks": 1250,
  "version_downloads": {
    "1.0.0": 45,
    "1.1.0": 67,
    "1.2.0": 38
  },
  "total_versions": 3
}
```

### Update Logs
All update checks and downloads are logged with:
- Client IP address
- User agent information
- Version information
- Timestamp

## Troubleshooting

### Common Issues

#### "Table does not exist" Error
**Problem:** Database tables not created
**Solution:** Run migrations
```bash
python manage.py makemigrations apk_updates
python manage.py migrate apk_updates
```

#### APK File Not Found
**Problem:** File uploaded but not accessible
**Solution:** Check file permissions and MEDIA_ROOT settings

#### Version Comparison Issues
**Problem:** Updates not detected correctly
**Solution:** Ensure version format is X.Y.Z (semantic versioning)

### Debug Logging
Enable detailed logging by adding to settings.py:
```python
LOGGING = {
    'loggers': {
        'apps.apk_updates': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': True,
        },
    },
}
```

## File Structure

```
apps/apk_updates/
├── __init__.py
├── admin.py                    # Django admin configuration
├── apps.py                     # App configuration
├── models.py                   # APKVersion and UpdateLog models
├── serializers.py              # DRF serializers
├── urls.py                     # URL routing
├── views.py                    # API views and endpoints
├── migrations/
│   └── __init__.py
└── management/
    ├── __init__.py
    └── commands/
        ├── __init__.py
        └── upload_apk.py       # Management command for APK upload
```

## Future Enhancements

### Planned Features
1. **iOS Support**: Extend for iOS app distribution
2. **Rollback Capability**: Ability to rollback to previous versions
3. **A/B Testing**: Gradual rollout to subset of users
4. **Delta Updates**: Provide incremental updates to reduce download size
5. **Enhanced Analytics**: More detailed usage statistics
6. **Automated Testing**: Integration with CI/CD for automatic APK validation

### Configuration Options
Future versions may include:
- Update scheduling (specific times for updates)
- Geographic targeting (different versions for different regions)
- Device-specific updates (based on device capabilities)
- Beta channel support (separate track for beta testers)

## Support

For issues or questions regarding the APK Updates system:
1. Check the troubleshooting section above
2. Review Django and DRF logs for error details
3. Ensure proper database migrations have been applied
4. Verify file permissions and storage configuration

---

*Last updated: December 2024*
*Version: 1.0.0*
