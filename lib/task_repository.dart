class Task {
  final int id;
  final String title;
  final String deadline;
  bool done;
  final String priority;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "deadline": deadline,
      "priority": priority,
      "done": done,
    };
  }

  factory Task.fromMap(Map map) {
    return Task(
      id: map["id"],
      title: map["title"],
      deadline: map["deadline"],
      priority: map["priority"],
      done: map["done"],
    );
  }
}

class TaskRepository {
  static List<Task> tasks = [
    Task(id: 1, title: "Przygotować prezentację",      deadline: "jutro",     done: true,  priority: "wysoki"),
    Task(id: 2, title: "Oddać raport z laboratoriów",  deadline: "dzisiaj",   done: true,  priority: "wysoki"),
    Task(id: 3, title: "Powtórzyć widgety Flutter",    deadline: "w piątek",  done: false, priority: "średni"),
    Task(id: 4, title: "Napisać notatki do kolokwium", deadline: "w weekend", done: false, priority: "niski"),
  ];
}