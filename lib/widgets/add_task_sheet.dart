import 'package:flutter/material.dart';

import '../models/task.dart';

class AddTaskSheet extends StatefulWidget {
  final String? initialTitle;
  final TaskPriority initialPriority;
  final DateTime? initialDueDate;
  final DateTime? initialReminderAt;

  const AddTaskSheet({
    super.key,
    this.initialTitle,
    this.initialPriority = TaskPriority.medium,
    this.initialDueDate,
    this.initialReminderAt,
  });

  bool get isEditing => initialTitle != null;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _titleController;

  late TaskPriority _selectedPriority;

  DateTime? _selectedDueDate;
  DateTime? _selectedReminderAt;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.initialTitle ?? '',
    );

    _selectedPriority = widget.initialPriority;
    _selectedDueDate = widget.initialDueDate;
    _selectedReminderAt = widget.initialReminderAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DUE DATE
  // ---------------------------------------------------------------------------

  Future<void> _pickDueDate() async {
    final today = DateUtils.dateOnly(
      DateTime.now(),
    );

    DateTime initialDate =
        _selectedDueDate ?? today;

    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select due date',
    );

    if (pickedDate == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedDueDate = pickedDate;
    });
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
    });
  }

  // ---------------------------------------------------------------------------
  // REMINDER
  // ---------------------------------------------------------------------------

  Future<void> _pickReminder() async {
    final now = DateTime.now();

    final today = DateUtils.dateOnly(now);

    DateTime initialDate =
        _selectedReminderAt ?? today;

    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(2100),
      helpText: 'Reminder date',
    );

    if (pickedDate == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final initialTime =
        _selectedReminderAt != null &&
                DateUtils.isSameDay(
                  _selectedReminderAt!,
                  pickedDate,
                )
            ? TimeOfDay.fromDateTime(
                _selectedReminderAt!,
              )
            : TimeOfDay.fromDateTime(
                now.add(
                  const Duration(minutes: 5),
                ),
              );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Reminder time',
    );

    if (pickedTime == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final reminderDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!reminderDateTime.isAfter(
      DateTime.now(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reminder must be in the future.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _selectedReminderAt = reminderDateTime;
    });
  }

  void _clearReminder() {
    setState(() {
      _selectedReminderAt = null;
    });
  }

  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();

    Navigator.pop(
      context,
      TaskFormResult(
        title: title,
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        reminderAt: _selectedReminderAt,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';

      case TaskPriority.medium:
        return 'Medium';

      case TaskPriority.high:
        return 'High';
    }
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context)
        .formatMediumDate(date);
  }

  String _formatDateTime(DateTime dateTime) {
    final date =
        MaterialLocalizations.of(context)
            .formatMediumDate(dateTime);

    final time =
        MaterialLocalizations.of(context)
            .formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );

    return '$date • $time';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
                20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? 'Edit Task'
                    : 'Add Task',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                autofocus: true,
                textInputAction:
                    TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Task title',
                  hintText: 'Enter your task',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter a task';
                  }

                  if (value.trim().length < 3) {
                    return 'Task must contain at least 3 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              SegmentedButton<TaskPriority>(
                segments: TaskPriority.values
                    .map(
                      (priority) =>
                          ButtonSegment<TaskPriority>(
                        value: priority,
                        label: Text(
                          _priorityLabel(priority),
                        ),
                      ),
                    )
                    .toList(),
                selected: {_selectedPriority},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedPriority =
                        selection.first;
                  });
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Due Date',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      label: Text(
                        _selectedDueDate == null
                            ? 'Select Date'
                            : _formatDate(
                                _selectedDueDate!,
                              ),
                      ),
                    ),
                  ),
                  if (_selectedDueDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearDueDate,
                      tooltip:
                          'Remove due date',
                      icon: const Icon(
                        Icons.clear,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Reminder',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Optional notification',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickReminder,
                      icon: const Icon(
                        Icons
                            .notifications_none_rounded,
                      ),
                      label: Text(
                        _selectedReminderAt == null
                            ? 'Set Reminder'
                            : _formatDateTime(
                                _selectedReminderAt!,
                              ),
                      ),
                    ),
                  ),
                  if (_selectedReminderAt != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearReminder,
                      tooltip:
                          'Remove reminder',
                      icon: const Icon(
                        Icons.clear,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    isEditing
                        ? 'Save Changes'
                        : 'Add Task',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskFormResult {
  final String title;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? reminderAt;

  const TaskFormResult({
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.reminderAt,
  });
}