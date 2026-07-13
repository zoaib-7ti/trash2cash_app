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

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
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
      context.read<JobsState>().loadFeed(reset: true);
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
    if (!jobsState.feedHasMorePages ||
        jobsState.feedState.status == RequestStatus.loading) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const delta = 200;

    if (currentScroll >= (maxScroll - delta)) {
      jobsState.loadMoreFeed();
    }
  }

  Future<void> _navigateToDetail(String jobId) async {
    final result = await Navigator.pushNamed(
      context,
      '/jobs/detail',
      arguments: jobId,
    );
    if (result == true && mounted) {
      context.read<JobsState>().loadFeed(reset: true);
    }
  }

  Future<void> _acceptJob(JobsState jobsState, String id) async {
    final success = await jobsState.acceptJob(id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMsg = jobsState.acceptState.errorMessage ?? 'Failed to accept job';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
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
              'Available Jobs',
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
                child: _buildBody(jobsState),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(JobsState jobsState) {
    final feedState = jobsState.feedState;
    final jobs = jobsState.feedJobs;
    final tokens = AppTheme.lightTokens;

    // Initial loading with no existing jobs
    if (feedState.status == RequestStatus.loading && jobs.isEmpty) {
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
                    width: 80,
                    height: 32,
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
    if (feedState.status == RequestStatus.success && jobs.isEmpty) {
      return Center(
        child: EmptyStateView(
          icon: Icons.work_off_outlined,
          title: 'No jobs available right now',
          body: 'Check back soon for new pickups.',
        ),
      );
    }

    // Error state with no existing jobs
    if (feedState.errorMessage != null && jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorBanner(
            message: feedState.errorMessage!,
            onRetry: () => jobsState.loadFeed(reset: true),
          ),
        ),
      );
    }

    // Loaded state
    return RefreshIndicator(
      color: tokens.primaryColor,
      onRefresh: () => jobsState.loadFeed(reset: true),
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
            onAccept: () => _acceptJob(jobsState, job.id),
            isAccepting: jobsState.acceptState.isLoading && jobsState.acceptState.data?.id == job.id,
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.onTap,
    required this.onAccept,
    required this.isAccepting,
  });

  final PickupRequestModel job;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
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
            isAccepting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.primaryColor,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Accept',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
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
