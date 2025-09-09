// lib/services/update_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:app_installer/app_installer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Get current version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // Check for updates
      final response = await DioInstance.dio.get(
        '/api/apk/check-update/?version=$currentVersion',
      );

      if (response.statusCode == 200) {
        // Log the update check response
        final data = response.data is String
            ? json.decode(response.data)
            : response.data;

        // If download_url is not provided, construct it from the base URL and version
        if (data['download_url'] == null || data['download_url'].isEmpty) {
          final baseUrl = DioInstance.dio.options.baseUrl;
          data['download_url'] =
              '$baseUrl/api/apk/download/${data['latest_version']}/';
        }

        return UpdateInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
    return null;
  }

  static Future<void> downloadAndInstall(String downloadUrl,
      {Function(double)? onProgress}) async {
    try {
      final directory = await getExternalStorageDirectory();
      final apkPath = '${directory!.path}/update.apk';
      debugPrint("Starting APK download from: $downloadUrl");
      debugPrint("Saving to: $apkPath");

      // Download the APK with progress tracking
      await DioInstance.dio.download(
        downloadUrl,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
            debugPrint(
                "Download progress: ${(progress * 100).toStringAsFixed(1)}%");
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          // Remove the Accept header that might be causing 406 error
          headers: {
            'User-Agent': 'Freshk Mobile App',
          },
        ),
      );

      final apkFile = File(apkPath);
      if (apkFile.existsSync()) {
        debugPrint(
            "APK downloaded successfully. File size: ${apkFile.lengthSync()} bytes");
        await UpdateService.requestPermissions();
        await UpdateService.installApk(apkPath);
        debugPrint("APK installed successfully");
      } else {
        throw Exception('Failed to download APK file');
      }
    } catch (e) {
      debugPrint('Error downloading and installing update: $e');
      // Add more detailed error information
      if (e is DioException) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Response headers: ${e.response?.headers}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.requestInstallPackages.request();

      // For Android 13+
      await Permission.mediaLibrary.request();

      // For Android <= 12
      await Permission.storage.request();
    }
  }

  static Future<void> installApk(String apkPath) async {
    try {
      if (Platform.isAndroid) {
        await AppInstaller.installApk(
          apkPath,
        );
      } else {
        debugPrint("Installation only supported on Android");
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to install APK: $e");
    }
  }
}

class UpdateInfo {
  final bool updateAvailable;
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final int apkSize;
  final String formattedSize;
  final bool forceUpdate;
  final String checksum;

  UpdateInfo({
    required this.updateAvailable,
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.apkSize,
    required this.formattedSize,
    required this.forceUpdate,
    required this.checksum,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      updateAvailable: json['update_available'] ?? false,
      latestVersion: json['latest_version'] ?? '',
      currentVersion: json['current_version'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      releaseNotes: json['release_notes'] ?? '',
      apkSize: json['apk_size'] ?? 0,
      formattedSize: json['formatted_size'] ?? '',
      forceUpdate: json['force_update'] ?? false,
      checksum: json['checksum'] ?? '',
    );
  }
}
