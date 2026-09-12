import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String buildNumber;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;

  const UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  /*
   * ============================================================
   * CHANGE THESE TWO VALUES
   * ============================================================
   */

  static const String githubOwner = 'Jokku-gamma';

  static const String githubRepository = 'test_cicd_flutter';
  /*
   * ============================================================
   * GitHub API URL
   * ============================================================
   */

  static String get latestReleaseUrl =>
      'https://api.github.com/repos/'
      '$githubOwner/$githubRepository/releases/latest';

  /*
   * ============================================================
   * CHECK FOR UPDATE
   * ============================================================
   */

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      /*
       * Get the version currently installed
       * on the user's phone.
       */

      final packageInfo =
          await PackageInfo.fromPlatform();

      final currentVersion = packageInfo.version;

      final currentBuildNumber =
          packageInfo.buildNumber;

      print(
        'Current version: $currentVersion',
      );

      print(
        'Current build: $currentBuildNumber',
      );

      /*
       * Ask GitHub for the latest release.
       */

      final response = await http.get(
        Uri.parse(latestReleaseUrl),
        headers: {
          'Accept': 'application/vnd.github+json',
        },
      );

      /*
       * GitHub should return HTTP 200.
       */

      if (response.statusCode != 200) {
        print(
          'GitHub API error: '
          '${response.statusCode}',
        );

        return null;
      }
      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final tagName =
          data['tag_name'] as String?;

      if (tagName == null ||
          tagName.isEmpty) {
        print(
          'GitHub release does not have tag_name',
        );

        return null;
      }


      final latestVersion =
          tagName.startsWith('v')
              ? tagName.substring(1)
              : tagName;

      /*
       * Get release name.
       */

      final releaseName =
          data['name'] as String? ??
              'New Update';

      /*
       * Get release notes/body.
       */

      final releaseNotes =
          data['body'] as String? ?? '';

      /*
       * Find the APK attached to the release.
       */

      final assets =
          data['assets'] as List<dynamic>? ??
              [];

      String? apkDownloadUrl;

      for (final asset in assets) {
        final assetMap =
            asset as Map<String, dynamic>;

        final assetName =
            assetMap['name'] as String?;

        final browserDownloadUrl =
            assetMap['browser_download_url']
                as String?;

        if (assetName != null &&
            assetName
                .toLowerCase()
                .endsWith('.apk') &&
            browserDownloadUrl != null) {
          apkDownloadUrl =
              browserDownloadUrl;

          break;
        }
      }

      /*
       * If GitHub release doesn't contain
       * an APK, there is nothing to install.
       */

      if (apkDownloadUrl == null) {
        print(
          'No APK found in latest GitHub release.',
        );

        return null;
      }

      /*
       * Compare current version with
       * latest GitHub version.
       */

      final isNewer = _isNewerVersion(
        latestVersion,
        currentVersion,
      );

      if (!isNewer) {
        print(
          'Application is already up to date.',
        );

        return null;
      }

      /*
       * We found a newer release.
       */

      return UpdateInfo(
        version: latestVersion,
        buildNumber: _extractBuildNumber(
          data,
        ),
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        downloadUrl: apkDownloadUrl,
      );
    } catch (e) {
      print(
        'Update check failed: $e',
      );

      return null;
    }
  }

  /*
   * ============================================================
   * VERSION COMPARISON
   * ============================================================
   *
   * Example:
   *
   * 1.0.1 > 1.0.0  -> true
   * 1.1.0 > 1.0.9  -> true
   * 2.0.0 > 1.9.9  -> true
   * 1.0.0 > 1.0.0  -> false
   */

  static bool _isNewerVersion(
    String latest,
    String current,
  ) {
    final latestParts =
        _parseVersion(latest);

    final currentParts =
        _parseVersion(current);

    final length =
        latestParts.length >
                currentParts.length
            ? latestParts.length
            : currentParts.length;

    for (int i = 0; i < length; i++) {
      final latestNumber =
          i < latestParts.length
              ? latestParts[i]
              : 0;

      final currentNumber =
          i < currentParts.length
              ? currentParts[i]
              : 0;

      if (latestNumber >
          currentNumber) {
        return true;
      }

      if (latestNumber <
          currentNumber) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(
    String version,
  ) {
    return version
        .split('.')
        .map(
          (part) =>
              int.tryParse(part) ?? 0,
        )
        .toList();
  }

  /*
   * ============================================================
   * BUILD NUMBER
   * ============================================================
   *
   * For now GitHub Releases don't automatically contain
   * Flutter's build number in a standard field.
   *
   * We therefore use the version as a fallback.
   *
   * Example:
   *
   * v1.0.1
   *      ↓
   * 1.0.1
   */

  static String _extractBuildNumber(
    Map<String, dynamic> data,
  ) {
    return 'Latest build';
  }

  /*
   * ============================================================
   * DOWNLOAD APK
   * ============================================================
   */

  static Future<String> downloadApk(
  String downloadUrl, {
  void Function(double progress)? onProgress,
}) async {
  print('Starting APK download...');
  print('Download URL: $downloadUrl');

  final client = http.Client();

  try {
    final request = http.Request(
      'GET',
      Uri.parse(downloadUrl),
    );

    final response = await client.send(request);

    print('Download HTTP status: ${response.statusCode}');
    print('Content length: ${response.contentLength}');

    if (response.statusCode != 200) {
      throw Exception(
        'APK download failed. HTTP ${response.statusCode}',
      );
    }

    final directory = await getTemporaryDirectory();

    final apkPath = '${directory.path}/app-update.apk';

    final apkFile = File(apkPath);

    // Delete old APK if it exists.
    if (await apkFile.exists()) {
      await apkFile.delete();
    }

    final sink = apkFile.openWrite();

    int downloadedBytes = 0;

    final totalBytes = response.contentLength;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);

        downloadedBytes += chunk.length;

        if (totalBytes != null && totalBytes > 0) {
          final progress = downloadedBytes / totalBytes;

          onProgress?.call(progress.clamp(0.0, 1.0));

          print(
            'Download progress: '
            '${(progress * 100).toStringAsFixed(1)}%',
          );
        }
      }
    } finally {
      await sink.close();
    }

    // Verify the complete APK was downloaded.
    if (totalBytes != null &&
        downloadedBytes != totalBytes) {
      throw Exception(
        'APK download incomplete. '
        'Downloaded $downloadedBytes of $totalBytes bytes.',
      );
    }

    // Final progress.
    onProgress?.call(1.0);

    final fileExists = await apkFile.exists();

    if (!fileExists) {
      throw Exception(
        'APK file was not created.',
      );
    }

    final fileSize = await apkFile.length();

    print('APK downloaded successfully.');
    print('APK path: $apkPath');
    print('APK size: $fileSize bytes');

    return apkPath;
  } finally {
    client.close();
  }
}
  /*
   * ============================================================
   * DOWNLOAD AND OPEN INSTALLER
   * ============================================================
   */
static const MethodChannel _installerChannel =
    MethodChannel('apk_installer');

static Future<void> downloadAndInstall(
  String downloadUrl, {
  void Function(double progress)? onProgress,
}) async {
  final apkPath = await downloadApk(
    downloadUrl,
    onProgress: onProgress,
  );

  print('APK downloaded.');
  print('Opening Android Package Installer...');

  try {
    await _installerChannel.invokeMethod(
      'installApk',
      {
        'apkPath': apkPath,
      },
    );

    print('Android installer launched.');
  } on PlatformException catch (e) {
    print('Installation failed.');
    print('Code: ${e.code}');
    print('Message: ${e.message}');

    throw Exception(
      'Could not open Android Package Installer: ${e.message}',
    );
  }
}
}