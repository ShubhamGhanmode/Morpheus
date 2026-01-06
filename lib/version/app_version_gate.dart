import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/splash_page.dart';

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  static const String _minBuildAndroidKey = 'min_build_android';
  static const Duration _fetchTimeout = Duration(seconds: 8);
  static const Duration _minimumFetchInterval = Duration(hours: 1);

  late Future<_VersionGateStatus> _checkFuture;

  @override
  void initState() {
    super.initState();
    _checkFuture = _checkMinBuild();
  }

  void _retry() {
    setState(() {
      _checkFuture = _checkMinBuild();
    });
  }

  Future<_VersionGateStatus> _checkMinBuild() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const _VersionGateStatus.allowed();
    }

    int currentBuild = 0;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _fetchTimeout,
          minimumFetchInterval: kDebugMode ? Duration.zero : _minimumFetchInterval,
        ),
      );
      await remoteConfig.setDefaults(const {_minBuildAndroidKey: 0});

      try {
        await remoteConfig.fetchAndActivate();
      } catch (error, stack) {
        await ErrorReporter.recordError(
          error,
          stack,
          reason: 'Remote config fetch failed',
          context: {'currentBuild': currentBuild.toString()},
        );
      }

      final minBuild = remoteConfig.getInt(_minBuildAndroidKey);
      if (minBuild > 0 && currentBuild > 0 && currentBuild < minBuild) {
        return _VersionGateStatus.blocked(currentBuild: currentBuild, minBuild: minBuild);
      }
    } catch (error, stack) {
      await ErrorReporter.recordError(
        error,
        stack,
        reason: 'Version gate check failed',
        context: {'currentBuild': currentBuild.toString()},
      );
    }

    return const _VersionGateStatus.allowed();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VersionGateStatus>(
      future: _checkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashPage(title: 'Checking version', description: 'Confirming this build is allowed to run.');
        }

        final status = snapshot.data ?? const _VersionGateStatus.allowed();
        if (status.isBlocked) {
          return SplashPage(title: 'Update required', message: _blockedMessage(status), onRetry: _retry);
        }

        return widget.child;
      },
    );
  }

  String _blockedMessage(_VersionGateStatus status) {
    // final minBuild = status.minBuild;
    // final currentBuild = status.currentBuild;
    // if (minBuild != null && currentBuild != null) {
    //   return 'This build ($currentBuild) is below the minimum allowed build '
    //       '($minBuild). Please install the latest build.';
    // }
    return 'This build is no longer allowed. Please install the latest build.';
  }
}

@immutable
class _VersionGateStatus {
  const _VersionGateStatus.allowed() : isBlocked = false, currentBuild = null, minBuild = null;

  const _VersionGateStatus.blocked({required this.currentBuild, required this.minBuild}) : isBlocked = true;

  final bool isBlocked;
  final int? currentBuild;
  final int? minBuild;
}
