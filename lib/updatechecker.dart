import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class UpdateChecker {
  static void startOtaUpdate(String apkUrl) {
    try {
      OtaUpdate()
          .execute(apkUrl, destinationFilename: 'myapp-latest.apk')
          .listen((OtaEvent event) {
        // Handle OTA update events here if needed
        // For now, just print the event
        print('OTA Event: ${event.status} - ${event.value}');
      });
    } catch (e) {
      print('OTA Update failed: $e');
    }
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Get values
      String latestVersion =
          "1.0.2"; //remoteConfig.getString('latest_version');
      String updateMessage = "summa authurutha";

      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      debugPrint("📱 Current version: $currentVersion");
      debugPrint("☁️ Remote version: $latestVersion");

      if (_isVersionOlder(currentVersion, latestVersion)) {
        _showUpdateDialog(context, updateMessage);
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static bool _isVersionOlder(String current, String latest) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> l = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < l.length; i++) {
      if (i >= c.length || c[i] < l[i]) return true;
      if (c[i] > l[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Update Available"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              startOtaUpdate(
                "https://files.vfsstorage.in/cdn/test/Charles/app-release_version%201.0.2.apk",
              );
              // TODO: Replace with your Play Store / Firebase App Distribution link
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
