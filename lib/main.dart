import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'services/task_api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "KrakFlow",
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";
  bool isLoading = true;      // ← to musi być tutaj
  String? errorMessage;       // ← i to

  @override
  void initState() {
    super.initState();
    TaskApiService.fetchTasks().then((tasks) {
      setState(() {
        TaskRepository.tasks = tasks;
        isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    });
  }

  void _showDeleteAllDialog() {
    final bool isEmpty = TaskRepository.tasks.isEmpty;

    if (isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lista zadań jest już pusta")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Potwierdzenie"),
          content: const Text("Czy na pewno chcesz usunąć wszystkie zadania?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anuluj"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  TaskRepository.tasks.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Usunięto wszystkie zadania")),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Usuń"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = TaskRepository.tasks;
    if (selectedFilter == "wykonane") {
      filteredTasks =
          TaskRepository.tasks.where((t) => t.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks =
          TaskRepository.tasks.where((t) => !t.done).toList();
    }

    final int doneCount = TaskRepository.tasks.where((t) => t.done).length;
    final int total = TaskRepository.tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete,
              color: total == 0 ? Colors.grey[400] : null,
            ),
            tooltip: total == 0 ? "Brak zadań do usunięcia" : "Usuń wszystkie zadania",
            onPressed: _showDeleteAllDialog,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masz dziś $total zadania",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  "Wykonano: $doneCount / $total",
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
                const SizedBox(height: 8),
                FilterBar(
                  selectedFilter: selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text("Błąd: $errorMessage"))
                : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];

                return Dismissible(
                  key: ValueKey(task.title),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    final removedTitle = task.title;
                    setState(() {
                      TaskRepository.tasks.remove(task);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Usunięto: "$removedTitle"')),
                    );
                  },
                  child: TaskCard(
                    title: task.title,
                    subtitle:
                    "termin: ${task.deadline} | priorytet: ${task.priority}",
                    done: task.done,
                    onChanged: (value) {
                      setState(() {
                        task.done = value!;
                      });
                    },
                    onTap: () async {
                      final Task? updatedTask = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTaskScreen(task: task),
                        ),
                      );
                      if (updatedTask != null) {
                        setState(() {
                          final originalIndex =
                          TaskRepository.tasks.indexOf(task);
                          if (originalIndex != -1) {
                            TaskRepository.tasks[originalIndex] = updatedTask;
                          }
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AddTaskScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );

          if (newTask != null) {
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    const filters = ["wszystkie", "do zrobienia", "wykonane"];

    return Row(
      children: filters.map((filter) {
        final isActive = selectedFilter == filter;
        final label =
            filter[0].toUpperCase() + filter.substring(1);

        return TextButton(
          onPressed: () => onFilterChanged(filter),
          style: TextButton.styleFrom(
            foregroundColor: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            padding:
            const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight:
              isActive ? FontWeight.bold : FontWeight.normal,
              decoration: isActive
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        child: ListTile(
          onTap: onTap,
          leading: Checkbox(
            value: done,
            onChanged: onChanged,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration:
              done ? TextDecoration.lineThrough : TextDecoration.none,
              color: done ? Colors.grey : null,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: done ? Colors.grey[400] : null,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}