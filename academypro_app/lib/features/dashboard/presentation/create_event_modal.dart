import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dashboard_controller.dart';

class CreateEventModal extends ConsumerStatefulWidget {
  const CreateEventModal({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const CreateEventModal(),
    );
  }

  @override
  ConsumerState<CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends ConsumerState<CreateEventModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController(text: '90');

  String _selectedEventType = 'Field Session';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 30);
  String _selectedIntensity = 'High';
  bool _isImportant = false;
  bool _isSubmitting = false;

  final List<String> _eventTypes = [
    'Field Session',
    'Match Day',
    'Development',
    'Gym Session',
  ];

  final List<String> _intensityLevels = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003EC7),
              onPrimary: Colors.white,
              onSurface: Color(0xFF131B2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003EC7),
              onPrimary: Colors.white,
              onSurface: Color(0xFF131B2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDateStr(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTimeStr(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final min = tod.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final durationMins = int.tryParse(_durationController.text.trim()) ?? 90;
    final dateStr = _formatDateStr(_selectedDate);
    final timeStr = _formatTimeStr(_selectedTime);

    final success = await ref.read(dashboardEventsProvider.notifier).createEvent(
          title: title,
          eventType: _selectedEventType,
          startTime: timeStr,
          date: dateStr,
          location: location,
          durationMins: durationMins,
          intensity: _selectedIntensity,
          isImportant: _isImportant,
        );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Event successfully created & added to calendar'),
              ],
            ),
            backgroundColor: const Color(0xFF166534),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create event. Please try again.'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 16.0,
        bottom: 24.0 + bottomPadding + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3C5D9).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Event Session',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF505F76)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              const Text(
                'Schedule a new training session or match for the team calendar.',
                style: TextStyle(fontSize: 13.0, color: Color(0xFF737688)),
              ),
              const SizedBox(height: 20.0),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16.0),

              // Event Title
              _buildLabel('EVENT TITLE'),
              const SizedBox(height: 6.0),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                decoration: _inputDecoration('e.g. Field Session A (Tactical & Set Pieces)', Icons.event_note),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Event Type Selector
              _buildLabel('EVENT CATEGORY'),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _eventTypes.map((type) {
                  final isSelected = _selectedEventType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: const Color(0xFFDDE1FF),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF0038B6) : const Color(0xFF505F76),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0038B6) : Colors.transparent,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedEventType = type;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),

              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('DATE'),
                        const SizedBox(height: 6.0),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: Color(0xFF003EC7), size: 18.0),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    _formatDateStr(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF131B2E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('START TIME'),
                        const SizedBox(height: 6.0),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFF003EC7), size: 18.0),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    _formatTimeStr(_selectedTime),
                                    style: const TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF131B2E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Location & Duration Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('LOCATION'),
                        const SizedBox(height: 6.0),
                        TextFormField(
                          controller: _locationController,
                          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                          decoration: _inputDecoration('e.g. Overkruin Field A', Icons.location_on_outlined),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Location required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('DURATION (MIN)'),
                        const SizedBox(height: 6.0),
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                          decoration: _inputDecoration('90', Icons.timer_outlined),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Intensity Level
              _buildLabel('INTENSITY LEVEL'),
              const SizedBox(height: 8.0),
              Row(
                children: _intensityLevels.map((lvl) {
                  final isSelected = _selectedIntensity == lvl;
                  Color activeColor;
                  switch (lvl) {
                    case 'Low':
                      activeColor = const Color(0xFF22C55E);
                      break;
                    case 'Medium':
                      activeColor = const Color(0xFFF59E0B);
                      break;
                    case 'High':
                    default:
                      activeColor = const Color(0xFFEF4444);
                      break;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIntensity = lvl;
                          });
                        },
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor.withOpacity(0.15) : const Color(0xFFF1F5F9),
                            border: Border.all(
                              color: isSelected ? activeColor : Colors.transparent,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt, color: isSelected ? activeColor : const Color(0xFF64748B), size: 16.0),
                              const SizedBox(width: 4.0),
                              Text(
                                lvl,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? activeColor : const Color(0xFF505F76),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),

              // Important Flag Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFD97706), size: 20.0),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Mark as High Priority / Important',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            'Highlights session in golden star badge',
                            style: TextStyle(fontSize: 11.0, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isImportant,
                      activeColor: const Color(0xFFD97706),
                      onChanged: (val) {
                        setState(() {
                          _isImportant = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003EC7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Publish & Create Event',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        color: Color(0xFF737688),
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.0, fontWeight: FontWeight.normal),
      prefixIcon: Icon(icon, color: const Color(0xFF505F76), size: 18.0),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFF003EC7), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.8),
      ),
    );
  }
}
