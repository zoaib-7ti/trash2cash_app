import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/pickup_request_model.dart';

class PickupFormFields extends StatelessWidget {
  const PickupFormFields({
    super.key,
    required this.addressController,
    required this.latitudeController,
    required this.longitudeController,
    required this.scheduledTime,
    required this.onScheduledTimeChanged,
    required this.selectedMaterialType,
    required this.onMaterialTypeChanged,
    required this.estimatedWeightController,
    required this.errorTextFor,
    this.isEditMode = false,
    this.scheduledTimeHasServerValue = false,
    this.materialTypeHasServerValue = false,
    this.estimatedWeightHasServerValue = false,
  });

  final TextEditingController addressController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final DateTime? scheduledTime;
  final ValueChanged<DateTime?> onScheduledTimeChanged;
  final PickupMaterialType? selectedMaterialType;
  final ValueChanged<PickupMaterialType?> onMaterialTypeChanged;
  final TextEditingController estimatedWeightController;
  final String? Function(String field) errorTextFor;
  final bool isEditMode;
  final bool scheduledTimeHasServerValue;
  final bool materialTypeHasServerValue;
  final bool estimatedWeightHasServerValue;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.lightTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Address
        AppTextField(
          controller: addressController,
          label: 'ADDRESS',
          hintText: 'e.g. 123 Main Street, City',
          prefixIcon: Icons.location_on_outlined,
          errorText: errorTextFor('pickupAddress'),
        ),
        const SizedBox(height: 14),
        // 2. Latitude / Longitude
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: latitudeController,
                label: 'LATITUDE',
                hintText: 'e.g. 40.7128',
                prefixIcon: Icons.my_location_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: errorTextFor('pickupLat'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: longitudeController,
                label: 'LONGITUDE',
                hintText: 'e.g. -74.0060',
                prefixIcon: Icons.my_location_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: errorTextFor('pickupLng'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: null,
              icon: const Icon(Icons.my_location),
              tooltip: 'Use current location — coming soon',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Find this via Google Maps → long-press a point → copy coordinates.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: 14),
        // 3. Scheduled time
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: errorTextFor('scheduledTime') != null
                      ? tokens.errorBannerBackgroundColor
                      : const Color(0xFFD1D5DB),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: scheduledTime ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          scheduledTime ?? DateTime.now(),
                        ),
                      );
                      if (time != null) {
                        onScheduledTimeChanged(
                          DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SCHEDULED TIME (optional)',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scheduledTime != null
                                    ? DateFormat.yMMMd().add_jm().format(
                                        scheduledTime!,
                                      )
                                    : 'Tap to select date and time',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: scheduledTime != null
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF9CA3AF),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (scheduledTime != null)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF6B7280),
                            ),
                            onPressed: scheduledTimeHasServerValue
                                ? null
                                : () => onScheduledTimeChanged(null),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (errorTextFor('scheduledTime') != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  errorTextFor('scheduledTime')!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ),
            if (isEditMode && scheduledTimeHasServerValue)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Scheduled time can be changed but not removed here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // 4. Material type
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MATERIAL TYPE (optional)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PickupMaterialType.values.map((type) {
                final isSelected = selectedMaterialType == type;
                return FilterChip(
                  label: Text(type.label),
                  avatar: Icon(type.icon, size: 18),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onMaterialTypeChanged(type);
                    } else if (!materialTypeHasServerValue) {
                      onMaterialTypeChanged(null);
                    }
                  },
                  backgroundColor: tokens.filterChipTheme.backgroundColor,
                  selectedColor: tokens.filterChipTheme.selectedColor,
                  disabledColor: tokens.filterChipTheme.disabledColor,
                  padding: tokens.filterChipTheme.padding,
                  labelStyle: isSelected
                      ? tokens.filterChipTheme.secondaryLabelStyle
                      : tokens.filterChipTheme.labelStyle,
                  side: tokens.filterChipTheme.side,
                );
              }).toList(),
            ),
            if (errorTextFor('materialType') != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  errorTextFor('materialType')!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // 5. Estimated weight
        AppTextField(
          controller: estimatedWeightController,
          label: 'ESTIMATED WEIGHT (optional)',
          hintText: 'e.g. 5.5',
          prefixIcon: Icons.scale_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: 'kg',
          errorText: errorTextFor('estimatedWeight'),
        ),
      ],
    );
  }
}
