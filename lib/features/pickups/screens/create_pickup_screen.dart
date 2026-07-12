import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/state/request_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/shadow_card_scaffold_body.dart';
import '../../../../data/models/pickup_request_model.dart';
import '../state/pickups_state.dart';

class CreatePickupScreen extends StatefulWidget {
  const CreatePickupScreen({super.key});

  @override
  State<CreatePickupScreen> createState() => _CreatePickupScreenState();
}

class _CreatePickupScreenState extends State<CreatePickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _estimatedWeightController = TextEditingController();
  DateTime? _scheduledTime;
  final List<PickupMaterialType> _selectedMaterialTypes = [];
  File? _imageFile;
  bool _triedSubmit = false;
  List<ApiFieldError>? _fieldErrors;

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _estimatedWeightController.dispose();
    super.dispose();
  }

  String? _errorTextFor(String field) {
    if (_fieldErrors == null) {
      return null;
    }
    for (final error in _fieldErrors!) {
      if (error.field == field) {
        return error.message;
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.of(context).pop();
                final image = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (image != null && mounted) {
                  setState(() {
                    _imageFile = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null && mounted) {
                  setState(() {
                    _imageFile = File(image.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }
    return null;
  }

  String? _validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }
    try {
      final lat = double.parse(value.trim());
      if (lat < -90 || lat > 90) {
        return 'Latitude must be between -90 and 90';
      }
      return null;
    } catch (_) {
      return 'Invalid latitude';
    }
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }
    try {
      final lng = double.parse(value.trim());
      if (lng < -180 || lng > 180) {
        return 'Longitude must be between -180 and 180';
      }
      return null;
    } catch (_) {
      return 'Invalid longitude';
    }
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    try {
      final weight = double.parse(value.trim());
      if (weight <= 0) {
        return 'Weight must be positive';
      }
      return null;
    } catch (_) {
      return 'Invalid weight';
    }
  }

  bool _validate() {
    bool isValid = true;

    if (_imageFile == null) {
      isValid = false;
    }

    if (_selectedMaterialTypes.isEmpty) {
      isValid = false;
    }

    return isValid;
  }

  Future<void> _submit() async {
    setState(() {
      _triedSubmit = true;
    });

    if (!_formKey.currentState!.validate() || !_validate()) {
      setState(() {});
      return;
    }

    final pickupsState = context.read<PickupsState>();
    final success = await pickupsState.createPickup(
      imageFile: _imageFile!,
      pickupAddress: _addressController.text.trim(),
      pickupLat: double.parse(_latitudeController.text.trim()),
      pickupLng: double.parse(_longitudeController.text.trim()),
      scheduledTimeIso: _scheduledTime?.toUtc().toIso8601String(),
      materialTypes: _selectedMaterialTypes.map((t) => t.apiValue).toList(),
      estimatedWeight: _estimatedWeightController.text.isNotEmpty
          ? double.parse(_estimatedWeightController.text.trim())
          : null,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _fieldErrors = pickupsState.createState.fieldErrors;
      });
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
              'New Pickup Request',
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
          ),
          body: ShadowCardScaffoldBody(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Error banner
                  if (pickupsState.createState.errorMessage != null) ...[
                    ErrorBanner(
                      message: pickupsState.createState.errorMessage!,
                      onRetry: _submit,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Photo card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'PHOTO'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _triedSubmit && _imageFile == null
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFFD1D5DB),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 48,
                                        color: Color(0xFF6B7280),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Add a photo of the waste',
                                        style: TextStyle(
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (_triedSubmit && _imageFile == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Please add a photo of the waste',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFFB91C1C)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'LOCATION'),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _addressController,
                          label: 'ADDRESS',
                          hintText: 'e.g. 123 Main Street, City',
                          prefixIcon: Icons.location_on_outlined,
                          errorText: _errorTextFor('pickupAddress'),
                          validator: _validateAddress,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Pick on Map'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Or enter coordinates manually',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _latitudeController,
                                label: 'LATITUDE',
                                hintText: 'e.g. 40.7128',
                                prefixIcon: Icons.my_location_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                errorText: _errorTextFor('pickupLat'),
                                validator: _validateLatitude,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _longitudeController,
                                label: 'LONGITUDE',
                                hintText: 'e.g. -74.0060',
                                prefixIcon: Icons.my_location_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                errorText: _errorTextFor('pickupLng'),
                                validator: _validateLongitude,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find this via Google Maps → long-press a point → copy coordinates.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Material type card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'MATERIAL TYPE *'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PickupMaterialType.values.map((type) {
                            final isSelected = _selectedMaterialTypes.contains(
                              type,
                            );
                            return FilterChip(
                              label: Text(type.label),
                              avatar: Icon(type.icon, size: 18),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedMaterialTypes.add(type);
                                  } else {
                                    _selectedMaterialTypes.remove(type);
                                  }
                                });
                              },
                              backgroundColor:
                                  tokens.filterChipTheme.backgroundColor,
                              selectedColor:
                                  tokens.filterChipTheme.selectedColor,
                              disabledColor:
                                  tokens.filterChipTheme.disabledColor,
                              padding: tokens.filterChipTheme.padding,
                              labelStyle: isSelected
                                  ? tokens.filterChipTheme.secondaryLabelStyle
                                  : tokens.filterChipTheme.labelStyle,
                              side: tokens.filterChipTheme.side,
                            );
                          }).toList(),
                        ),
                        if (_triedSubmit && _selectedMaterialTypes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Select at least one material type',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFFB91C1C)),
                            ),
                          ),
                        if (_errorTextFor('materialTypes') != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorTextFor('materialTypes')!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFFB91C1C)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Schedule card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'SCHEDULED TIME'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _scheduledTime ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null && context.mounted) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  _scheduledTime ?? DateTime.now(),
                                ),
                              );
                              if (time != null) {
                                setState(() {
                                  _scheduledTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _errorTextFor('scheduledTime') != null
                                    ? tokens.errorBannerBackgroundColor
                                    : const Color(0xFFD1D5DB),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _scheduledTime != null
                                            ? DateFormat.yMMMd()
                                                  .add_jm()
                                                  .format(_scheduledTime!)
                                            : 'Tap to select date and time',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: _scheduledTime != null
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFF9CA3AF),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_scheduledTime != null)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF6B7280),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _scheduledTime = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (_errorTextFor('scheduledTime') != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorTextFor('scheduledTime')!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFFB91C1C)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Weight card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'ESTIMATED WEIGHT'),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _estimatedWeightController,
                          label: 'WEIGHT',
                          hintText: 'e.g. 5.5',
                          prefixIcon: Icons.scale_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffixText: 'kg',
                          errorText: _errorTextFor('estimatedWeight'),
                          validator: _validateWeight,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit button
                  _PrimaryButton(
                    text: 'Request Pickup',
                    isLoading:
                        pickupsState.createState.status ==
                        RequestStatus.loading,
                    onPressed:
                        pickupsState.createState.status == RequestStatus.loading
                        ? null
                        : _submit,
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
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.lightTokens.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
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
