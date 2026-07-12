import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/state/request_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/pickup_request_model.dart';
import '../state/pickups_state.dart';

class PickupListScreen extends StatefulWidget {
  const PickupListScreen({super.key});

  @override
  State<PickupListScreen> createState() => _PickupListScreenState();
}

class _PickupListScreenState extends State<PickupListScreen> {
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
      context.read<PickupsState>().loadPickups(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pickupsState = context.read<PickupsState>();
    if (!pickupsState.hasMorePages ||
        pickupsState.listState.status == RequestStatus.loading) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const delta = 200;

    if (currentScroll >= (maxScroll - delta)) {
      pickupsState.loadMore();
    }
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.pushNamed(context, '/pickups/create');
    if (result == true && mounted) {
      context.read<PickupsState>().loadPickups(reset: true);
    }
  }

  Future<void> _navigateToDetail(String pickupId) async {
    final result = await Navigator.pushNamed(
      context,
      '/pickups/detail',
      arguments: pickupId,
    );
    if (result == true && mounted) {
      context.read<PickupsState>().loadPickups(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    return Consumer<PickupsState>(
      builder: (context, pickupsState, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              'My Pickups',
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _navigateToCreate,
            icon: const Icon(Icons.add),
            label: const Text('New Pickup'),
            backgroundColor: tokens.primaryColor,
          ),
          body: Column(
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
                        selected: pickupsState.activeStatusFilter == null,
                        onSelected: (_) => pickupsState.loadPickups(
                          reset: true,
                          statusFilter: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...PickupStatus.values.map((status) {
                        final label = _statusToLabel(status);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: label,
                            selected: pickupsState.activeStatusFilter == status,
                            onSelected: (_) => pickupsState.loadPickups(
                              reset: true,
                              statusFilter: status,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Expanded(child: _buildBody(pickupsState)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(PickupsState pickupsState) {
    final listState = pickupsState.listState;
    final pickups = pickupsState.pickups;
    final tokens = AppTheme.lightTokens;

    // Initial loading with no existing pickups
    if (listState.status == RequestStatus.loading && pickups.isEmpty) {
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
    if (listState.status == RequestStatus.success && pickups.isEmpty) {
      String title, body;
      if (pickupsState.activeStatusFilter == null) {
        title = 'No pickups yet';
        body = 'Request your first collection to get started.';
      } else {
        final label = _statusToLabel(pickupsState.activeStatusFilter!);
        title = 'No $label pickups';
        body = 'You don\'t have any $label pickups right now.';
      }
      return Center(
        child: EmptyStateView(
          icon: Icons.recycling,
          title: title,
          body: body,
          actionLabel: 'Request a Pickup',
          onAction: _navigateToCreate,
        ),
      );
    }

    // Error state with no existing pickups
    if (listState.errorMessage != null && pickups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorBanner(
            message: listState.errorMessage!,
            onRetry: () => pickupsState.loadPickups(reset: true),
          ),
        ),
      );
    }

    // Loaded state
    return RefreshIndicator(
      color: tokens.primaryColor,
      onRefresh: () => pickupsState.loadPickups(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: pickups.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pickup = pickups[index];
          return _PickupCard(
            pickup: pickup,
            onTap: () => _navigateToDetail(pickup.id),
          );
        },
      ),
    );
  }

  String _statusToLabel(PickupStatus status) {
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

class _PickupCard extends StatelessWidget {
  const _PickupCard({required this.pickup, required this.onTap});

  final PickupRequestModel pickup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;
    final statusBadge = tokens.statusBadgeStyles[pickup.status]!;
    final imageUrl = '${ApiConstants.uploadsBaseUrl}${pickup.imageUrl}';

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
                    pickup.materialTypes.isEmpty
                        ? 'General waste'
                        : pickup.materialTypes.length <= 2
                            ? pickup.materialTypes.map((m) => m.label).join(', ')
                            : '${pickup.materialTypes.take(2).map((m) => m.label).join(', ')} +${pickup.materialTypes.length - 2} more',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pickup.pickupAddress,
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
                _statusToBadgeText(pickup.status),
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
