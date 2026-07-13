import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/state/request_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/pickup_request_model.dart';
import '../state/jobs_state.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _requestedInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) {
      return;
    }
    _requestedInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<JobsState>().loadMyJobs(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final jobsState = context.read<JobsState>();
    if (!jobsState.myJobsHasMorePages ||
        jobsState.myJobsState.status == RequestStatus.loading) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const delta = 200;

    if (currentScroll >= (maxScroll - delta)) {
      jobsState.loadMoreMyJobs();
    }
  }

  Future<void> _navigateToDetail(String jobId) async {
    final result = await Navigator.pushNamed(
      context,
      '/jobs/detail',
      arguments: jobId,
    );
    if (result == true && mounted) {
      context.read<JobsState>().loadMyJobs(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobsState>(
      builder: (context, jobsState, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              'My Jobs',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            centerTitle: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: jobsState.activeJobStatusFilter == null,
                              onSelected: (_) => jobsState.loadMyJobs(
                                reset: true,
                                statusFilter: null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Accepted',
                              selected: jobsState.activeJobStatusFilter == 'ACCEPTED',
                              onSelected: (_) => jobsState.loadMyJobs(
                                reset: true,
                                statusFilter: 'ACCEPTED',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'In Progress',
                              selected: jobsState.activeJobStatusFilter == 'IN_PROGRESS',
                              onSelected: (_) => jobsState.loadMyJobs(
                                reset: true,
                                statusFilter: 'IN_PROGRESS',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Completed',
                              selected: jobsState.activeJobStatusFilter == 'COMPLETED',
                              onSelected: (_) => jobsState.loadMyJobs(
                                reset: true,
                                statusFilter: 'COMPLETED',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: _buildBody(jobsState)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(JobsState jobsState) {
    final myJobsState = jobsState.myJobsState;
    final jobs = jobsState.myJobs;
    final tokens = AppTheme.lightTokens;

    // Initial loading with no existing jobs
    if (myJobsState.status == RequestStatus.loading && jobs.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SkeletonLoader(
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        SkeletonLoader(
                          width: 120,
                          height: 16,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        SizedBox(height: 8),
                        SkeletonLoader(
                          width: 180,
                          height: 14,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  SkeletonLoader(
                    width: 70,
                    height: 28,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: 4,
      );
    }

    // Empty state
    if (myJobsState.status == RequestStatus.success && jobs.isEmpty) {
      String title, body;
      if (jobsState.activeJobStatusFilter == null) {
        title = 'No jobs yet';
        body = 'Accept an available job from the feed to get started.';
      } else {
        final label = jobsState.activeJobStatusFilter == 'IN_PROGRESS'
            ? 'in progress'
            : jobsState.activeJobStatusFilter!.toLowerCase();
        title = 'No $label jobs';
        body = 'You don\'t have any $label jobs right now.';
      }
      return Center(
        child: EmptyStateView(
          icon: Icons.work_outline,
          title: title,
          body: body,
        ),
      );
    }

    // Error state with no existing jobs
    if (myJobsState.errorMessage != null && jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorBanner(
            message: myJobsState.errorMessage!,
            onRetry: () => jobsState.loadMyJobs(reset: true),
          ),
        ),
      );
    }

    // Loaded state
    return RefreshIndicator(
      color: tokens.primaryColor,
      onRefresh: () => jobsState.loadMyJobs(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _JobCard(
            job: job,
            onTap: () => _navigateToDetail(job.id),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: tokens.filterChipTheme.backgroundColor,
      selectedColor: tokens.filterChipTheme.selectedColor,
      disabledColor: tokens.filterChipTheme.disabledColor,
      padding: tokens.filterChipTheme.padding,
      labelStyle: selected
          ? tokens.filterChipTheme.secondaryLabelStyle
          : tokens.filterChipTheme.labelStyle,
      side: tokens.filterChipTheme.side,
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});

  final PickupRequestModel job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    final statusBadge = tokens.statusBadgeStyles[job.status]!;
    final imageUrl = '${ApiConstants.uploadsBaseUrl}${job.imageUrl}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF6B7280),
                        size: 24,
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
                          color: Color(0xFF6B7280),
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.materialTypes.isEmpty
                        ? 'General waste'
                        : job.materialTypes.length <= 2
                            ? job.materialTypes.map((m) => m.label).join(', ')
                            : '${job.materialTypes.take(2).map((m) => m.label).join(', ')} +${job.materialTypes.length - 2} more',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.pickupAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: statusBadge.background,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                _statusToBadgeText(job.status),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: statusBadge.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
