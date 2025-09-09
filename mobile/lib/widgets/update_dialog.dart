import 'package:flutter/material.dart';
import 'package:freshk/services/update_service.dart';
import 'package:freshk/utils/freshk_utils.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onUpdateLater;

  const UpdateDialog({
    Key? key,
    required this.updateInfo,
    this.onUpdateLater,
  }) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.updateInfo.forceUpdate && !_isDownloading,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF1AB560)),
            const SizedBox(width: 8),
            Text(
              widget.updateInfo.forceUpdate
                  ? 'Required Update'
                  : 'Update Available',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${widget.updateInfo.latestVersion} is now available!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Current version: ${widget.updateInfo.currentVersion}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
              const Text(
                'What\'s new:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.updateInfo.releaseNotes),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.updateInfo.formattedSize.isNotEmpty)
              Text(
                'Size: ${widget.updateInfo.formattedSize}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.grey[300],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF1AB560)),
              ),
              const SizedBox(height: 8),
              Text(
                'Downloading... ${(_downloadProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: _isDownloading
            ? []
            : [
                if (!widget.updateInfo.forceUpdate)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onUpdateLater?.call();
                    },
                    child: const Text('Later'),
                  ),
                ElevatedButton(
                  onPressed: _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1AB560),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                      widget.updateInfo.forceUpdate ? 'Update Now' : 'Update'),
                ),
              ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await UpdateService.downloadAndInstall(
        widget.updateInfo.downloadUrl,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        FreshkUtils.showErrorSnackbar(context, 'Failed to download update: $e');
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }
}
