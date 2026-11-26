import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../application/providers/wizard_draft_provider.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';
import '../../domain/enums/app_enums.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.isSignInIntent = false});

  final bool isSignInIntent;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _showEmailForm = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _showEmailForm = widget.isSignInIntent;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithProvider(
    AuthProviderType provider, {
    required String name,
    required String email,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(provider: provider, displayName: name, email: email);
      await ref.read(journeyWorkspaceProvider.notifier).reconcileTimeline();

      if (!mounted) return;
      final workspace = ref.read(journeyWorkspaceProvider);
      final archives = ref.read(archiveQueueControllerProvider).archives;
      if (workspace.hasOpenJourney || archives.isNotEmpty) {
        context.go('/home');
      } else {
        ref.read(journeyWizardProvider.notifier).reset(isQueueMode: false);
        context.go('/wizard');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _promptDemoIdentityAndSignIn(AuthProviderType provider) async {
    final nameCtrl = TextEditingController(text: 'Jordan Ellis');
    final confirmedName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Continue with ${provider.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your profile will be set up with local demo persistence.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: FinishXSpacing.md),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your display name',
                hintText: 'e.g. Jordan Ellis',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: () => Navigator.of(ctx).pop(
              nameCtrl.text.trim().isEmpty
                  ? 'Jordan Ellis'
                  : nameCtrl.text.trim(),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmedName != null && mounted) {
      final sanitized = confirmedName.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '.',
      );
      await _authenticateWithProvider(
        provider,
        name: confirmedName,
        email: '$sanitized@${provider.name}.demo.finishx',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: FinishXColors.darkBg,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/welcome');
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: FinishXSpacing.xl),
          child: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: FinishXSpacing.lg),
                Text(
                  widget.isSignInIntent
                      ? 'Welcome back'
                      : 'Create your account',
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: FinishXColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isSignInIntent
                      ? 'Sign in to access your ongoing commitment.'
                      : 'Join FinishX and start your next journey.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: FinishXColors.textSecondary,
                  ),
                ),
                const SizedBox(height: FinishXSpacing.xxl),

                // Continue with Google (White pill)
                _MockupAuthProviderButton(
                  label: 'Continue with Google',
                  isWhite: true,
                  iconWidget: const _GoogleGIcon(),
                  onPressed: _isSubmitting
                      ? null
                      : () => _promptDemoIdentityAndSignIn(
                          AuthProviderType.google,
                        ),
                ),
                const SizedBox(height: 14),

                // Continue with Apple (White pill)
                _MockupAuthProviderButton(
                  label: 'Continue with Apple',
                  isWhite: true,
                  iconWidget: const Icon(
                    Icons.apple_rounded,
                    size: 22,
                    color: Colors.black,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _promptDemoIdentityAndSignIn(
                          AuthProviderType.apple,
                        ),
                ),
                const SizedBox(height: 14),

                // Continue with Email (Dark outlined pill)
                _MockupAuthProviderButton(
                  label: 'Continue with Email',
                  isWhite: false,
                  iconWidget: const Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _showEmailForm = !_showEmailForm),
                ),

                if (_showEmailForm) ...[
                  const SizedBox(height: FinishXSpacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            hintText: 'Alex Mercer',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().length < 2) {
                              return 'Please enter your name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: FinishXSpacing.sm),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'alex@example.com',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (val) {
                            final v = val?.trim() ?? '';
                            if (v.isEmpty || !v.contains('@')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: FinishXSpacing.md),
                        FinishXPrimaryButton(
                          label: widget.isSignInIntent
                              ? 'Sign In'
                              : 'Create Account',
                          isLoading: _isSubmitting,
                          useMintFill: true,
                          onPressed: () {
                            if (_formKey.currentState?.validate() == true) {
                              _authenticateWithProvider(
                                AuthProviderType.email,
                                name: _nameController.text,
                                email: _emailController.text,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: FinishXSpacing.xl),
                Text(
                  'or',
                  style: textTheme.bodySmall?.copyWith(
                    color: FinishXColors.textMuted,
                  ),
                ),
                const SizedBox(height: FinishXSpacing.md),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showEmailForm = true;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium?.copyWith(
                        color: FinishXColors.textSecondary,
                      ),
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: FinishXColors.kineticMint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: FinishXSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MockupAuthProviderButton extends StatelessWidget {
  const _MockupAuthProviderButton({
    required this.label,
    required this.isWhite,
    required this.iconWidget,
    required this.onPressed,
  });

  final String label;
  final bool isWhite;
  final Widget iconWidget;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isWhite ? Colors.white : FinishXColors.cardSurface,
        foregroundColor: isWhite ? Colors.black : Colors.white,
        side: isWhite
            ? null
            : const BorderSide(color: FinishXColors.cardBorder, width: 1.2),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinishXSpacing.radiusPill),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isWhite ? Colors.black : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 16,
          height: 1.0,
        ),
      ),
    );
  }
}
