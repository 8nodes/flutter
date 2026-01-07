import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_item.dart';

const String baseUrl = 'http://localhost:3000';

class Todo {
  final String id;
  final String title;
  final String description;
  final List<TodoStep> steps;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      steps: (json['steps'] as List)
          .map((s) => TodoStep.fromJson(s))
          .toList(),
    );
  }
}

class TodoStep {
  final String id;
  final String description;
  bool completed;

  TodoStep({
    required this.id,
    required this.description,
    required this.completed,
  });

  factory TodoStep.fromJson(Map<String, dynamic> json) {
    return TodoStep(
      id: json['_id'],
      description: json['description'],
      completed: json['completed'],
    );
  }
}


class ItemView extends StatefulWidget {
  const ItemView({Key? key}) : super(key: key);

  @override
  _ItemViewState createState() => _ItemViewState();
}

class _ItemViewState extends State<ItemView> {
  late Future<List<Todo>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() {
    _todosFuture = fetchTodos();
  }

  /// READ
  Future<List<Todo>> fetchTodos() async {
    final response = await http.get(Uri.parse('$baseUrl/todos'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load todos');
    }

    final List data = json.decode(response.body);
    return data.map((e) => Todo.fromJson(e)).toList();
  }

  /// DELETE
  Future<void> deleteTodo(String id) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/todos/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete todo');
    }

    _loadTodos();
    setState(() {});
  }

  /// UPDATE STEP COMPLETION
  Future<void> toggleStep(
    String todoId,
    TodoStep step,
  ) async {
    step.completed = !step.completed;
    setState(() {});

    await http.patch(
      Uri.parse('$baseUrl/todos/$todoId/steps/${step.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'completed': step.completed}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Todos'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItem()),
                );
                _loadTodos();
                setState(() {});
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Todo>>(
            future: _todosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }

              final todos = snapshot.data!;
              if (todos.isEmpty) {
                return const Center(child: Text('No todos yet'));
              }

              return ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];

                  return Dismissible(
                    key: Key(todo.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => deleteTodo(todo.id),
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todo.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(todo.description),
                            const Divider(height: 24),
                            const Text(
                              'Steps',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...todo.steps.map(
                              (step) => CheckboxListTile(
                                value: step.completed,
                                title: Text(
                                  step.description,
                                  style: TextStyle(
                                    decoration: step.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                onChanged: (_) =>
                                    toggleStep(todo.id, step),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const ItemView());
}
