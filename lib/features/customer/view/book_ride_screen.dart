import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/mock_map.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/dispatch.dart';
import '../../../data/models/vehicle.dart';
import '../viewmodel/book_ride_viewmodel.dart';
import 'widgets/dispatch_result_sheet.dart';

class BookRideScreen extends ConsumerStatefulWidget {
  const BookRideScreen({super.key});

  @override
  ConsumerState<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends ConsumerState<BookRideScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPlace(bool isPickup) async {
    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PlacePickerSheet(isPickup: isPickup),
    );
    if (place == null) return;
    final vm = ref.read(bookRideProvider.notifier);
    isPickup ? vm.setPickup(place) : vm.setDropoff(place);
  }

  Future<void> _pickSchedule() async {
    final state = ref.read(bookRideProvider);
    final date = await showDatePicker(
      context: context,
      initialDate: state.scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(state.scheduledAt),
    );
    if (time == null) return;
    ref.read(bookRideProvider.notifier).setScheduledAt(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
  }

  Future<void> _confirm() async {
    final result = await ref.read(bookRideProvider.notifier).submit();
    if (result == null || !mounted) return;
    final bookingId = result.bookingId;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => DispatchResultSheet(result: result),
    );
    if (!mounted) return;
    context.pushReplacement('/customer/trip/$bookingId');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookRideProvider);
    final preview = state.hasRoute ? ref.read(bookRideProvider.notifier).previewMatch() : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Reserve a ride')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          MockMap(
            height: 200,
            pickup: state.pickup?.position,
            dropoff: state.dropoff?.position,
            drivers: MockData.drivers
                .where((d) => d.status.name == 'available')
                .map((d) => MapDriver(
                      position: d.position,
                      highlighted: d.id == preview?.winner?.driver.id,
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          _LocationField(
            icon: Icons.my_location_rounded,
            color: AppColors.success,
            label: 'Pickup',
            value: state.pickup,
            onTap: () => _pickPlace(true),
          ),
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Divider(color: AppColors.line, height: 18),
              ),
              IconButton(
                onPressed: ref.read(bookRideProvider.notifier).swap,
                icon: const Icon(Icons.swap_vert_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceAlt,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          _LocationField(
            icon: Icons.place_rounded,
            color: AppColors.danger,
            label: 'Drop-off',
            value: state.dropoff,
            onTap: () => _pickPlace(false),
          ),
          const SizedBox(height: 22),
          Text('When', style: context.sectionTitle),
          const SizedBox(height: 10),
          _WhenToggle(
            scheduleLater: state.scheduleLater,
            scheduledAt: state.scheduledAt,
            onNow: () => ref.read(bookRideProvider.notifier).setScheduleLater(false),
            onSchedule: () {
              ref.read(bookRideProvider.notifier).setScheduleLater(true);
              _pickSchedule();
            },
            onEditSchedule: _pickSchedule,
          ),
          const SizedBox(height: 22),
          Text('Choose a vehicle', style: context.sectionTitle),
          const SizedBox(height: 10),
          for (final type in VehicleType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VehicleTile(
                type: type,
                selected: state.vehicleType == type,
                fare: state.hasRoute
                    ? Fmt.money(_fareFor(state, type))
                    : '--',
                onTap: () => ref.read(bookRideProvider.notifier).setVehicle(type),
              ),
            ),
          const SizedBox(height: 12),
          _PassengersRow(
            passengers: state.passengers,
            onChanged: ref.read(bookRideProvider.notifier).setPassengers,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            onChanged: ref.read(bookRideProvider.notifier).setNotes,
            decoration: const InputDecoration(
              hintText: 'Notes for the driver (optional)',
              prefixIcon: Icon(Icons.sticky_note_2_outlined),
            ),
          ),
          const SizedBox(height: 20),
          if (state.hasRoute) _FareSummary(state: state, preview: preview),
        ],
      ),
      bottomNavigationBar: _ConfirmBar(
        enabled: state.hasRoute && !state.submitting,
        submitting: state.submitting,
        fare: state.hasRoute ? Fmt.money(state.fare) : null,
        onConfirm: _confirm,
      ),
    );
  }

  double _fareFor(BookRideState s, VehicleType t) {
    // Reuse the same distance, vary the multiplier per row.
    final km = s.distanceKm;
    return _round(
        (2.5 + km * 1.15 + (km / 34 * 60) * 0.25) * t.fareMultiplier);
  }

  double _round(double v) => (v * 100).roundToDouble() / 100;
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final Place? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    value?.label ?? 'Select location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: value == null ? AppColors.inkSoft : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _WhenToggle extends StatelessWidget {
  const _WhenToggle({
    required this.scheduleLater,
    required this.scheduledAt,
    required this.onNow,
    required this.onSchedule,
    required this.onEditSchedule,
  });
  final bool scheduleLater;
  final DateTime scheduledAt;
  final VoidCallback onNow;
  final VoidCallback onSchedule;
  final VoidCallback onEditSchedule;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _toggle(
            label: 'Ride soon',
            sub: 'Next available',
            icon: Icons.bolt_rounded,
            selected: !scheduleLater,
            onTap: onNow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _toggle(
            label: 'Schedule',
            sub: scheduleLater ? Fmt.whenLabel(scheduledAt) : 'Pick a time',
            icon: Icons.calendar_month_rounded,
            selected: scheduleLater,
            onTap: scheduleLater ? onEditSchedule : onSchedule,
          ),
        ),
      ],
    );
  }

  Widget _toggle({
    required String label,
    required String sub,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.inkSoft),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.type,
    required this.selected,
    required this.fare,
    required this.onTap,
  });
  final VehicleType type;
  final bool selected;
  final String fare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(type.icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(type.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14.5)),
                      const SizedBox(width: 6),
                      Icon(Icons.person, size: 13, color: AppColors.inkSoft),
                      Text('${type.seats}',
                          style: const TextStyle(
                              color: AppColors.inkSoft, fontSize: 12)),
                    ],
                  ),
                  Text(type.description,
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 12)),
                ],
              ),
            ),
            Text(fare,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _PassengersRow extends StatelessWidget {
  const _PassengersRow({required this.passengers, required this.onChanged});
  final int passengers;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_rounded, color: AppColors.inkSoft, size: 20),
          const SizedBox(width: 12),
          const Text('Passengers',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          IconButton(
            onPressed: passengers > 1 ? () => onChanged(passengers - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text('$passengers',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          IconButton(
            onPressed: passengers < 6 ? () => onChanged(passengers + 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _FareSummary extends StatelessWidget {
  const _FareSummary({required this.state, required this.preview});
  final BookRideState state;
  final DispatchResult? preview;

  @override
  Widget build(BuildContext context) {
    final winner = preview?.winner;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _row('Distance', Fmt.km(state.distanceKm)),
          _row('Est. trip time', Fmt.minutes(state.etaMinutes)),
          _row('Vehicle', state.vehicleType.label),
          const Divider(height: 22),
          if (winner != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-dispatch ready: ${winner.driver.name.split(' ').first} '
                      '· ${winner.etaMinutes.round()} min away',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Total fare',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text(Fmt.money(state.fare),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.inkSoft)),
            const Spacer(),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.enabled,
    required this.submitting,
    required this.fare,
    required this.onConfirm,
  });
  final bool enabled;
  final bool submitting;
  final String? fare;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? onConfirm : null,
          child: submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded),
                    const SizedBox(width: 8),
                    Text(fare == null
                        ? 'Confirm reservation'
                        : 'Confirm • $fare'),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PlacePickerSheet extends StatelessWidget {
  const _PlacePickerSheet({required this.isPickup});
  final bool isPickup;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(isPickup ? 'Choose pickup' : 'Choose drop-off',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            ...MockData.savedPlaces.map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place_rounded,
                      color: AppColors.primary, size: 18),
                ),
                title: Text(p.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(p.address),
                onTap: () => Navigator.pop(context, p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
