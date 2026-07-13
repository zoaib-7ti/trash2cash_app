import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shadow_card_scaffold_body.dart';
import '../state/jobs_state.dart';

class CompleteJobScreen extends StatefulWidget {
  const CompleteJobScreen({super.key});

  @override
  State<CompleteJobScreen> createState() => _CompleteJobScreenState();
}

class _CompleteJobScreenState extends State<CompleteJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  String? _jobId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _jobId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit(JobsState jobsState) async {
    if (_jobId == null) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    double? actualWeight;
    if (_weightController.text.trim().isNotEmpty) {
      actualWeight = double.tryParse(_weightController.text.trim());
    }

    final success = await jobsState.updateJobStatus(
      _jobId!,
      'COMPLETED',
      actualWeight: actualWeight,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job marked as completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final error = jobsState.statusUpdateState.errorMessage ?? 'Failed to complete job';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Complete Job'),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        scrolledUnderElevation: 0,
      ),
      body: Consumer<JobsState>(
        builder: (context, jobsState, _) {
          final isLoading = jobsState.statusUpdateState.isLoading;

          return ShadowCardScaffoldBody(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Collection Weight',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please verify the actual weight collected if different from the estimate.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _weightController,
                      label: 'ACTUAL WEIGHT (kg)',
                      hintText: 'Leave blank to keep the estimate',
                      prefixIcon: Icons.scale_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffixText: 'kg',
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value.trim()) == null) {
                            return 'Enter a valid decimal number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: null,
                            icon: const Icon(Icons.camera_alt_outlined),
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add completion photo',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Coming in a future update',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton(
                            onPressed: () => _submit(jobsState),
                            style: FilledButton.styleFrom(
                              backgroundColor: tokens.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Confirm Completion'),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
