import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'task_repository.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'services/task_api_service.dart';
import 'services/task_local_database.dart';
import 'services/task_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("tasks");
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
  bool isLoading = true;
  String? errorMessage;
  late Future<List<Task>> tasksFuture;

  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  Future<List<Task>> loadLocalTasks() async {
    return TaskLocalDatabase.getTasks();
  }

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  void updateCounters(List<Task> tasks) {
    setState(() {
      allTasksCount = tasks.length;
      doneTasksCount = tasks.where((t) => t.done).length;
      todoTasksCount = tasks.where((t) => !t.done).length;
    });
  }

  void _showDeleteAllDialog() {
    final bool isEmpty = TaskLocalDatabase.isEmpty();

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
              onPressed: () async {
                await TaskLocalDatabase.deleteAllTasks();
                setState(() {
                  tasksFuture = loadLocalTasks();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete,
              color: allTasksCount == 0 ? Colors.grey[400] : null,
            ),
            tooltip: allTasksCount == 0 ? "Brak zadań do usunięcia" : "Usuń wszystkie zadania",
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
                  "Masz dziś $allTasksCount zadania",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  "Wykonano: $doneTasksCount / $allTasksCount",
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
            child: FutureBuilder<List<Task>>(
              future: tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Błąd: ${snapshot.error}"));
                }
                final allTasks = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  updateCounters(allTasks);
                });
                List<Task> filteredTasks = allTasks;
                if (selectedFilter == "wykonane") {
                  filteredTasks = allTasks.where((t) => t.done).toList();
                } else if (selectedFilter == "do zrobienia") {
                  filteredTasks = allTasks.where((t) => !t.done).toList();
                }
                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return Dismissible(
                      key: ValueKey(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await TaskLocalDatabase.deleteTask(task.id);
                        setState(() {
                          tasksFuture = loadLocalTasks();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Usunięto: "${task.title}"')),
                        );
                      },
                      child: TaskCard(
                        title: task.title,
                        subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                        done: task.done,
                        onChanged: (value) async {
                          final updatedTask = Task(
                            id: task.id,
                            title: task.title,
                            deadline: task.deadline,
                            priority: task.priority,
                            done: value ?? false,
                          );
                          await TaskLocalDatabase.updateTask(updatedTask);
                          setState(() {
                            tasksFuture = loadLocalTasks();
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
                            await TaskLocalDatabase.updateTask(updatedTask);
                            setState(() {
                              tasksFuture = loadLocalTasks();
                            });
                          }
                        },
                      ),
                    );
                  },
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
            await TaskLocalDatabase.addTask(newTask);
            setState(() {
              tasksFuture = loadLocalTasks();
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
        final label = filter[0].toUpperCase() + filter.substring(1);

        return TextButton(
          onPressed: () => onFilterChanged(filter),
          style: TextButton.styleFrom(
            foregroundColor: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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