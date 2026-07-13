import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/pickup_request_model.dart';
import '../../../data/models/household_summary_model.dart';
import '../state/jobs_state.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _requestedInitialLoad = false;
  String? _jobId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) {
      return;
    }
    _requestedInitialLoad = true;
    _jobId = ModalRoute.of(context)?.settings.arguments as String?;
    if (_jobId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<JobsState>().loadJobDetail(_jobId!);
        }
      });
    }
  }

  Future<void> _startJob(JobsState jobsState) async {
    if (_jobId == null) return;
    final success = await jobsState.updateJobStatus(_jobId!, 'IN_PROGRESS');
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job started!'),
          backgroundColor: Colors.green,
        ),
      );
      jobsState.loadJobDetail(_jobId!);
    } else {
      final error = jobsState.statusUpdateState.errorMessage ?? 'Failed to start job';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markComplete() async {
    if (_jobId == null) return;
    final completed = await Navigator.pushNamed(
      context,
      '/jobs/complete',
      arguments: _jobId,
    );
    if (completed == true && mounted) {
      context.read<JobsState>().loadJobDetail(_jobId!);
    }
  }

  Future<void> _acceptJob(JobsState jobsState) async {
    if (_jobId == null) return;
    final success = await jobsState.acceptJob(_jobId!);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final error = jobsState.acceptState.errorMessage ?? 'Failed to accept job';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobsState>(
      builder: (context, jobsState, _) {
        final detailState = jobsState.jobDetailState;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Job Details'),
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
                  return const _JobDetailLoadingView();
                }
                if (detailState.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ErrorBanner(
                        message: detailState.errorMessage!,
                        onRetry: () {
                          if (_jobId != null) {
                            jobsState.loadJobDetail(_jobId!);
                          }
                        },
                      ),
                    ),
                  );
                }
                final job = detailState.data;
                if (job == null) {
                  return const SizedBox.shrink();
                }
                return _JobDetailLoadedView(
                  job: job,
                  onStart: () => _startJob(jobsState),
                  isStarting: jobsState.statusUpdateState.isLoading,
                  onComplete: _markComplete,
                  onAccept: () => _acceptJob(jobsState),
                  isAccepting: jobsState.acceptState.isLoading,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _JobDetailLoadingView extends StatelessWidget {
  const _JobDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonLoader(width: double.infinity, height: 220),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(width: double.infinity, height: 80),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(width: double.infinity, height: 240),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(width: double.infinity, height: 120),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _JobDetailLoadedView extends StatelessWidget {
  const _JobDetailLoadedView({
    required this.job,
    required this.onStart,
    required this.isStarting,
    required this.onComplete,
    required this.onAccept,
    required this.isAccepting,
  });

  final PickupRequestModel job;
  final VoidCallback onStart;
  final bool isStarting;
  final VoidCallback onComplete;
  final VoidCallback onAccept;
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderImageSection(job: job),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusSection(job: job),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  _InfoCard(job: job),
                  if (job.citizen != null) ...[
                    const SizedBox(height: 20),
                    _HouseholdInfoCard(citizen: job.citizen!),
                  ],
                  const SizedBox(height: 24),
                  _buildActionArea(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context) {
    if (job.status == PickupStatus.pending) {
      return isAccepting
          ? const Center(child: CircularProgressIndicator())
          : FilledButton(
              onPressed: onAccept,
              child: const Text('Accept Job'),
            );
    }
    if (job.status == PickupStatus.accepted) {
      return isStarting
          ? const Center(child: CircularProgressIndicator())
          : FilledButton(
              onPressed: onStart,
              child: const Text('Start Job'),
            );
    }
    if (job.status == PickupStatus.inProgress) {
      return FilledButton(
        onPressed: onComplete,
        child: const Text('Mark Complete'),
      );
    }
    if (job.status == PickupStatus.completed) {
      return _CompletedBanner(job: job);
    }
    return const SizedBox.shrink();
  }
}

class _HeaderImageSection extends StatelessWidget {
  const _HeaderImageSection({required this.job});

  final PickupRequestModel job;

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${ApiConstants.uploadsBaseUrl}${job.imageUrl}';
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Icon(
              Icons.image_outlined,
              color: Color(0xFF6B7280),
              size: 48,
            ),
          );
        },
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.job});

  final PickupRequestModel job;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    final stages = [
      PickupStatus.accepted,
      PickupStatus.inProgress,
      PickupStatus.completed,
    ];
    final stageLabels = {
      PickupStatus.accepted: 'Accepted',
      PickupStatus.inProgress: 'In Progress',
      PickupStatus.completed: 'Completed',
    };
    final currentIndex = stages.indexOf(job.status);

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
            'Last updated: ${_formatDateTime(job.updatedAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.job});

  final PickupRequestModel job;

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
            value: job.pickupAddress,
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.recycling_outlined,
            label: 'MATERIAL TYPE',
            value: job.materialTypes.isEmpty
                ? 'Not specified'
                : job.materialTypes.map((m) => m.label).join(', '),
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.scale_outlined,
            label: 'ESTIMATED WEIGHT',
            value: job.estimatedWeight != null
                ? '${job.estimatedWeight} kg'
                : 'Not specified',
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'SCHEDULED TIME',
            value: job.scheduledTime != null
                ? _formatDateTime(job.scheduledTime!)
                : 'Not scheduled',
          ),
          const Divider(height: 1),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'REQUESTED ON',
            value: _formatDateTime(job.createdAt),
          ),
        ],
      ),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
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

class _HouseholdInfoCard extends StatelessWidget {
  const _HouseholdInfoCard({required this.citizen});

  final HouseholdSummaryModel citizen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOUSEHOLD INFO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AvatarBadge(profileImage: citizen.profileImage, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      citizen.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      citizen.phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner({required this.job});

  final PickupRequestModel job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Completed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF166534),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last updated: ${_formatDateTime(job.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF15803D),
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

String _formatDateTime(DateTime dateTime) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final period = dateTime.hour < 12 ? 'AM' : 'PM';
  return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
}
