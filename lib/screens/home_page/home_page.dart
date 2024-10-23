import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/screens/home_page/bloc/home_page_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomePageBloc _bloc = HomePageBloc();
  final TextEditingController taskController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Task item with actions
  Widget _buildTaskItem(
      Map<String, dynamic> task, int index, {required bool isCompleted}) {
    return Card(
      child: ListTile(
        title: Text(task['title']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task['description'] != null && task['description'].isNotEmpty)
              Text(task['description']),
            if (task['dueDate'] != null)
              Text('Due: ${task['dueDate']}', style: TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task['completed'],
              onChanged: (bool? value) {
                _bloc.toggleComplete(index);
              },
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _showEditTaskDialog(context, index, task),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for adding a task
  void _showAddTaskDialog(BuildContext context) {
    taskController.clear();
    descriptionController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: InputDecoration(hintText: 'Task Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(hintText: 'Task Description'),
              ),
              SizedBox(height: 10),

              // Wrap due date selection in a StreamBuilder
              StreamBuilder<DateTime?>(
                stream: _bloc.dueDateStream,
                builder: (context, snapshot) {
                  return Row(
                    children: [
                      Text(snapshot.hasData
                          ? 'Due: ${DateFormat.yMMMd().format(snapshot.data!)}'
                          : 'No due date'),
                      IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDueDate(context),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                _bloc.updateDueDate(null);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                _bloc.updateDueDate(null);

                if (taskController.text.isNotEmpty) {
                  // Now you can access the due date safely
                  final dueDate = _bloc.currentDueDate != null
                      ? DateFormat.yMMMd().format(_bloc.currentDueDate!)
                      : null;
                  _bloc.addTask(
                    taskController.text,
                    descriptionController.text,
                    dueDate,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }


  // Dialog for editing a task
  void _showEditTaskDialog(BuildContext context, int index, Map<String, dynamic> task) {
    taskController.text = task['title'];
    descriptionController.text = task['description'] ?? '';
    _bloc.updateDueDate(task['dueDate'] != null
        ? DateFormat.yMMMd().parse(task['dueDate'])
        : null);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime? selectedDueDate; // Define a local variable for due date

        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: InputDecoration(hintText: 'Task Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(hintText: 'Task Description'),
              ),
              SizedBox(height: 10),
              StreamBuilder<DateTime?>(
                stream: _bloc.dueDateStream,
                builder: (context, snapshot) {
                  selectedDueDate = snapshot.data; // Update the local variable
                  return Row(
                    children: [
                      Text(snapshot.hasData
                          ? 'Due: ${DateFormat.yMMMd().format(snapshot.data!)}'
                          : 'No due date'),
                      IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDueDate(context),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  // Use the locally updated due date
                  _bloc.editTask(
                    index,
                    taskController.text,
                    descriptionController.text,
                    selectedDueDate != null
                        ? DateFormat.yMMMd().format(selectedDueDate!)
                        : null,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Date picker
  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,

      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      _bloc.updateDueDate(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('To-Do List', style: TextStyle(fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Search Bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _bloc.searchTask,
            ),
            // Task List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _bloc.tasksStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No tasks found'));
                  }

                  final tasks = snapshot.data!;
                  final pendingTasks =
                  tasks.where((task) => !task['completed']).toList();
                  final completedTasks =
                  tasks.where((task) => task['completed']).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        if (pendingTasks.isNotEmpty) ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Pending Tasks',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingTasks.length,
                            itemBuilder: (context, index) {
                              return _buildTaskItem(
                                  pendingTasks[index],
                                  tasks.indexOf(pendingTasks[index]),
                                  isCompleted: false);
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (completedTasks.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Completed Tasks',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: _bloc.deleteCompletedTasks,
                                tooltip: 'Delete Completed Tasks',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: completedTasks.length,
                            itemBuilder: (context, index) {
                              return _buildTaskItem(
                                  completedTasks[index],
                                  tasks.indexOf(completedTasks[index]),
                                  isCompleted: true);
                            },
                          ),
                          const SizedBox(height: 50),
                        ]
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _bloc.dispose();
    taskController.dispose();
    descriptionController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
