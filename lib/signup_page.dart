import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:morpheus/services/auth_service.dart';
import 'package:morpheus/services/error_reporter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  bool _busy = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final (user, isNew) = await AuthService.signInWithGoogle();

      dev.log(
        'Google sign-in OK',
        name: 'auth',
        error: {'uid': user?.uid, 'email': user?.email, 'isNew': isNew},
      );

      // ✅ No manual navigation here (see section 2)
      // just return and let AuthGate rebuild.
      return;
    } on GoogleSignInException catch (e, st) {
      await ErrorReporter.recordError(
        e,
        st,
        reason: 'Google sign-in failed',
      );
      dev.log(
        'GoogleSignInException: ${e.code}',
        name: 'auth',
        error: e.description,
        stackTrace: st,
      );
      setState(() => _error = 'Google sign-in failed: ${e.code}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.code}')),
      );
    } on FirebaseAuthException catch (e, st) {
      await ErrorReporter.recordError(
        e,
        st,
        reason: 'Firebase auth failed',
      );
      dev.log(
        'FirebaseAuthException: ${e.code}',
        name: 'auth',
        error: e.message,
        stackTrace: st,
      );
      setState(() => _error = 'Auth error: ${e.code}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Auth error: ${e.code}')));
    } catch (e, st) {
      await ErrorReporter.recordError(
        e,
        st,
        reason: 'Sign-in failed',
      );
      dev.log('Unknown auth error', name: 'auth', error: e, stackTrace: st);
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Need Help?'),
        content: const Text(
          'If you\'re having trouble signing in:\n\n'
          '• Make sure you have a stable internet connection\n'
          '• Try clearing your browser cache\n'
          '• Contact our support team at support@morpheus.app',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
              colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Card(
                        elevation: 8,
                        shadowColor: colorScheme.shadow.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App Icon with enhanced styling
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  size: 48,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Welcome Text
                              Text(
                                'Welcome to Morpheus',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your secure financial companion',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Security Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.security,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bank-level security',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.normal,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Error Message
                              if (_error != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: colorScheme.onErrorContainer,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Google Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton.icon(
                                  onPressed: _busy ? null : _handleGoogle,
                                  icon: _busy
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  colorScheme.onPrimary,
                                                ),
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/images/google_logo.png', // Add Google logo asset
                                          height: 20,
                                          width: 20,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.login,
                                                    size: 20,
                                                  ),
                                        ),
                                  label: Text(
                                    _busy
                                        ? 'Signing in...'
                                        : 'Continue with Google',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: colorScheme.outline),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'or',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: colorScheme.outline),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Help Button
                              TextButton.icon(
                                onPressed: _busy ? null : _showHelpDialog,
                                icon: const Icon(Icons.help_outline, size: 18),
                                label: const Text('Need help signing in?'),
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Privacy Note
                              Text(
                                'By continuing, you agree to our Terms of Service and Privacy Policy. Your financial data is encrypted and secure.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
