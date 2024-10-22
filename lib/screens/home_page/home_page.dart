import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  @override
  void dispose() {
    _bloc.dispose();
    taskController.dispose();
    descriptionController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading:false,
        title: Text('To-Do List',style:TextStyle(
          fontSize:20
        )),

      ),
      body: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 12 ),
        child: Column(
          children: [
            // Search Bar
            SizedBox(height:20),
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
                        SizedBox(height:20),

                       if(pendingTasks.isNotEmpty)...[
                         Align(
                           alignment: Alignment.centerLeft,

                           child: Text('Pending Tasks',
                               style: TextStyle(
                                   fontSize: 20, fontWeight: FontWeight.bold)),
                         ),
                         SizedBox(height:10),
                         ListView.builder(
                           shrinkWrap: true,
                           physics: const NeverScrollableScrollPhysics(),
                           itemCount: pendingTasks.length,
                           padding:EdgeInsets.zero,
                           itemBuilder: (context, index) {
                             return _buildTaskItem(
                                 pendingTasks[index],
                                 tasks.indexOf(pendingTasks[index]),
                                 isCompleted: false);
                           },
                         ),
                       ],
                        SizedBox(height:20),

                       if(completedTasks.isNotEmpty)...[
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text('Completed Tasks',
                                 style: TextStyle(
                                     fontSize: 20, fontWeight: FontWeight.bold)),
                             IconButton(
                               icon: Icon(Icons.delete),
                               onPressed: _bloc.deleteCompletedTasks,
                               tooltip: 'Delete Completed Tasks',
                             ),
                           ],
                         ),
                         SizedBox(height: 10),

                         ListView.builder(
                           shrinkWrap: true,
                           physics: const NeverScrollableScrollPhysics(),
                           padding:EdgeInsets.zero,

                           itemCount: completedTasks.length,
                           itemBuilder: (context, index) {
                             return _buildTaskItem(
                                 completedTasks[index],
                                 tasks.indexOf(completedTasks[index]),
                                 isCompleted: true);
                           },
                         ),
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

  Widget _buildTaskItem(
      Map<String, dynamic> task, int index, {required bool isCompleted}) {
    return Card(
      child: ListTile(
        title: Text(task['title']),
        subtitle: Text(task['description'] ?? ''),
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
              child: Text('Add'),
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  _bloc.addTask(taskController.text, descriptionController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, int index, Map<String, dynamic> task) {
    taskController.text = task['title'];
    descriptionController.text = task['description'] ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  _bloc.editTask(index, taskController.text, descriptionController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
