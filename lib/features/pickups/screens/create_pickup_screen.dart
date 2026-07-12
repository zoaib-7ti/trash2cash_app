import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/state/request_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../data/models/pickup_request_model.dart';
import '../state/pickups_state.dart';
import '../widgets/pickup_form_fields.dart';

class CreatePickupScreen extends StatefulWidget {
  const CreatePickupScreen({super.key});

  @override
  State<CreatePickupScreen> createState() => _CreatePickupScreenState();
}

class _CreatePickupScreenState extends State<CreatePickupScreen> {
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _estimatedWeightController = TextEditingController();
  DateTime? _scheduledTime;
  PickupMaterialType? _selectedMaterialType;
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

  bool _validate() {
    bool isValid = true;

    // Address: min 5 characters
    if (_addressController.text.trim().length < 5) {
      isValid = false;
    }

    // Latitude and longitude must be valid doubles if provided
    try {
      final lat = double.tryParse(_latitudeController.text.trim());
      final lng = double.tryParse(_longitudeController.text.trim());
      if (lat == null || lng == null) {
        isValid = false;
      }
    } catch (_) {
      isValid = false;
    }

    // Estimated weight must be positive if provided
    final estimatedWeight = double.tryParse(
      _estimatedWeightController.text.trim(),
    );
    if (estimatedWeight != null && estimatedWeight <= 0) {
      isValid = false;
    }

    // Image required
    if (_imageFile == null) {
      isValid = false;
    }

    return isValid;
  }

  Future<void> _submit() async {
    setState(() {
      _triedSubmit = true;
    });
    if (!_validate()) {
      setState(() {}); // rebuild to show errors
      return;
    }
    final pickupsState = context.read<PickupsState>();
    final success = await pickupsState.createPickup(
      imageFile: _imageFile!,
      pickupAddress: _addressController.text.trim(),
      pickupLat: double.parse(_latitudeController.text.trim()),
      pickupLng: double.parse(_longitudeController.text.trim()),
      scheduledTimeIso: _scheduledTime?.toUtc().toIso8601String(),
      materialType: _selectedMaterialType?.apiValue,
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
      // Check field errors from createState
      setState(() {
        _fieldErrors = pickupsState.createState.fieldErrors;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
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
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_triedSubmit && _imageFile == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Please add a photo of the waste',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                // Form fields
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
                ),
                const SizedBox(height: 24),
                // Submit button
                _PrimaryButton(
                  text: 'Request Pickup',
                  isLoading:
                      pickupsState.createState.status == RequestStatus.loading,
                  onPressed:
                      pickupsState.createState.status == RequestStatus.loading
                      ? null
                      : _submit,
                ),
              ],
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
