import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:morpheus/services/app_lock_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final AppLockService _service = AppLockService();
  bool _locked = false;
  bool _authInProgress = false;
  bool _supported = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncLock(initial: true);
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncLock(initial: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncLock({required bool initial}) {
    if (!widget.enabled) {
      if (mounted) {
        setState(() => _locked = false);
      }
      return;
    }
    if (mounted) {
      setState(() => _locked = true);
    } else {
      _locked = true;
    }
    if (initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    } else {
      _authenticate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _locked = true;
      if (!_authInProgress) {
        _service.cancel();
      }
    } else if (state == AppLifecycleState.resumed && _locked) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_authInProgress || !widget.enabled) return;
    _authInProgress = true;
    final supported = await _service.isSupported();
    if (!supported) {
      if (mounted) {
        setState(() {
          _supported = false;
          _locked = false;
        });
      }
      _authInProgress = false;
      return;
    }
    final ok = await _service.authenticate();
    if (!mounted) return;
    setState(() {
      _supported = true;
      _locked = !ok;
      _authInProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !_locked) {
      return widget.child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: ColoredBox(
              color: colorScheme.surface.withOpacity(0.75),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 36,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'App locked',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _supported
                            ? 'Authenticate to continue'
                            : 'Device authentication not available',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _supported ? _authenticate : null,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Unlock'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
