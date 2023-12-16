// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Todo {
  final String id;
  final String title;
  final String description;
  final List<Step> steps;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });
}

class Step {
  final String description;
  bool completed;
  final String id;

  Step({
    required this.description,
    required this.completed,
    required this.id,
  });
}

class ItemView extends StatefulWidget {
  const ItemView({Key? key}) : super(key: key);

  @override
  _ItemViewState createState() => _ItemViewState();
}

class _ItemViewState extends State<ItemView> {
  Future<List<Todo>>? todosFuture;

  @override
  void initState() {
    super.initState();
    todosFuture = fetchTodos();
  }

  Future<List<Todo>> fetchTodos() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/todos'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Todo> fetchedTodos = data
            .map((item) => Todo(
                  id: item['_id'] as String,
                  title: item['title'] as String,
                  description: item['description'] as String,
                  steps: (item['steps'] as List<dynamic>)
                      .map((step) => Step(
                            description: step['description'] as String,
                            completed: step['completed'] as bool,
                            id: step['_id'] as String,
                          ))
                      .toList(),
                ))
            .toList();
        return fetchedTodos;
      } else {
        throw Exception('Failed to load todos');
      }
    } catch (error) {
      print(error);
      throw Exception('Failed to load todos');
    }
  }

  void deleteTodo(String todoId) async {
    setState(() {
      todosFuture = fetchTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Todos'),
        ),
        body: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          child: FutureBuilder(
            future: todosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<Todo> todos = snapshot.data as List<Todo>;
                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(todos[index].id),
                      background: Container(
                        color: Colors.red,
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      onDismissed: (direction) {
                        deleteTodo(todos[index].id);
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Title: ${todos[index].title}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Description: ${todos[index].description}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Steps:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (var step in todos[index].steps)
                                ListTile(
                                  title: Text(
                                    step.description,
                                    style: TextStyle(
                                      decoration: step.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  leading: Checkbox(
                                    value: step.completed,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        step.completed = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              todosFuture = fetchTodos();
            });
          },
          tooltip: 'Reload',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

void main() {
  runApp(const ItemView());
}
