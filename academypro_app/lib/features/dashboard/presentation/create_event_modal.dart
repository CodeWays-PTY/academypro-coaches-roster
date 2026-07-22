import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String _selectedEventType = 'Field';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 30);
  String _selectedRecurrence = 'Does Not Repeat';
  bool _isImportant = false;
  bool _isSubmitting = false;
  String? _attachedWorkoutName;

  Map<String, List<String>> _userLocationHistory = {};

  final List<String> _eventTypes = [
    'Field',
    'Test Day',
    'Gym',
    'Match',
  ];

  final List<int> _durationOptions = [30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _loadLocationHistory();

    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _titleController.text = e.title;
      _locationController.text = e.location;
      _durationController.text = (e.durationMins ?? 90).toString();
      _selectedEventType = e.eventType;
      _isImportant = e.isImportant;
      _selectedRecurrence = e.recurrenceRule;
      _attachedWorkoutName = e.workoutAttachmentName;
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

  Future<void> _loadLocationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyMap = <String, List<String>>{};
    for (final type in _eventTypes) {
      final saved = prefs.getStringList('user_locations_$type') ?? [];
      historyMap[type] = saved;
    }
    if (mounted) {
      setState(() {
        _userLocationHistory = historyMap;
      });
    }
  }

  Future<void> _saveLocationToHistory(String type, String loc) async {
    final cleanLoc = loc.trim();
    if (cleanLoc.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('user_locations_$type') ?? [];
    if (!current.contains(cleanLoc)) {
      final updated = [cleanLoc, ...current].take(8).toList();
      await prefs.setStringList('user_locations_$type', updated);
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

  Future<void> _pickWorkoutFile() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _attachedWorkoutName = file.name;
      });
    } else {
      setState(() {
        _attachedWorkoutName = 'Workout_Program_${_selectedEventType}_Session.pdf';
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

    // Save location to user history for this training type
    await _saveLocationToHistory(_selectedEventType, location);

    bool success = false;

    if (widget.eventToEdit != null) {
      final updated = widget.eventToEdit!.copyWith(
        title: title,
        eventType: _selectedEventType,
        startTime: timeStr,
        date: dateStr,
        location: location,
        durationMins: durationMins,
        isImportant: _isImportant,
        recurrenceRule: _selectedRecurrence,
        workoutAttachmentName: _attachedWorkoutName,
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
            isImportant: _isImportant,
            recurrenceRule: _selectedRecurrence,
            workoutAttachmentName: _attachedWorkoutName,
          );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20.0),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    widget.eventToEdit != null ? 'Event updated successfully' : 'Event created successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final userLocations = _userLocationHistory[_selectedEventType] ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Drag Handle & Title Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 12.0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                  ),
                ),
                const SizedBox(height: 14.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Icon(Icons.event_note, color: Color(0xFF003EC7), size: 20.0),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          widget.eventToEdit != null ? 'Edit Event' : 'Create Event',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, bottomInset + 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TRAINING TYPE SELECTOR
                    const Text(
                      'TYPE OF TRAINING',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: _eventTypes.map((type) {
                        final isSel = _selectedEventType == type;
                        IconData typeIcon = Icons.sports_soccer;
                        if (type == 'Gym') typeIcon = Icons.fitness_center;
                        if (type == 'Test Day') typeIcon = Icons.timer_outlined;
                        if (type == 'Match') typeIcon = Icons.emoji_events_outlined;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedEventType = type;
                                  if (type == 'Match' || type == 'Test Day') {
                                    _isImportant = true;
                                  } else {
                                    _isImportant = false;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF003EC7) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF003EC7) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(typeIcon, color: isSel ? Colors.white : const Color(0xFF64748B), size: 18.0),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        color: isSel ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 11.5,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
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

                    const SizedBox(height: 20.0),

                    // 2. EVENT TITLE (BLANK BY DEFAULT - CUSTOM USER INPUT)
                    const Text(
                      'EVENT TITLE',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter event title...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.0),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: Color(0xFF003EC7), width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter an event title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20.0),

                    // 3. LOCATION INPUT WITH USER-ENTERED HISTORY MEMORY
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'LOCATION',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter location...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.0),
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 20.0),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: Color(0xFF003EC7), width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please specify the event location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8.0),

                    // Displays ONLY user's previously entered locations for this training type
                    if (userLocations.isNotEmpty) ...[
                      const Text(
                        'Recent Locations:',
                        style: TextStyle(fontSize: 11.0, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4.0),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 6.0,
                        children: userLocations.map((loc) {
                          return ActionChip(
                            avatar: const Icon(Icons.history, size: 13.0, color: Color(0xFF003EC7)),
                            label: Text(loc),
                            backgroundColor: const Color(0xFFEFF6FF),
                            labelStyle: const TextStyle(color: Color(0xFF003EC7), fontSize: 11.5, fontWeight: FontWeight.w600),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _locationController.text = loc;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20.0),

                    // 4. DATE, TIME & DURATION (CRITICAL FIELDS)
                    Row(
                      children: [
                        // DATE PICKER
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATE',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16.0, color: Color(0xFF003EC7)),
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Text(
                                          _formatDateStr(_selectedDate),
                                          style: const TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10.0),

                        // TIME PICKER
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'START TIME',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(12.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16.0, color: Color(0xFF003EC7)),
                                      const SizedBox(width: 6.0),
                                      Text(
                                        _formatTimeStr(_selectedTime),
                                        style: const TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
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

                    // DURATION SELECTOR CHIPS
                    const Text(
                      'DURATION (MINS)',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: _durationOptions.map((dur) {
                        final isSel = _durationController.text == dur.toString();
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: ChoiceChip(
                              label: Text('${dur}m'),
                              selected: isSel,
                              selectedColor: const Color(0xFFDBEAFE),
                              backgroundColor: const Color(0xFFF8FAFC),
                              labelStyle: TextStyle(
                                color: isSel ? const Color(0xFF003EC7) : const Color(0xFF64748B),
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12.0,
                              ),
                              side: BorderSide(
                                color: isSel ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _durationController.text = dur.toString();
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20.0),

                    // 5. OPTIONAL WORKOUT ATTACHMENT
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.attachment, color: Color(0xFF003EC7), size: 18.0),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'WORKOUT PROGRAM (OPTIONAL)',
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: _pickWorkoutFile,
                                icon: const Icon(Icons.upload_file, size: 14.0),
                                label: Text(_attachedWorkoutName != null ? 'Change' : 'Upload'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF003EC7),
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                ),
                              ),
                            ],
                          ),
                          if (_attachedWorkoutName != null) ...[
                            const SizedBox(height: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description, color: Color(0xFF166534), size: 14.0),
                                  const SizedBox(width: 6.0),
                                  Expanded(
                                    child: Text(
                                      _attachedWorkoutName!,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF166534),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _attachedWorkoutName = null;
                                      });
                                    },
                                    child: const Icon(Icons.close, color: Color(0xFF166534), size: 14.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // IMPORTANT / HIGH PRIORITY SWITCH TILE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: _isImportant ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: _isImportant ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
                      ),
                      child: SwitchListTile(
                        value: _isImportant,
                        onChanged: (val) {
                          setState(() {
                            _isImportant = val;
                          });
                        },
                        activeColor: const Color(0xFFD97706),
                        title: const Text(
                          'Mark as High Priority / Important',
                          style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        subtitle: const Text(
                          'Flags this session with a star badge on player dashboards',
                          style: TextStyle(fontSize: 11.0, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    // SUBMIT EVENT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003EC7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                              )
                            : Text(
                                widget.eventToEdit != null ? 'Update Event Details' : 'Create Event',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
