import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'add_task_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    final int doneCount = TaskRepository.tasks.where((t) => t.done).length;
    final int total     = TaskRepository.tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masz dziś $total zadania",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  "Wykonano: $doneCount / $total",
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: TaskRepository.tasks.length,
              itemBuilder: (context, index) {
                final task = TaskRepository.tasks[index];
                return TaskCard(
                  title: task.title,
                  subtitle:
                  "termin: ${task.deadline} | priorytet: ${task.priority}",
                  icon: task.done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
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
              pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(1.0, 0.0),
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
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(icon),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}