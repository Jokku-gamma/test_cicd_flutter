import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'services/update_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CI/CD Update Demo',

      // VERSION 1.0.1 CHANGE
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),

      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String currentVersion = 'Loading...';
  String currentBuildNumber = '';

  UpdateInfo? updateInfo;

  bool checkingForUpdate = false;
  bool downloading = false;

  double downloadProgress = 0;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    _loadAppVersion();
    _checkForUpdate();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        currentVersion = packageInfo.version;
        currentBuildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        currentVersion = 'Unknown';
        currentBuildNumber = '';
      });
    }
  }

  Future<void> _checkForUpdate() async {
    if (checkingForUpdate) return;

    setState(() {
      checkingForUpdate = true;
      errorMessage = null;
    });

    try {
      final result =
          await UpdateService.checkForUpdate();

      if (!mounted) return;

      setState(() {
        updateInfo = result;
        checkingForUpdate = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        checkingForUpdate = false;
        errorMessage =
            'Could not check for updates.';
      });
    }
  }

  Future<void> _updateApplication() async {
    final update = updateInfo;

    if (update == null) return;

    setState(() {
      downloading = true;
      downloadProgress = 0;
      errorMessage = null;
    });

    try {
      await UpdateService.downloadAndInstall(
        update.downloadUrl,
        onProgress: (progress) {
          if (!mounted) return;

          setState(() {
            downloadProgress = progress;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Update failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update failed: $e',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        downloading = false;
      });
    }
  }

  void _showUpdateDialog() {
    final update = updateInfo;

    if (update == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update),
              SizedBox(width: 10),
              Text('New Update'),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Version ${update.version} '
                  'is available.',
                ),

                const SizedBox(height: 20),

                if (update.releaseNotes
                    .trim()
                    .isNotEmpty) ...[
                  const Text(
                    'What is new?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    update.releaseNotes,
                  ),
                ],
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('LATER'),
            ),

            ElevatedButton(
              onPressed: downloading
                  ? null
                  : () {
                      Navigator.pop(context);
                      _updateApplication();
                    },
              child: const Text('UPDATE NOW'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.green.shade50,

      appBar: AppBar(
        backgroundColor:
            Colors.green.shade700,

        foregroundColor: Colors.white,

        title: const Text(
          'CI/CD Update Demo',
        ),

        actions: [
          IconButton(
            tooltip: 'Check for updates',
            onPressed:
                checkingForUpdate
                    ? null
                    : _checkForUpdate,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              /*
               * =================================================
               * BIG VERSION 1.0.1 CHANGE
               * =================================================
               */

              const Icon(
                Icons.rocket_launch,
                size: 100,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              const Text(
                'CI/CD UPDATE SUCCESS!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'This screen belongs to Version 1.0.1',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              /*
               * CURRENT VERSION
               */

              Card(
                elevation: 4,

                child: Padding(
                  padding:
                      const EdgeInsets.all(24),

                  child: Column(
                    children: [
                      const Text(
                        'Installed Version',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'v$currentVersion',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      if (currentBuildNumber
                          .isNotEmpty) ...[
                        const SizedBox(height: 5),

                        Text(
                          'Build $currentBuildNumber',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /*
               * UPDATE CHECK
               */

              if (checkingForUpdate)
                const Column(
                  children: [
                    CircularProgressIndicator(),

                    SizedBox(height: 15),

                    Text(
                      'Checking GitHub for updates...',
                    ),
                  ],
                )

              else if (updateInfo != null)
                _buildUpdateAvailable()

              else
                _buildUpToDate(),

              /*
               * ERROR
               */

              if (errorMessage != null) ...[
                const SizedBox(height: 20),

                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateAvailable() {
    final update = updateInfo!;

    return Card(
      elevation: 5,

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const Icon(
              Icons.new_releases,
              size: 60,
              color: Colors.orange,
            ),

            const SizedBox(height: 15),

            const Text(
              'NEW UPDATE AVAILABLE!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Version ${update.version}',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 20),

            if (update.releaseNotes
                .trim()
                .isNotEmpty)
              Text(
                update.releaseNotes,
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 20),

            if (downloading) ...[
              LinearProgressIndicator(
                value:
                    downloadProgress > 0
                        ? downloadProgress
                        : null,
              ),

              const SizedBox(height: 10),

              Text(
                downloadProgress > 0
                    ? 'Downloading '
                        '${(downloadProgress * 100).toInt()}%'
                    : 'Downloading update...',
              ),

              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed:
                    downloading
                        ? null
                        : _updateApplication,

                icon: downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.download,
                      ),

                label: Text(
                  downloading
                      ? 'DOWNLOADING...'
                      : 'UPDATE NOW',
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed:
                  downloading
                      ? null
                      : _showUpdateDialog,

              child: const Text(
                'VIEW UPDATE DETAILS',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpToDate() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          size: 60,
          color: Colors.green,
        ),

        const SizedBox(height: 15),

        const Text(
          'You are up to date!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'No new version is available.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed:
              checkingForUpdate
                  ? null
                  : _checkForUpdate,

          icon: const Icon(
            Icons.refresh,
          ),

          label: const Text(
            'CHECK FOR UPDATES',
          ),
        ),
      ],
    );
  }
}