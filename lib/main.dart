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

      // VERSION 1.0.2
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
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

  // ============================================================
  // LOAD CURRENT APP VERSION
  // ============================================================

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
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

  // ============================================================
  // CHECK FOR UPDATE
  // ============================================================

  Future<void> _checkForUpdate() async {
    if (checkingForUpdate) return;

    setState(() {
      checkingForUpdate = true;
      errorMessage = null;
    });

    try {
      final result = await UpdateService.checkForUpdate();

      if (!mounted) return;

      setState(() {
        updateInfo = result;
        checkingForUpdate = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        checkingForUpdate = false;
        errorMessage = 'Could not check for updates.';
      });
    }
  }

  // ============================================================
  // UPDATE APPLICATION
  // ============================================================

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

  // ============================================================
  // OPEN UPDATE DRAWER
  // ============================================================

  void _openUpdateDrawer() {
    Scaffold.of(context).openEndDrawer();
  }

  // ============================================================
  // UPDATE DRAWER
  // ============================================================

  Widget _buildUpdateDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // DRAWER HEADER
            // ----------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                    ),
                    child: Icon(
                      Icons.system_update,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      'Updates',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Close',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ----------------------------------------------------
            // DRAWER CONTENT
            // ----------------------------------------------------

            Expanded(
              child: _buildUpdateContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPDATE CONTENT INSIDE DRAWER
  // ============================================================

  Widget _buildUpdateContent() {
    // ----------------------------------------------------------
    // CHECKING
    // ----------------------------------------------------------

    if (checkingForUpdate) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),

              SizedBox(height: 20),

              Text(
                'Checking GitHub for updates...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // UPDATE AVAILABLE
    // ----------------------------------------------------------

    if (updateInfo != null) {
      final update = updateInfo!;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // UPDATE ICON
            // --------------------------------------------------

            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade100,
                ),
                child: Icon(
                  Icons.new_releases,
                  size: 55,
                  color: Colors.orange.shade800,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

            const Center(
              child: Text(
                'New Update Available!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                'Version ${update.version}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // CURRENT VERSION
            // --------------------------------------------------

            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current version',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'v$currentVersion',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // NEW VERSION
            // --------------------------------------------------

            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New version',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'v${update.version}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------
            // RELEASE NOTES
            // --------------------------------------------------

            if (update.releaseNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 25),

              const Text(
                'What is new?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  update.releaseNotes,
                  style: const TextStyle(
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 25),

            // --------------------------------------------------
            // DOWNLOAD PROGRESS
            // --------------------------------------------------

            if (downloading) ...[
              Text(
                downloadProgress > 0
                    ? 'Downloading ${(downloadProgress * 100).toInt()}%'
                    : 'Downloading update...',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              LinearProgressIndicator(
                value: downloadProgress > 0
                    ? downloadProgress
                    : null,
              ),

              const SizedBox(height: 20),
            ],

            // --------------------------------------------------
            // UPDATE BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: downloading
                    ? null
                    : _updateApplication,
                icon: downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  downloading
                      ? 'DOWNLOADING...'
                      : 'UPDATE NOW',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // LATER BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: downloading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text('LATER'),
              ),
            ),

            // --------------------------------------------------
            // ERROR
            // --------------------------------------------------

            if (errorMessage != null) ...[
              const SizedBox(height: 20),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // UP TO DATE
    // ----------------------------------------------------------

    return _buildUpToDate();
  }

  // ============================================================
  // UP TO DATE
  // ============================================================

  Widget _buildUpToDate() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 70,
              color: Colors.green.shade600,
            ),

            const SizedBox(height: 20),

            const Text(
              'You are up to date!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'No new version is available.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            OutlinedButton.icon(
              onPressed: checkingForUpdate
                  ? null
                  : _checkForUpdate,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'CHECK FOR UPDATES',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN PAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      // --------------------------------------------------------
      // RIGHT SIDE UPDATE DRAWER
      // --------------------------------------------------------

      endDrawer: _buildUpdateDrawer(),

      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,

        title: const Text(
          'CI/CD Update Demo',
        ),

        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: 'Updates',
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.system_update,
                    ),

                    // Notification dot when update exists
                    if (updateInfo != null)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          IconButton(
            tooltip: 'Check for updates',
            onPressed: checkingForUpdate
                ? null
                : _checkForUpdate,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // --------------------------------------------------------
      // MAIN APP CONTENT
      // --------------------------------------------------------

    // --------------------------------------------------------
// MAIN APP CONTENT
// --------------------------------------------------------
body: SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ----------------------------------------------------
        // WELCOME SECTION
        // ----------------------------------------------------
        const SizedBox(height: 20),

        Text(
          'Welcome 👋',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          "Jokku's Application",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Your simple Flutter application',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 35),

        // ----------------------------------------------------
        // MAIN APPLICATION CARD
        // ----------------------------------------------------
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.apps,
                        size: 32,
                        color: Colors.blue.shade700,
                      ),
                    ),

                    const SizedBox(width: 16),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Jokku's Application",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Application Home',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Text(
                  'Welcome to the application.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'This is the main home page of Jokku\'s application. '
                  'Use the update icon in the top-right corner to '
                  'check for new versions.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ----------------------------------------------------
        // APPLICATION FEATURES
        // ----------------------------------------------------
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [

            // APP INFO
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 35,
                        color: Colors.blue.shade700,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'App Info',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Version $currentVersion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // UPDATES
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Icon(
                          Icons.system_update,
                          size: 35,
                          color: Colors.orange.shade700,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Updates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          updateInfo != null
                              ? 'Update available'
                              : 'You are up to date',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: updateInfo != null
                                ? Colors.orange.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // ----------------------------------------------------
        // CURRENT VERSION
        // ----------------------------------------------------
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [

                Icon(
                  Icons.verified,
                  size: 32,
                  color: Colors.green.shade600,
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Installed Version',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'v$currentVersion',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (currentBuildNumber.isNotEmpty)
                        Text(
                          'Build $currentBuildNumber',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),

                // UPDATE INDICATOR
                if (updateInfo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Latest',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ----------------------------------------------------
        // CHECK FOR UPDATES
        // ----------------------------------------------------
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: checkingForUpdate
                ? null
                : _checkForUpdate,
            icon: checkingForUpdate
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(
              checkingForUpdate
                  ? 'CHECKING...'
                  : 'CHECK FOR UPDATES',
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ----------------------------------------------------
        // FOOTER
        // ----------------------------------------------------
        Center(
          child: Text(
            "Jokku's Application",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    ),
  ),
),

      
    );
  }
}