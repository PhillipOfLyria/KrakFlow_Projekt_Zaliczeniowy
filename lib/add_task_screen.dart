import 'package:flutter/material.dart';
import 'task_repository.dart';

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController    = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowe zadanie"),
        // przycisk wstecz pojawia się automatycznie
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet (niski / średni / wysoki)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final newTask = Task(
                    title:    titleController.text,
                    deadline: deadlineController.text,
                    priority: priorityController.text,
                    done:     false,   // nowe zadanie zawsze nieukończone
                  );
                  // zwraca Task do poprzedniego ekranu (Zadanie 8)
                  Navigator.pop(context, newTask);
                },
                child: Text("Zapisz"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}