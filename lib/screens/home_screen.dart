import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/task_storage.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/filter_bar.dart';
import '../widgets/task_item.dart';
import '../widgets/task_search_bar.dart';
import '../widgets/task_stats.dart';
import 'settings_screen.dart';

enum TaskSort {
  created,
  dueDate,
}

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Task> _tasks = [];

  final TextEditingController _searchController =
      TextEditingController();

  TaskFilter _selectedFilter = TaskFilter.all;
  TaskSort _selectedSort = TaskSort.created;

  String _searchQuery = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD TASKS
  // ---------------------------------------------------------------------------

  Future<void> _loadTasks() async {
    try {
      final tasks =
          await TaskStorage.instance.getTasks();

      for (final task in tasks) {
        try {
          await NotificationService.instance
              .syncTaskReminder(task);
        } catch (_) {
          // Notification scheduling failure should
          // not prevent tasks from loading.
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks
          ..clear()
          ..addAll(tasks);

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load tasks: $error',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  void _changeSearchQuery(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  // ---------------------------------------------------------------------------
  // FILTER + SEARCH + SORT
  // ---------------------------------------------------------------------------

  List<Task> get _visibleTasks {
    List<Task> tasks;

    switch (_selectedFilter) {
      case TaskFilter.all:
        tasks = List<Task>.from(_tasks);

      case TaskFilter.active:
        tasks = _tasks
            .where(
              (task) => !task.isCompleted,
            )
            .toList();

      case TaskFilter.completed:
        tasks = _tasks
            .where(
              (task) => task.isCompleted,
            )
            .toList();
    }

    if (_searchQuery.isNotEmpty) {
      tasks = tasks
          .where(
            (task) => task.title
                .toLowerCase()
                .contains(_searchQuery),
          )
          .toList();
    }

    if (_selectedSort == TaskSort.dueDate) {
      tasks.sort((a, b) {
        if (a.dueDate == null &&
            b.dueDate == null) {
          return 0;
        }

        if (a.dueDate == null) {
          return 1;
        }

        if (b.dueDate == null) {
          return -1;
        }

        return DateUtils.dateOnly(a.dueDate!)
            .compareTo(
          DateUtils.dateOnly(b.dueDate!),
        );
      });
    }

    return tasks;
  }

  // ---------------------------------------------------------------------------
  // FILTER / SORT
  // ---------------------------------------------------------------------------

  void _changeFilter(TaskFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _changeSort(TaskSort sort) {
    setState(() {
      _selectedSort = sort;
    });
  }

  // ---------------------------------------------------------------------------
  // SETTINGS
  // ---------------------------------------------------------------------------

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return SettingsScreen(
            themeMode: widget.themeMode,
            onThemeModeChanged:
                widget.onThemeModeChanged,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOGGLE TASK
  // ---------------------------------------------------------------------------

  Future<void> _toggleTask(
    String taskId,
  ) async {
    final task = _tasks.firstWhere(
      (task) => task.id == taskId,
    );

    final previousValue = task.isCompleted;

    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    try {
      await TaskStorage.instance.updateTask(task);

      if (task.isCompleted) {
        await NotificationService.instance
            .cancelTaskReminder(task.id);
      } else {
        await NotificationService.instance
            .syncTaskReminder(task);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        task.isCompleted = previousValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update task: $error',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ADD TASK
  // ---------------------------------------------------------------------------

  Future<void> _showAddTaskSheet() async {
    final result =
        await showModalBottomSheet<TaskFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const AddTaskSheet();
      },
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    final task = Task(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      title: result.title,
      priority: result.priority,
      dueDate: result.dueDate,
      reminderAt: result.reminderAt,
    );

    try {
      await TaskStorage.instance.insertTask(task);

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks.add(task);
      });

      if (task.reminderAt != null) {
        try {
          await NotificationService.instance
              .scheduleTaskReminder(task);
        } catch (_) {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Task saved, but the reminder could not be scheduled.',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add task: $error',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // EDIT TASK
  // ---------------------------------------------------------------------------

  Future<void> _editTask(Task task) async {
    final result =
        await showModalBottomSheet<TaskFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return AddTaskSheet(
          initialTitle: task.title,
          initialPriority: task.priority,
          initialDueDate: task.dueDate,
          initialReminderAt: task.reminderAt,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    final previousTitle = task.title;
    final previousPriority = task.priority;
    final previousDueDate = task.dueDate;
    final previousReminder = task.reminderAt;

    setState(() {
      task.title = result.title;
      task.priority = result.priority;
      task.dueDate = result.dueDate;
      task.reminderAt = result.reminderAt;
    });

    try {
      await TaskStorage.instance
          .updateTask(task);

      if (!mounted) {
        return;
      }

      await NotificationService.instance
          .syncTaskReminder(task);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        task.title = previousTitle;
        task.priority = previousPriority;
        task.dueDate = previousDueDate;
        task.reminderAt = previousReminder;
      });

      try {
        await NotificationService.instance
            .syncTaskReminder(task);
      } catch (_) {}

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update task: $error',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE TASK
  // ---------------------------------------------------------------------------

  Future<void> _confirmDeleteTask(
    Task task,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Task?'),
          content: Text(
            'Are you sure you want to delete "${task.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (shouldDelete != true) {
      return;
    }

    try {
      await TaskStorage.instance
          .deleteTask(task.id);

      if (!mounted) {
        return;
      }

      await NotificationService.instance
          .cancelTaskReminder(task.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks.removeWhere(
          (item) => item.id == task.id,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete task: $error',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      message = 'No tasks found';
      subtitle = 'Try a different search term.';
      icon = Icons.search_off_rounded;
    } else {
      switch (_selectedFilter) {
        case TaskFilter.all:
          message = 'No tasks yet';
          subtitle =
              'Tap + to create your first task.';
          icon = Icons.task_alt_rounded;

        case TaskFilter.active:
          message = 'Nothing pending';
          subtitle =
              'You are all caught up!';
          icon = Icons.check_circle_rounded;

        case TaskFilter.completed:
          message = 'Nothing completed';
          subtitle =
              'Completed tasks will appear here.';
          icon = Icons.done_all_rounded;
      }
    }

    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color:
                    colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 42,
                color:
                    colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER CARD
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard() {
    final colorScheme =
        Theme.of(context).colorScheme;

    final activeCount = _tasks
        .where(
          (task) => !task.isCompleted,
        )
        .length;

    final completedCount = _tasks
        .where(
          (task) => task.isCompleted,
        )
        .length;

    final progress = _tasks.isEmpty
        ? 0.0
        : completedCount / _tasks.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface
                      .withValues(alpha: 0.65),
                  borderRadius:
                      BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.today_rounded,
                      size: 16,
                      color:
                          colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(
                        DateTime.now(),
                      ),
                      style: TextStyle(
                        color:
                            colorScheme.onSurface,
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'Stay focused.',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.w900,
                  color: colorScheme
                      .onPrimaryContainer,
                  letterSpacing: -0.5,
                ),
          ),

          const SizedBox(height: 4),

          Text(
            activeCount == 0
                ? 'Everything is under control.'
                : '$activeCount ${activeCount == 1 ? 'task' : 'tasks'} left to finish.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: colorScheme
                      .onPrimaryContainer
                      .withValues(
                        alpha: 0.75,
                      ),
                ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  child:
                      LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        colorScheme
                            .onPrimaryContainer
                            .withValues(
                              alpha: 0.14,
                            ),
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  color: colorScheme
                      .onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'My To-Do',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
            ),
            Text(
              'Plan • Focus • Finish',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<TaskSort>(
            tooltip: 'Sort tasks',
            icon: const Icon(
              Icons.sort_rounded,
            ),
            onSelected: _changeSort,
            itemBuilder: (context) {
              return [
                CheckedPopupMenuItem<TaskSort>(
                  value: TaskSort.created,
                  checked:
                      _selectedSort ==
                          TaskSort.created,
                  child: const Text(
                    'Created order',
                  ),
                ),
                CheckedPopupMenuItem<TaskSort>(
                  value: TaskSort.dueDate,
                  checked:
                      _selectedSort ==
                          TaskSort.dueDate,
                  child: const Text(
                    'Due date',
                  ),
                ),
              ];
            },
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      0,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child:
                          _buildHeaderCard(),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child:
                        SizedBox(height: 14),
                  ),

                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child: TaskSearchBar(
                        query: _searchQuery,
                        onChanged:
                            _changeSearchQuery,
                        onClear:
                            _clearSearch,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child:
                        SizedBox(height: 14),
                  ),

                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child: TaskStats(
                        tasks: _tasks,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child:
                        SizedBox(height: 14),
                  ),

                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child: FilterBar(
                        selectedFilter:
                            _selectedFilter,
                        onFilterChanged:
                            _changeFilter,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child:
                        SizedBox(height: 8),
                  ),

                  if (_visibleTasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child:
                          _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        100,
                      ),
                      sliver: SliverList(
                        delegate:
                            SliverChildBuilderDelegate(
                          (context, index) {
                            final task =
                                _visibleTasks[index];

                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                bottom: 10,
                              ),
                              child: TaskItem(
                                task: task,
                                onToggle: () {
                                  _toggleTask(
                                    task.id,
                                  );
                                },
                                onEdit: () {
                                  _editTask(task);
                                },
                                onDelete: () {
                                  _confirmDeleteTask(
                                    task,
                                  );
                                },
                              ),
                            );
                          },
                          childCount:
                              _visibleTasks.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _isLoading
                ? null
                : _showAddTaskSheet,
        tooltip: 'Add task',
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Task',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}