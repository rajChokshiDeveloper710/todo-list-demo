import 'dart:async';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePageBloc {
  final _tasksSubject = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  final _searchSubject = BehaviorSubject<String>.seeded("");
  final _loadingSubject = BehaviorSubject<bool>.seeded(false);
  final _dueDateSubject = BehaviorSubject<DateTime?>.seeded(null);

  // Stream for the selected due date
  Stream<DateTime?> get dueDateStream => _dueDateSubject.stream;

  // Get the current value of due date
  DateTime? get currentDueDate => _dueDateSubject.valueOrNull;

  // Update due date
  void updateDueDate(DateTime? date) {
    _dueDateSubject.add(date);
  }
  Stream<List<Map<String, dynamic>>> get tasksStream => Rx.combineLatest2(
    _tasksSubject.stream,
    _searchSubject.stream,
        (List<Map<String, dynamic>> tasks, String searchQuery) {
      return tasks
          .where((task) => task['title']
          .toLowerCase()
          .contains(searchQuery.toLowerCase()))
          .toList();
    },
  );

  Stream<bool> get loadingStream => _loadingSubject.stream;

  List<Map<String, dynamic>> _tasks = [];

  HomePageBloc() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    _loadingSubject.add(true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      _tasks = List<Map<String, dynamic>>.from(json.decode(tasksString));
      _tasksSubject.add(_tasks);
    }
    _loadingSubject.add(false);
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksString = json.encode(_tasks);
    await prefs.setString('tasks', tasksString);
  }

  void addTask(String title, String description, String? dueDate) {
    _tasks.add({
      'title': title,
      'description': description,
      'completed': false,
      'dueDate': dueDate, // Store the due date
      'timestamp': DateTime.now().toString(),
    });
    _tasksSubject.add(_tasks);
    _saveTasks();
  }

  void editTask(int index, String newTitle, String newDescription, String? newDueDate) {
    _tasks[index]['title'] = newTitle;
    _tasks[index]['description'] = newDescription;
    _tasks[index]['dueDate'] = newDueDate; // Update due date
    _tasksSubject.add(_tasks);
    _saveTasks();
  }

  void toggleComplete(int index) {
    _tasks[index]['completed'] = !_tasks[index]['completed'];
    _tasksSubject.add(_tasks);
    _saveTasks();
  }

  void deleteCompletedTasks() {
    _tasks.removeWhere((task) => task['completed'] == true);
    _tasksSubject.add(_tasks);
    _saveTasks();
  }

  void searchTask(String query) {
    _searchSubject.add(query);
  }

  void dispose() {
    _tasksSubject.close();
    _searchSubject.close();
    _loadingSubject.close();
  }
}
