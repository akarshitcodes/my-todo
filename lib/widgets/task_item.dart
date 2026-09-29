import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  // ---------------------------------------------------------------------------
  // PRIORITY
  // ---------------------------------------------------------------------------

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.low:
        return Colors.green;

      case TaskPriority.medium:
        return Colors.orange;

      case TaskPriority.high:
        return Colors.red;
    }
  }

  String _priorityLabel() {
    switch (task.priority) {
      case TaskPriority.low:
        return 'LOW';

      case TaskPriority.medium:
        return 'MEDIUM';

      case TaskPriority.high:
        return 'HIGH';
    }
  }

  // ---------------------------------------------------------------------------
  // DUE DATE
  // ---------------------------------------------------------------------------

  bool get _isOverdue {
    if (task.dueDate == null ||
        task.isCompleted) {
      return false;
    }

    final today = DateUtils.dateOnly(
      DateTime.now(),
    );

    final dueDate = DateUtils.dateOnly(
      task.dueDate!,
    );

    return dueDate.isBefore(today);
  }

  String _formatDueDate(
    BuildContext context,
  ) {
    return MaterialLocalizations.of(context)
        .formatMediumDate(
      task.dueDate!,
    );
  }

  // ---------------------------------------------------------------------------
  // REMINDER
  // ---------------------------------------------------------------------------

  String _formatReminderDate(
    BuildContext context,
  ) {
    if (task.reminderAt == null) {
      return '';
    }

    final date =
        MaterialLocalizations.of(context)
            .formatMediumDate(
      task.reminderAt!,
    );

    final time =
        MaterialLocalizations.of(context)
            .formatTimeOfDay(
      TimeOfDay.fromDateTime(
        task.reminderAt!,
      ),
    );

    return '$date • $time';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final priorityColor =
        _priorityColor();

    final dueDateColor = _isOverdue
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding:
            const EdgeInsets.fromLTRB(
          10,
          10,
          8,
          10,
        ),

        // ---------------------------------------------------------------------
        // CHECKBOX
        // ---------------------------------------------------------------------

        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) {
            onToggle();
          },
        ),

        // ---------------------------------------------------------------------
        // CONTENT
        // ---------------------------------------------------------------------

        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: task.isCompleted
                ? colorScheme
                    .onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 8,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 7,
            children: [
              // ---------------------------------------------------------------
              // PRIORITY
              // ---------------------------------------------------------------

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(6),
                ),
                child: Text(
                  _priorityLabel(),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // DUE DATE
              // ---------------------------------------------------------------

              if (task.dueDate != null)
                Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      _isOverdue
                          ? Icons
                              .warning_amber_rounded
                          : Icons
                              .calendar_today_outlined,
                      size: 13,
                      color: dueDateColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOverdue
                          ? 'Overdue • ${_formatDueDate(context)}'
                          : _formatDueDate(
                              context,
                            ),
                      style: TextStyle(
                        color: dueDateColor,
                        fontSize: 11,
                        fontWeight: _isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

              // ---------------------------------------------------------------
              // REMINDER
              // ---------------------------------------------------------------

              if (task.reminderAt != null)
                Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .notifications_none_rounded,
                      size: 13,
                      color: colorScheme
                          .onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatReminderDate(
                        context,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // ---------------------------------------------------------------------
        // ACTIONS
        // ---------------------------------------------------------------------

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit task',
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete task',
              icon: const Icon(
                Icons.delete_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}