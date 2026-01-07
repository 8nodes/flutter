import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http';

const String baseUrl = 'http://localhost:3000';

class AddItem extends StatefulWidget {
  const AddItem({Key? key}) : super(key: key);

  @override
  _AddItemState createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _stepControllers = [];

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers.removeAt(index);
    });
  }

  /// CREATE
  Future<void> _submit() async {
    final steps = _stepControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => {
              'description': c.text,
              'completed': false,
            })
        .toList();

    final payload = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'steps': steps,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/todos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      throw Exception('Failed to create todo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Todo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                icon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                icon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Steps',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ..._stepControllers.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final controller = entry.value;

                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration:
                            InputDecoration(labelText: 'Step ${index + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeStep(index),
                    ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addStep,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
