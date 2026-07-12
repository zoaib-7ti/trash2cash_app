import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/request_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/collector_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../state/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();

  bool _isEditMode = false;
  bool _requestedInitialLoad = false;
  AvailabilityStatus _availabilityStatus = AvailabilityStatus.offline;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) {
      return;
    }

    _requestedInitialLoad = true;
    final authState = context.read<AuthState>();
    if (authState.currentUser == null &&
        authState.profileRefreshState.status == RequestStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.read<AuthState>().currentUser == null) {
          context.read<AuthState>().refreshProfile();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Consumer<AuthState>(
      builder: (context, authState, _) {
        final user = authState.currentUser;
        final refreshState = authState.profileRefreshState;
        final updateState = authState.profileUpdateState;
        final isLoading = user == null && refreshState.isLoading;
        final isSaving = updateState.isLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(_isEditMode ? 'Edit Profile' : 'Profile'),
            centerTitle: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: _isEditMode,
            leading: _isEditMode
                ? IconButton(
                    onPressed: _discardEdits,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                  )
                : null,
            actions: !_isEditMode && user != null
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        child: InkWell(
                          onTap: () => _enterEditMode(user),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.lightGreenSurfaceTint,
                              border: Border.all(
                                color: const Color(0xFFD1FAE5),
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]
                : null,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          body: SafeArea(
            child: isLoading
                ? const _ProfileLoadingView()
                : user == null
                ? _ProfileMissingView(onRetry: authState.refreshProfile)
                : _isEditMode
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: _buildEditMode(
                      context,
                      authState,
                      user,
                      updateState,
                      isSaving,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: authState.refreshProfile,
                    color: tokens.primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                      child: _buildViewMode(context, user),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildViewMode(BuildContext context, UserModel user) {
    final tokens = AppTheme.lightTokens;
    final profile = user.collectorProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
          decoration: BoxDecoration(
            color: tokens.lightGreenSurfaceTint,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _AvatarBadge(profileImage: user.profileImage, size: 86),
                  if (profile != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: tokens.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PillBadge(
                    text: _roleLabel(user.role),
                    backgroundColor: tokens.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  if (profile != null)
                    _PillBadge(
                      text: profile.availabilityStatus.apiValue,
                      backgroundColor: _availabilityColors(
                        profile.availabilityStatus,
                      ).background,
                      foregroundColor: _availabilityColors(
                        profile.availabilityStatus,
                      ).foreground,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (profile != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.lightGreenSurfaceTint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tokens.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE VEHICLE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.vehicleType ?? 'Not specified'}${profile.vehicleType == null ? '' : ' (Medium)'}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    'LP-1202',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (profile != null) const SizedBox(height: 18),
        _SectionHeader(
          icon: Icons.contact_page_outlined,
          label: 'CONTACT INFORMATION',
        ),
        const SizedBox(height: 10),
        _InfoCard(
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'EMAIL ADDRESS',
              value: user.email,
            ),
            const Divider(height: 1),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'PHONE NUMBER',
              value: user.phone,
            ),
            const Divider(height: 1),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'MEMBER SINCE',
              value: _formatMonthYear(user.createdAt),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          icon: Icons.insights_outlined,
          label: 'PERFORMANCE TRACKING',
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                icon: Icons.task_alt_outlined,
                value: '142',
                label: 'Jobs Completed',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.eco_outlined,
                value: '2,450',
                label: 'Eco Points',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _PreferencesRow(),
      ],
    );
  }

  Widget _buildEditMode(
    BuildContext context,
    AuthState authState,
    UserModel user,
    RequestState<UserModel> updateState,
    bool isSaving,
  ) {
    final tokens = AppTheme.lightTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: tokens.lightGreenSurfaceTint,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _AvatarBadge(profileImage: user.profileImage, size: 88),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: tokens.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: tokens.primaryColor,
                ),
                child: const Text(
                  'Change Profile Picture',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (updateState.errorMessage != null &&
            (updateState.fieldErrors == null ||
                updateState.fieldErrors!.isEmpty)) ...[
          ErrorBanner(
            message: updateState.errorMessage!,
            onRetry: _saveProfile,
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldLabel(text: 'FULL NAME'),
              const SizedBox(height: 8),
              _TextFieldShell(
                controller: _nameController,
                hintText: 'John Doe',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                errorText: authState.fieldErrorFor(
                  updateState.fieldErrors,
                  'name',
                ),
              ),
              const SizedBox(height: 14),
              _FieldLabel(text: 'PHONE NUMBER'),
              const SizedBox(height: 8),
              _TextFieldShell(
                controller: _phoneController,
                hintText: '03001234567',
                prefixIcon: Icons.phone_outlined,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                errorText: authState.fieldErrorFor(
                  updateState.fieldErrors,
                  'phone',
                ),
              ),
              if (user.role == UserRole.collector &&
                  user.collectorProfile != null) ...[
                const SizedBox(height: 16),
                _CollectorSettingsCard(
                  vehicleTypeController: _vehicleTypeController,
                  availabilityStatus: _availabilityStatus,
                  onAvailabilityChanged: (value) {
                    setState(() {
                      _availabilityStatus = value;
                    });
                  },
                  vehicleTypeErrorText: authState.fieldErrorFor(
                    updateState.fieldErrors,
                    'vehicleType',
                  ),
                  availabilityErrorText: authState.fieldErrorFor(
                    updateState.fieldErrors,
                    'availabilityStatus',
                  ),
                  enabled: !isSaving,
                ),
              ],
              const SizedBox(height: 20),
              _PrimaryButton(
                text: 'Save Profile',
                isLoading: isSaving,
                onPressed: isSaving ? null : _saveProfile,
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: isSaving ? null : _discardEdits,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                  ),
                  child: const Text('Cancel Changes'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthState>();
    final user = authState.currentUser;
    if (user == null) {
      return;
    }

    final trimmedName = _nameController.text.trim();
    final trimmedPhone = _phoneController.text.trim();
    final currentProfile = user.collectorProfile;

    var changed = trimmedName != user.name || trimmedPhone != user.phone;
    String? vehicleType;
    AvailabilityStatus? availabilityStatus;

    if (user.role == UserRole.collector && currentProfile != null) {
      vehicleType = _vehicleTypeController.text.trim();
      if (vehicleType.isEmpty) {
        vehicleType = null;
      }

      if ((vehicleType ?? '') != (currentProfile.vehicleType ?? '')) {
        changed = true;
      }

      availabilityStatus = _availabilityStatus;
      if (availabilityStatus != currentProfile.availabilityStatus) {
        changed = true;
      }
    }

    if (!changed) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No profile changes to save.')),
        );
      return;
    }

    final success = await authState.updateProfile(
      name: trimmedName,
      phone: trimmedPhone,
      vehicleType: user.role == UserRole.collector ? vehicleType : null,
      availabilityStatus: user.role == UserRole.collector
          ? availabilityStatus
          : null,
    );

    if (!mounted || !success) {
      return;
    }

    setState(() {
      _isEditMode = false;
      final updatedUser = authState.currentUser;
      if (updatedUser != null) {
        _loadFromUser(updatedUser);
      }
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
  }

  void _enterEditMode(UserModel user) {
    _loadFromUser(user);
    setState(() {
      _isEditMode = true;
    });
  }

  void _loadFromUser(UserModel user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone;

    final profile = user.collectorProfile;
    _vehicleTypeController.text = profile?.vehicleType ?? '';
    _availabilityStatus =
        profile?.availabilityStatus ?? AvailabilityStatus.offline;
  }

  void _discardEdits() {
    final user = context.read<AuthState>().currentUser;
    if (user != null) {
      _loadFromUser(user);
    }

    setState(() {
      _isEditMode = false;
    });
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.citizen => 'Household',
      UserRole.collector => 'Collector',
      UserRole.admin => 'Admin',
      UserRole.vendor => 'Vendor',
    };
  }

  String _formatMonthYear(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }

  _BadgeColors _availabilityColors(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.online:
        return const _BadgeColors(
          background: Color(0xFFD6FCE7),
          foreground: Color(0xFF15803D),
        );
      case AvailabilityStatus.busy:
        return const _BadgeColors(
          background: Color(0xFFFEF3C5),
          foreground: Color(0xFFB45309),
        );
      case AvailabilityStatus.offline:
        return const _BadgeColors(
          background: Color(0xFFEFF2F7),
          foreground: Color(0xFF475569),
        );
    }
  }
}

class _CollectorSettingsCard extends StatelessWidget {
  const _CollectorSettingsCard({
    required this.vehicleTypeController,
    required this.availabilityStatus,
    required this.onAvailabilityChanged,
    required this.vehicleTypeErrorText,
    required this.availabilityErrorText,
    required this.enabled,
  });

  final TextEditingController vehicleTypeController;
  final AvailabilityStatus availabilityStatus;
  final ValueChanged<AvailabilityStatus> onAvailabilityChanged;
  final String? vehicleTypeErrorText;
  final String? availabilityErrorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.lightGreenSurfaceTint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tokens.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'COLLECTOR SETTINGS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: const Color(0xFF15803D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FieldLabel(text: 'VEHICLE TYPE'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: vehicleTypeController.text.isEmpty
                ? null
                : vehicleTypeController.text,
            onChanged: enabled
                ? (value) {
                    vehicleTypeController.text = value ?? '';
                  }
                : null,
            decoration: _inputDecoration(
              hintText: 'Select vehicle type',
              prefixIcon: Icons.local_shipping_outlined,
              errorText: vehicleTypeErrorText,
            ),
            items: const [
              DropdownMenuItem(value: 'Bike', child: Text('Bike')),
              DropdownMenuItem(value: 'Motorbike', child: Text('Motorbike')),
              DropdownMenuItem(value: 'Pickup Van', child: Text('Pickup Van')),
              DropdownMenuItem(value: 'Truck', child: Text('Truck')),
            ],
          ),
          const SizedBox(height: 14),
          _FieldLabel(text: 'AVAILABILITY STATUS'),
          const SizedBox(height: 8),
          _AvailabilitySegmentedControl(
            value: availabilityStatus,
            onChanged: enabled ? onAvailabilityChanged : null,
            errorText: availabilityErrorText,
          ),
        ],
      ),
    );
  }
}

class _AvailabilitySegmentedControl extends StatelessWidget {
  const _AvailabilitySegmentedControl({
    required this.value,
    required this.onChanged,
    required this.errorText,
  });

  final AvailabilityStatus value;
  final ValueChanged<AvailabilityStatus>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final options = [
      (AvailabilityStatus.online, 'Online'),
      (AvailabilityStatus.busy, 'Busy'),
      (AvailabilityStatus.offline, 'Offline'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Row(
            children: options
                .map(
                  (option) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _SegmentButton(
                        label: option.$2,
                        selected: value == option.$1,
                        onTap: onChanged == null
                            ? null
                            : () => onChanged!(option.$1),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB91C1C)),
          ),
        ],
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? tokens.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? Colors.white : const Color(0xFF4B5563),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
                children: [
                  Text(text),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
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
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: _inputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        errorText: errorText,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  required IconData prefixIcon,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(prefixIcon, color: const Color(0xFF6B7280)),
    errorText: errorText,
  );
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.profileImage, required this.size});

  final String? profileImage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = profileImage != null && profileImage!.trim().isNotEmpty;
    final imageUrl = profileImage?.trim();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1FAE5), width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFECFDF5),
        backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
        child: hasImage
            ? null
            : const Icon(Icons.person, size: 38, color: Color(0xFF15803D)),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.3,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tokens.lightGreenSurfaceTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tokens.primaryColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesRow extends StatelessWidget {
  const _PreferencesRow();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.settings_outlined, color: tokens.primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'App Preferences',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: tokens.primaryColor,
            ),
            child: const Text(
              'Update',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeColors {
  const _BadgeColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 180, height: 28),
          SizedBox(height: 12),
          SkeletonLoader(width: double.infinity, height: 190),
          SizedBox(height: 12),
          SkeletonLoader(width: double.infinity, height: 160),
          SizedBox(height: 12),
          SkeletonLoader(width: double.infinity, height: 200),
        ],
      ),
    );
  }
}

class _ProfileMissingView extends StatelessWidget {
  const _ProfileMissingView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: EmptyStateView(
        title: 'Profile unavailable',
        body: 'Could not load profile data. Please retry.',
        icon: Icons.person_off,
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    );
  }
}
