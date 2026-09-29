import 'package:flutter/material.dart';

enum TaskFilter {
  all,
  active,
  completed,
}

class FilterBar extends StatelessWidget {
  final TaskFilter selectedFilter;
  final ValueChanged<TaskFilter> onFilterChanged;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilter(
            context,
            label: 'All',
            filter: TaskFilter.all,
          ),
          const SizedBox(width: 8),
          _buildFilter(
            context,
            label: 'Active',
            filter: TaskFilter.active,
          ),
          const SizedBox(width: 8),
          _buildFilter(
            context,
            label: 'Completed',
            filter: TaskFilter.completed,
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(
    BuildContext context, {
    required String label,
    required TaskFilter filter,
  }) {
    final isSelected = selectedFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        onFilterChanged(filter);
      },
    );
  }
}