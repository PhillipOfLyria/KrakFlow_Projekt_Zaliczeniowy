import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'dart:math';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _deadlineController;
  late String _selectedPriority;
  late bool _done;

  final List<String> _priorities = ["niski", "średni", "wysoki"];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _deadlineController = TextEditingController(text: widget.task.deadline);
    _selectedPriority = widget.task.priority;
    _done = widget.task.done;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    final deadline = _deadlineController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tytuł zadania nie może być pusty")),
      );
      return;
    }

    final updatedTask = Task(
      id: widget.task.id,
      title: title,
      deadline: deadline,
      priority: _selectedPriority,
      done: _done,
    );

    Navigator.pop(context, updatedTask);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _deadlineController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edytuj zadanie"),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text(
              "Zapisz",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tytuł
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Termin
            TextField(
              controller: _deadlineController,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: "Termin",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Priorytet
            const Text(
              "Priorytet",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(priority),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text("Wykonane"),
              value: _done,
              onChanged: (value) {
                setState(() {
                  _done = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Zapisz zmiany",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}