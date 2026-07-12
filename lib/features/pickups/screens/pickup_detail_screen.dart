import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/pickup_request_model.dart';
import '../state/pickups_state.dart';

class PickupDetailScreen extends StatefulWidget {
  const PickupDetailScreen({super.key});

  @override
  State<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends State<PickupDetailScreen> {
  bool _requestedInitialLoad = false;
  String? _pickupId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) {
      return;
    }
    _requestedInitialLoad = true;
    _pickupId = ModalRoute.of(context)?.settings.arguments as String?;
    if (_pickupId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PickupsState>().loadPickupDetail(_pickupId!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PickupsState>(
      builder: (context, pickupsState, _) {
        final detailState = pickupsState.detailState;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pickup Details'),
            centerTitle: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (detailState.isLoading) {
                  return const _PickupDetailLoadingView();
                }
                if (detailState.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ErrorBanner(
                        message: detailState.errorMessage!,
                        onRetry: () {
                          if (_pickupId != null) {
                            pickupsState.loadPickupDetail(_pickupId!);
                          }
                        },
                      ),
                    ),
                  );
                }
                final pickup = detailState.data;
                if (pickup == null) {
                  return const SizedBox.shrink();
                }
                return _PickupDetailLoadedView(pickup: pickup);
              },
            ),
          ),
        );
      },
    );
  }
}

class _PickupDetailLoadingView extends StatelessWidget {
  const _PickupDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonLoader(width: double.infinity, height: 220),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(width: double.infinity, height: 80),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(width: double.infinity, height: 240),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(width: double.infinity, height: 160),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PickupDetailLoadedView extends StatelessWidget {
  const _PickupDetailLoadedView({required this.pickup});

  final PickupRequestModel pickup;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderImageSection(pickup: pickup),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StatusSection(pickup: pickup),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _InfoCard(pickup: pickup),
          ),
          if (pickup.collector != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CollectorCard(collector: pickup.collector!),
            ),
          ],
          if (pickup.status == PickupStatus.pending) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActionButtons(pickup: pickup),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderImageSection extends StatelessWidget {
  const _HeaderImageSection({required this.pickup});

  final PickupRequestModel pickup;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    final statusBadge = tokens.statusBadgeStyles[pickup.status]!;
    final imageUrl = '${ApiConstants.uploadsBaseUrl}${pickup.imageUrl}';

    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Color(0xFF6B7280),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: statusBadge.background,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                _statusToBadgeText(pickup.status),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: statusBadge.foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusToBadgeText(PickupStatus status) {
    switch (status) {
      case PickupStatus.pending:
        return 'Pending';
      case PickupStatus.accepted:
        return 'Accepted';
      case PickupStatus.inProgress:
        return 'In Progress';
      case PickupStatus.completed:
        return 'Completed';
      case PickupStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.pickup});

  final PickupRequestModel pickup;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    if (pickup.status == PickupStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup Cancelled',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last updated: ${_formatDateTime(pickup.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final stages = [
      PickupStatus.pending,
      PickupStatus.accepted,
      PickupStatus.inProgress,
      PickupStatus.completed,
    ];
    final stageLabels = {
      PickupStatus.pending: 'Pending',
      PickupStatus.accepted: 'Accepted',
      PickupStatus.inProgress: 'In Progress',
      PickupStatus.completed: 'Completed',
    };
    final currentIndex = stages.indexOf(pickup.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                children: stages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final isActive = index <= currentIndex;
                  final isLast = index == stages.length - 1;
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive
                                ? tokens.primaryColor
                                : const Color(0xFFE5E7EB),
                            shape: BoxShape.circle,
                          ),
                          child: isActive
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: index < currentIndex
                                    ? tokens.primaryColor
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: stages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stageStatus = entry.value;
                  final isLast = index == stages.length - 1;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            stageLabels[stageStatus]!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: index <= currentIndex
                                      ? const Color(0xFF111827)
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (!isLast) const SizedBox(width: 4 + 16),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Last updated: ${_formatDateTime(pickup.updatedAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.pickup});

  final PickupRequestModel pickup;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'ADDRESS',
            value: pickup.pickupAddress,
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.recycling_outlined,
            label: 'MATERIAL TYPE',
            value: pickup.materialType?.label ?? 'Not specified',
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.scale_outlined,
            label: 'ESTIMATED WEIGHT',
            value: pickup.estimatedWeight != null
                ? '${pickup.estimatedWeight} kg'
                : 'Not specified',
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'SCHEDULED TIME',
            value: pickup.scheduledTime != null
                ? _formatDateTime(pickup.scheduledTime!)
                : 'Not scheduled',
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'REQUESTED ON',
            value: _formatDateTime(pickup.createdAt),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
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

class _CollectorCard extends StatelessWidget {
  const _CollectorCard({required this.collector});

  final dynamic collector;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.lightGreenSurfaceTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Color(0xFF15803D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ASSIGNED COLLECTOR',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: const Color(0xFF15803D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _AvatarBadge(profileImage: collector.profileImage, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collector.name ?? 'Collector',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (collector.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            collector.phone!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (collector.vehicleType != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF2F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car_outlined,
                    size: 18,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Vehicle: ${collector.vehicleType}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.all(2),
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
            : const Icon(Icons.person, size: 28, color: Color(0xFF15803D)),
      ),
    );
  }
}

class _ActionButtons extends StatefulWidget {
  const _ActionButtons({required this.pickup});

  final PickupRequestModel pickup;

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/pickups/edit',
                arguments: widget.pickup.id,
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
              side: BorderSide(color: tokens.primaryColor),
              foregroundColor: tokens.primaryColor,
              textStyle: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            child: const Text('Edit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _isCancelling
                ? null
                : () async {
                    final pickupsState = context.read<PickupsState>();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel Pickup'),
                        content: const Text(
                          'Cancel this pickup request? This can\'t be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Keep Request'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                            ),
                            child: const Text('Yes, Cancel'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !mounted) return;
                    
                    setState(() {
                      _isCancelling = true;
                    });
                    
                    final success = await pickupsState.cancelPickup(
                      widget.pickup.id,
                    );
                    
                    if (!mounted) return;
                    
                    if (success) {
                      navigator.pop(true);
                    } else {
                      final errorMessage =
                          pickupsState.cancelState.errorMessage;
                      scaffoldMessenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              errorMessage ??
                                  'Failed to cancel pickup. Please try again.',
                            ),
                          ),
                        );
                    }
                    
                    setState(() {
                      _isCancelling = false;
                    });
                  },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
              textStyle: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            child: _isCancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Cancel Pickup'),
          ),
        ),
      ],
    );
  }
}
