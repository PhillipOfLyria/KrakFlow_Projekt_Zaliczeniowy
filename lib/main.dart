import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}
class MyApp extends StatelessWidget {
  MyApp({super.key});

  final List<Task> tasks = [
    Task(title: "Przygotować prezentację",      deadline: "jutro",      done: true,  priority: "wysoki"),
    Task(title: "Oddać raport z laboratoriów",  deadline: "dzisiaj",    done: true,  priority: "wysoki"),
    Task(title: "Powtórzyć widgety Flutter",    deadline: "w piątek",   done: false, priority: "średni"),
    Task(title: "Napisać notatki do kolokwium", deadline: "w weekend",  done: false, priority: "niski"),
  ];

  @override
  Widget build(BuildContext context) {
    final int doneCount = tasks.where((t) => t.done).length;
    return MaterialApp(
      title: "KrakFlow",
      home: Scaffold(
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
                    "Masz dziś ${tasks.length} zadania",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    "Wykonano: $doneCount / ${tasks.length}",
                    style: TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskCard(
                    title: task.title,
                    subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                    icon: task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  );
                },
              ),
            ),
          ],
        ),
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