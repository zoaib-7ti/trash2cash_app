import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../data/models/user_model.dart';
import '../state/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cnicController = TextEditingController();
  final _vehicleTypeController = TextEditingController();

  UserRole _selectedRole = UserRole.citizen;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cnicController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Consumer<AuthState>(
      builder: (context, authState, _) {
        final registerState = authState.registerState;
        final isLoading = registerState.isLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Create Account'),
            centerTitle: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: true,
            actions: [
              IconButton(onPressed: null, icon: const Icon(Icons.more_vert)),
            ],
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
                    Text(
                      'Join the Community',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select how you want to use Trash 2 Cash',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            title: 'Household',
                            description: 'Request pickups for your recyclables',
                            icon: Icons.person_outline,
                            selected: _selectedRole == UserRole.citizen,
                            onTap: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _selectedRole = UserRole.citizen;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            title: 'Collector',
                            description: 'Pick up waste and earn rewards',
                            icon: Icons.local_shipping_outlined,
                            selected: _selectedRole == UserRole.collector,
                            onTap: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _selectedRole = UserRole.collector;
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (registerState.errorMessage != null &&
                        (registerState.fieldErrors == null ||
                            registerState.fieldErrors!.isEmpty)) ...[
                      ErrorBanner(
                        message: registerState.errorMessage!,
                        onRetry: _submit,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _FieldLabel(text: 'FULL NAME'),
                    const SizedBox(height: 6),
                    _TextFieldShell(
                      controller: _nameController,
                      hintText: 'John Doe',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      errorText: authState.fieldErrorFor(
                        registerState.fieldErrors,
                        'name',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(text: 'EMAIL ADDRESS'),
                    const SizedBox(height: 6),
                    _TextFieldShell(
                      controller: _emailController,
                      hintText: 'john@example.com',
                      prefixIcon: Icons.email_outlined,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      errorText: authState.fieldErrorFor(
                        registerState.fieldErrors,
                        'email',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(text: 'PHONE NUMBER'),
                    const SizedBox(height: 6),
                    _TextFieldShell(
                      controller: _phoneController,
                      hintText: '03001234567',
                      prefixIcon: Icons.phone_outlined,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      errorText: authState.fieldErrorFor(
                        registerState.fieldErrors,
                        'phone',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(text: 'PASSWORD'),
                    const SizedBox(height: 6),
                    _TextFieldShell(
                      controller: _passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      errorText: authState.fieldErrorFor(
                        registerState.fieldErrors,
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
                    const SizedBox(height: 6),
                    Text(
                      'Must include uppercase, lowercase, a number, and be at least 8 characters.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF22C55E)),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'By creating an account, you agree to our ',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF6B7280),
                                    height: 1.35,
                                  ),
                              children: const [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedRole == UserRole.collector) ...[
                      const SizedBox(height: 14),
                      _FieldLabel(text: 'CNIC NUMBER'),
                      const SizedBox(height: 6),
                      _TextFieldShell(
                        controller: _cnicController,
                        hintText: '13101-1234567-1',
                        prefixIcon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        errorText: authState.fieldErrorFor(
                          registerState.fieldErrors,
                          'cnicNumber',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel(text: 'VEHICLE TYPE'),
                      const SizedBox(height: 6),
                      _TextFieldShell(
                        controller: _vehicleTypeController,
                        hintText: 'Motorbike',
                        prefixIcon: Icons.local_shipping_outlined,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        errorText: authState.fieldErrorFor(
                          registerState.fieldErrors,
                          'vehicleType',
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _PrimaryButton(
                      text: 'Create Account',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF6B7280)),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pushNamed('/login');
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: tokens.primaryColor,
                            ),
                            child: const Text(
                              'Log in',
                              style: TextStyle(fontWeight: FontWeight.w800),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthState>();
    final success = await authState.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      cnicNumber: _selectedRole == UserRole.collector
          ? _cnicController.text.trim()
          : null,
      vehicleType: _selectedRole == UserRole.collector
          ? _vehicleTypeController.text.trim()
          : null,
    );

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
      arguments: 'Registration successful. Please log in.',
    );
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
    final borderColor = errorText != null
        ? const Color(0xFFFCA5A5)
        : const Color(0xFFD1D5DB);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF6B7280)),
        suffixIcon: suffixIcon,
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.lightTokens.primaryColor,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 1.4),
        ),
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
                  Text('Create Account'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    final borderColor = selected
        ? tokens.primaryColor
        : const Color(0xFFD1D5DB);
    final backgroundColor = selected
        ? tokens.lightGreenSurfaceTint
        : Colors.white;
    final iconCircleColor = selected
        ? tokens.primaryColor
        : const Color(0xFFE5E7EB);
    final iconColor = selected ? Colors.white : const Color(0xFF6B7280);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.3),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: tokens.primaryColor.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconCircleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
