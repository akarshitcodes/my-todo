import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskStats extends StatelessWidget {
  final List<Task> tasks;

  const TaskStats({
    super.key,
    required this.tasks,
  });

  int get _completedCount {
    return tasks.where((task) => task.isCompleted).length;
  }

  int get _activeCount {
    return tasks.where((task) => !task.isCompleted).length;
  }

  int get _overdueCount {
    final today = DateUtils.dateOnly(DateTime.now());

    return tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) {
        return false;
      }

      return DateUtils.dateOnly(task.dueDate!).isBefore(today);
    }).length;
  }

  double get _completionProgress {
    if (tasks.isEmpty) {
      return 0;
    }

    return _completedCount / tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 700
                ? (constraints.maxWidth - 24) / 4
                : (constraints.maxWidth - 8) / 2;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatCard(
                  width: cardWidth,
                  label: 'Total',
                  value: tasks.length.toString(),
                  icon: Icons.list_alt_rounded,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Active',
                  value: _activeCount.toString(),
                  icon: Icons.pending_actions_rounded,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Completed',
                  value: _completedCount.toString(),
                  icon: Icons.check_circle_outline,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Overdue',
                  value: _overdueCount.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Completion',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(_completionProgress * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _completionProgress,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}