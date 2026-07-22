import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dashboard_controller.dart';

class CreateEventModal extends ConsumerStatefulWidget {
  final CoachEvent? eventToEdit;

  const CreateEventModal({Key? key, this.eventToEdit}) : super(key: key);

  static Future<void> show(BuildContext context, {CoachEvent? eventToEdit}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CreateEventModal(eventToEdit: eventToEdit),
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
  String _selectedSquad = 'All Squads';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 30);
  String _selectedIntensity = 'High';
  String _selectedRecurrence = 'Does Not Repeat';
  Set<int> _selectedDays = {1, 3, 5}; // Default Monday, Wednesday, Friday
  bool _isImportant = false;
  bool _isSubmitting = false;

  final List<String> _eventTypes = [
    'Field Session',
    'Match Day',
    'Development',
    'Gym Session',
  ];

  final List<String> _squads = ['All Squads', 'U15', 'U16', 'U18'];

  final List<Map<String, dynamic>> _quickTemplates = [
    {
      'label': '⚽ Field Practice',
      'title': 'High-Intensity Tactical & Offload Drills',
      'eventType': 'Field Session',
      'time': const TimeOfDay(hour: 16, minute: 30),
      'duration': '90',
      'location': 'Primary Oval Field 1',
      'intensity': 'High',
      'isImportant': false,
    },
    {
      'label': '🏋️ Gym Strength',
      'title': 'Power Weight Training & Core Conditioning',
      'eventType': 'Gym Session',
      'time': const TimeOfDay(hour: 07, minute: 00),
      'duration': '60',
      'location': 'High Performance Center',
      'intensity': 'Medium',
      'isImportant': false,
    },
    {
      'label': '🤝 uGroup Mentor',
      'title': 'uGroup Character & Spirit Meeting',
      'eventType': 'Development',
      'time': const TimeOfDay(hour: 15, minute: 00),
      'duration': '45',
      'location': 'Seminar Room 1',
      'intensity': 'Low',
      'isImportant': false,
    },
    {
      'label': '🏟️ Match Day',
      'title': 'Premier Derby Match',
      'eventType': 'Match Day',
      'time': const TimeOfDay(hour: 14, minute: 00),
      'duration': '120',
      'location': 'Main Stadium Pitch',
      'intensity': 'High',
      'isImportant': true,
    },
  ];

  void _applyQuickTemplate(Map<String, dynamic> template) {
    HapticFeedback.lightImpact();
    setState(() {
      _titleController.text = template['title'];
      _selectedEventType = template['eventType'];
      _selectedTime = template['time'];
      _durationController.text = template['duration'];
      _locationController.text = template['location'];
      _selectedIntensity = template['intensity'];
      _isImportant = template['isImportant'];
    });
  }

  final List<String> _intensityLevels = ['Low', 'Medium', 'High'];

  final List<String> _recurrenceRules = [
    'Does Not Repeat',
    'Every Day',
    'Every Week',
    'Every 2 Weeks',
    'Every Month',
  ];

  final List<Map<String, dynamic>> _weekDays = [
    {'id': 1, 'label': 'Mon'},
    {'id': 2, 'label': 'Tue'},
    {'id': 3, 'label': 'Wed'},
    {'id': 4, 'label': 'Thu'},
    {'id': 5, 'label': 'Fri'},
    {'id': 6, 'label': 'Sat'},
    {'id': 7, 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _titleController.text = e.title;
      _locationController.text = e.location;
      _durationController.text = (e.durationMins ?? 90).toString();
      _selectedEventType = e.eventType;
      _selectedIntensity = e.intensity ?? 'High';
      _isImportant = e.isImportant;
      _selectedRecurrence = e.recurrenceRule;
      if (e.date.isNotEmpty) {
        _selectedDate = DateTime.tryParse(e.date) ?? DateTime.now();
      }
      if (e.startTime.isNotEmpty && e.startTime.contains(':')) {
        final parts = e.startTime.split(':');
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 16,
          minute: int.tryParse(parts[1]) ?? 30,
        );
      }
    }
  }

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
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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

    bool success = false;

    if (widget.eventToEdit != null) {
      final updated = widget.eventToEdit!.copyWith(
        title: title,
        eventType: _selectedEventType,
        startTime: timeStr,
        date: dateStr,
        location: location,
        durationMins: durationMins,
        intensity: _selectedIntensity,
        isImportant: _isImportant,
        recurrenceRule: _selectedRecurrence,
      );
      success = await ref.read(dashboardEventsProvider.notifier).updateEvent(updated);
    } else {
      success = await ref.read(dashboardEventsProvider.notifier).createEvent(
            title: title,
            eventType: _selectedEventType,
            startTime: timeStr,
            date: dateStr,
            location: location,
            durationMins: durationMins,
            intensity: _selectedIntensity,
            isImportant: _isImportant,
            recurrenceRule: _selectedRecurrence,
            repeatDaysOfWeek: _selectedRecurrence != 'Does Not Repeat' ? _selectedDays.toList() : null,
          );
    }

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
              // Quick Preset Templates Banner (uRun Style)
              _buildLabel('1-TAP QUICK TEMPLATES'),
              const SizedBox(height: 8.0),
              SizedBox(
                height: 38.0,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickTemplates.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 8.0),
                  itemBuilder: (context, index) {
                    final tmpl = _quickTemplates[index];
                    return ActionChip(
                      label: Text(tmpl['label']),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003EC7),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      onPressed: () => _applyQuickTemplate(tmpl),
                    );
                  },
                ),
              ),
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

              // Recurrence Rule Selector
              _buildLabel('RECURRENCE RULE'),
              const SizedBox(height: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRecurrence,
                    isExpanded: true,
                    icon: const Icon(Icons.repeat, color: Color(0xFF003EC7)),
                    style: const TextStyle(fontSize: 14.0, color: Color(0xFF131B2E), fontWeight: FontWeight.w600),
                    items: _recurrenceRules.map((rule) {
                      return DropdownMenuItem(value: rule, child: Text(rule));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRecurrence = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              if (_selectedRecurrence != 'Does Not Repeat') ...[
                const SizedBox(height: 12.0),
                _buildLabel('REPEAT ON DAYS'),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekDays.map((day) {
                    final int dayId = day['id'] as int;
                    final String label = day['label'] as String;
                    final bool isSelected = _selectedDays.contains(dayId);
                    return Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                if (_selectedDays.length > 1) {
                                  _selectedDays.remove(dayId);
                                }
                              } else {
                                _selectedDays.add(dayId);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF003EC7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF505F76),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
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
