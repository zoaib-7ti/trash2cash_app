import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/routing/route_guard.dart';
import '../state/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _handledRouteMessage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledRouteMessage) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(args)));
      });
    }
    _handledRouteMessage = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Consumer<AuthState>(
      builder: (context, authState, _) {
        final loginState = authState.loginState;
        final isLoading = loginState.isLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Log in'),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      decoration: BoxDecoration(
                        color: tokens.lightGreenSurfaceTint,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: tokens.lightGreenSurfaceTint),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: tokens.primaryColor,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              Icons.bolt,
                              size: 38,
                              color: Colors.white.withValues(alpha: 0.98),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Turn your recycling into rewards.\nSign in to continue.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF4B5563),
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (loginState.errorMessage != null &&
                        (loginState.fieldErrors == null ||
                            loginState.fieldErrors!.isEmpty)) ...[
                      ErrorBanner(
                        message: loginState.errorMessage!,
                        onRetry: _submit,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _FieldLabel(text: 'EMAIL ADDRESS'),
                    const SizedBox(height: 8),
                    _TextFieldShell(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      hintText: 'user@trash2cash.com',
                      prefixIcon: Icons.email_outlined,
                      errorText: authState.fieldErrorFor(
                        loginState.fieldErrors,
                        'email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(text: 'PASSWORD'),
                    const SizedBox(height: 8),
                    _TextFieldShell(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      errorText: authState.fieldErrorFor(
                        loginState.fieldErrors,
                        'password',
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PrimaryButton(
                      text: 'Sign In',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF6B7280)),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/register');
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: tokens.primaryColor,
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) {
      return;
    }

    final authState = context.read<AuthState>();
    final destination = await authState.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || destination == null) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(destination.routeName, (route) => false);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 1.2,
        color: const Color(0xFF6B7280),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _TextFieldShell extends StatelessWidget {
  const _TextFieldShell({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.errorText,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final String? errorText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF6B7280)),
        suffixIcon: suffixIcon,
        errorText: errorText,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primaryColor,
          foregroundColor: const Color(0xFF0F172A),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Sign In'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}
