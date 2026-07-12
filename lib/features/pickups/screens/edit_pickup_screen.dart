import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/state/request_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../data/models/pickup_request_model.dart';
import '../state/pickups_state.dart';
import '../widgets/pickup_form_fields.dart';

class EditPickupScreen extends StatefulWidget {
  const EditPickupScreen({super.key});

  @override
  State<EditPickupScreen> createState() => _EditPickupScreenState();
}

class _EditPickupScreenState extends State<EditPickupScreen> {
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _estimatedWeightController = TextEditingController();
  DateTime? _scheduledTime;
  PickupMaterialType? _selectedMaterialType;
  List<ApiFieldError>? _fieldErrors;
  bool _requestedInitialLoad = false;
  String? _pickupId;
  PickupRequestModel? _originalPickup;

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _estimatedWeightController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) return;
    _requestedInitialLoad = true;
    _pickupId = ModalRoute.of(context)?.settings.arguments as String?;
    if (_pickupId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<PickupsState>().loadPickupDetail(_pickupId!);
      });
    }
  }

  void _populateForm(PickupRequestModel pickup) {
    _originalPickup = pickup;
    _addressController.text = pickup.pickupAddress;
    _latitudeController.text = pickup.pickupLat.toString();
    _longitudeController.text = pickup.pickupLng.toString();
    _scheduledTime = pickup.scheduledTime;
    _selectedMaterialType = pickup.materialType;
    _estimatedWeightController.text = pickup.estimatedWeight?.toString() ?? '';
  }

  String? _errorTextFor(String field) {
    if (_fieldErrors != null) {
      for (final error in _fieldErrors!) {
        if (error.field == field) {
          return error.message;
        }
      }
    }
    if (field == 'estimatedWeight' &&
        _originalPickup?.estimatedWeight != null &&
        _estimatedWeightController.text.trim().isEmpty) {
      return "Can't be cleared once set";
    }
    return null;
  }

  bool _validate() {
    bool isValid = true;

    if (_addressController.text.trim().length < 5) {
      isValid = false;
    }

    try {
      final lat = double.tryParse(_latitudeController.text.trim());
      final lng = double.tryParse(_longitudeController.text.trim());
      if (lat == null || lng == null) {
        isValid = false;
      }
    } catch (_) {
      isValid = false;
    }

    if (_originalPickup?.estimatedWeight != null &&
        _estimatedWeightController.text.trim().isEmpty) {
      isValid = false;
    } else {
      final estimatedWeight = double.tryParse(
        _estimatedWeightController.text.trim(),
      );
      if (estimatedWeight != null && estimatedWeight <= 0) {
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      setState(() {});
      return;
    }
    final pickupsState = context.read<PickupsState>();

    final changes = <String, dynamic>{};

    final newAddress = _addressController.text.trim();
    if (newAddress != _originalPickup?.pickupAddress) {
      changes['pickupAddress'] = newAddress;
    }

    final newLat = double.parse(_latitudeController.text.trim());
    if (newLat != _originalPickup?.pickupLat) {
      changes['pickupLat'] = newLat;
    }

    final newLng = double.parse(_longitudeController.text.trim());
    if (newLng != _originalPickup?.pickupLng) {
      changes['pickupLng'] = newLng;
    }

    if (_scheduledTime != _originalPickup?.scheduledTime) {
      if (_scheduledTime != null) {
        changes['scheduledTime'] = _scheduledTime!.toUtc().toIso8601String();
      } else if (_originalPickup?.scheduledTime == null) {
        // Only omit, since we can't clear if there was a value
      }
    }

    if (_selectedMaterialType != _originalPickup?.materialType) {
      if (_selectedMaterialType != null) {
        changes['materialType'] = _selectedMaterialType!.apiValue;
      } else if (_originalPickup?.materialType == null) {
        // Only omit if there was no original value
      }
    }

    final newWeightText = _estimatedWeightController.text.trim();
    final newWeight = newWeightText.isEmpty
        ? null
        : double.tryParse(newWeightText);
    if (newWeight != _originalPickup?.estimatedWeight) {
      if (newWeight != null) {
        changes['estimatedWeight'] = newWeight;
      } else if (_originalPickup?.estimatedWeight == null) {
        // Omit only if no original value
      }
    }

    if (changes.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pop(false);
      return;
    }

    final success = await pickupsState.updatePickup(_pickupId!, changes);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _fieldErrors = pickupsState.updateState.fieldErrors;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PickupsState>(
      builder: (context, pickupsState, child) {
        final detailState = pickupsState.detailState;
        final updateState = pickupsState.updateState;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Pickup'),
            centerTitle: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            scrolledUnderElevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (context) {
                if (detailState.isLoading) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SkeletonLoader(width: double.infinity, height: 200),
                      const SizedBox(height: 16),
                      const SkeletonLoader(width: double.infinity, height: 50),
                      const SizedBox(height: 12),
                      const SkeletonLoader(width: double.infinity, height: 50),
                      const SizedBox(height: 12),
                      const SkeletonLoader(width: double.infinity, height: 150),
                      const SizedBox(height: 24),
                      const SkeletonLoader(width: double.infinity, height: 60),
                    ],
                  );
                }

                if (detailState.errorMessage != null) {
                  return Center(
                    child: ErrorBanner(
                      message: detailState.errorMessage!,
                      onRetry: () {
                        if (_pickupId != null) {
                          pickupsState.loadPickupDetail(_pickupId!);
                        }
                      },
                    ),
                  );
                }

                final pickup = detailState.data;

                if (pickup == null) {
                  return const SizedBox.shrink();
                }

                if (_originalPickup == null) {
                  _populateForm(pickup);
                }

                if (pickup.status != PickupStatus.pending) {
                  return EmptyStateView(
                    icon: Icons.edit_off_outlined,
                    title: 'This pickup can no longer be edited',
                    body: 'Only pending pickups can be edited.',
                    actionLabel: 'Back',
                    onAction: () => Navigator.of(context).pop(),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (updateState.errorMessage != null) ...[
                      Builder(
                        builder: (context) {
                          if (updateState.statusCode == 400) {
                            return ErrorBanner(
                              message: updateState.errorMessage!,
                              onRetry: () => Navigator.of(context).pop(),
                            );
                          }
                          return ErrorBanner(
                            message: updateState.errorMessage!,
                            onRetry: _submit,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          '${ApiConstants.uploadsBaseUrl}${pickup.imageUrl}',
                          fit: BoxFit.cover,
                          width: double.infinity,
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Photo can\'t be changed after submission',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PickupFormFields(
                      addressController: _addressController,
                      latitudeController: _latitudeController,
                      longitudeController: _longitudeController,
                      scheduledTime: _scheduledTime,
                      onScheduledTimeChanged: (value) {
                        setState(() {
                          _scheduledTime = value;
                        });
                      },
                      selectedMaterialType: _selectedMaterialType,
                      onMaterialTypeChanged: (value) {
                        setState(() {
                          _selectedMaterialType = value;
                        });
                      },
                      estimatedWeightController: _estimatedWeightController,
                      errorTextFor: _errorTextFor,
                      isEditMode: true,
                      scheduledTimeHasServerValue: pickup.scheduledTime != null,
                      materialTypeHasServerValue: pickup.materialType != null,
                      estimatedWeightHasServerValue:
                          pickup.estimatedWeight != null,
                    ),
                    const SizedBox(height: 24),
                    _PrimaryButton(
                      text: 'Save Changes',
                      isLoading: updateState.status == RequestStatus.loading,
                      onPressed: updateState.status == RequestStatus.loading
                          ? null
                          : _submit,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: updateState.status == RequestStatus.loading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: const Text('Cancel Changes'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
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
            : Text(text),
      ),
    );
  }
}
