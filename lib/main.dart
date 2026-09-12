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

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
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
  State<MyHomePage> createState() =>
      _MyHomePageState();
}

class _MyHomePageState
    extends State<MyHomePage> {

  /*
   * Current installed version.
   */

  String currentVersion = 'Loading...';

  String currentBuildNumber = '';

  /*
   * Information about the update,
   * if one exists.
   */

  UpdateInfo? updateInfo;

  /*
   * UI states.
   */

  bool checkingForUpdate = false;

  bool downloading = false;

  double downloadProgress = 0;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    /*
     * Load current version.
     */

    _loadAppVersion();

    /*
     * Check GitHub for an update.
     */

    _checkForUpdate();
  }

  /*
   * ============================================================
   * LOAD CURRENT APP VERSION
   * ============================================================
   */

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      if (!mounted) {
        return;
      }

      setState(() {
        currentVersion =
            packageInfo.version;

        currentBuildNumber =
            packageInfo.buildNumber;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        currentVersion =
            'Unknown';

        currentBuildNumber =
            '';
      });
    }
  }

  /*
   * ============================================================
   * CHECK FOR UPDATE
   * ============================================================
   */

  Future<void> _checkForUpdate() async {
    if (checkingForUpdate) {
      return;
    }

    setState(() {
      checkingForUpdate = true;
      errorMessage = null;
    });

    try {
      final result =
          await UpdateService.checkForUpdate();

      if (!mounted) {
        return;
      }

      setState(() {
        updateInfo = result;
        checkingForUpdate = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        checkingForUpdate = false;

        errorMessage =
            'Could not check for updates.';
      });
    }
  }

  /*
   * ============================================================
   * DOWNLOAD AND INSTALL
   * ============================================================
   */

  Future<void> _updateApplication() async {
    final update =
        updateInfo;

    if (update == null) {
      return;
    }

    setState(() {
      downloading = true;
      downloadProgress = 0;
      errorMessage = null;
    });

    try {
      await UpdateService.downloadAndInstall(
        update.downloadUrl,

        onProgress: (progress) {
          if (!mounted) {
            return;
          }

          setState(() {
            downloadProgress =
                progress;
          });
        },
      );

      /*
       * Android installer has now been opened.
       *
       * The user will see the Android installation
       * confirmation screen.
       */

    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
            'Update failed: $e';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Update failed: $e',
          ),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        downloading = false;
      });
    }
  }

  /*
   * ============================================================
   * UPDATE DIALOG
   * ============================================================
   */

  void _showUpdateDialog() {
    final update =
        updateInfo;

    if (update == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.system_update,
              ),

              SizedBox(width: 10),

              Text(
                'New Update',
              ),
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
                      fontWeight:
                          FontWeight.bold,
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
              onPressed:
                  () {
                Navigator.pop(context);
              },

              child: const Text(
                'LATER',
              ),
            ),

            ElevatedButton(
              onPressed:
                  downloading
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                          );

                          _updateApplication();
                        },

              child: const Text(
                'UPDATE NOW',
              ),
            ),
          ],
        );
      },
    );
  }

  /*
   * ============================================================
   * BUILD UI
   * ============================================================
   */

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'CI/CD Update Demo',
        ),

        actions: [

          IconButton(
            tooltip:
                'Check for updates',

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
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              /*
               * APP ICON
               */

              const Icon(
                Icons.rocket_launch,
                size: 90,
              ),

              const SizedBox(
                height: 24,
              ),

              /*
               * TITLE
               */

              const Text(
                'Flutter CI/CD Demo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'GitHub Release Update System',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              /*
               * CURRENT VERSION CARD
               */

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),

                  child: Column(
                    children: [

                      const Text(
                        'Installed Version',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'v$currentVersion',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (currentBuildNumber
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          'Build $currentBuildNumber',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              /*
               * CHECKING
               */

              if (checkingForUpdate)
                const Column(
                  children: [

                    CircularProgressIndicator(),

                    SizedBox(
                      height: 15,
                    ),

                    Text(
                      'Checking GitHub for updates...',
                    ),
                  ],
                )

              /*
               * UPDATE AVAILABLE
               */

              else if (updateInfo != null)
                _buildUpdateAvailable()

              /*
               * NO UPDATE
               */

              else
                _buildUpToDate(),

              /*
               * ERROR
               */

              if (errorMessage != null) ...[
                const SizedBox(
                  height: 20,
                ),

                Text(
                  errorMessage!,
                  textAlign:
                      TextAlign.center,

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

  /*
   * ============================================================
   * UPDATE AVAILABLE UI
   * ============================================================
   */

  Widget _buildUpdateAvailable() {
    final update =
        updateInfo!;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [

            const Icon(
              Icons.new_releases,
              size: 60,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'New Update Available!',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Version ${update.version}',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            if (update.releaseNotes
                .trim()
                .isNotEmpty)
              Text(
                update.releaseNotes,
                textAlign:
                    TextAlign.center,
              ),

            const SizedBox(
              height: 20,
            ),

            /*
             * DOWNLOAD PROGRESS
             */

            if (downloading) ...[
              LinearProgressIndicator(
                value:
                    downloadProgress > 0
                        ? downloadProgress
                        : null,
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                downloadProgress > 0
                    ? 'Downloading '
                        '${(downloadProgress * 100).toInt()}%'
                    : 'Downloading update...',
              ),

              const SizedBox(
                height: 20,
              ),
            ],

            /*
             * UPDATE BUTTON
             */

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

            const SizedBox(
              height: 10,
            ),

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

  /*
   * ============================================================
   * UP TO DATE UI
   * ============================================================
   */

  Widget _buildUpToDate() {
    return Column(
      children: [

        const Icon(
          Icons.check_circle,
          size: 60,
        ),

        const SizedBox(
          height: 15,
        ),

        const Text(
          'You are up to date!',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        const Text(
          'No new version is available.',
          textAlign:
              TextAlign.center,
        ),

        const SizedBox(
          height: 20,
        ),

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