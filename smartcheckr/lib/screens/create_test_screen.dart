import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../bloc/omr_bloc.dart';
import '../models/test_model.dart';
import '../main.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalItemsController = TextEditingController();
  
  List<int> _answerKey = [];
  
  @override
  void initState() {
    super.initState();
    _totalItemsController.text = '5'; // Default to 5 questions
    _updateAnswerKey(5);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalItemsController.dispose();
    super.dispose();
  }

  void _updateAnswerKey(int totalItems) {
    setState(() {
      if (totalItems > _answerKey.length) {
        // Add more answers with default value A (0)
        _answerKey.addAll(List.filled(totalItems - _answerKey.length, 0));
      } else if (totalItems < _answerKey.length) {
        // Remove excess answers
        _answerKey = _answerKey.take(totalItems).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Test'),
        actions: [
          TextButton(
            onPressed: _saveTest,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: BlocListener<OmrBloc, OmrState>(
        listener: (context, state) {
          if (state is TestCreated) {
            Navigator.pop(context);
          } else if (state is OmrError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Test Title
                Text(
                  'Test Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Test Title',
                    hintText: 'Enter test title',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a test title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Number of Questions
                TextFormField(
                  controller: _totalItemsController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Questions',
                    hintText: 'Enter number of questions (1-50)',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter number of questions';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 1 || number > 50) {
                      return 'Please enter a number between 1 and 50';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final number = int.tryParse(value);
                    if (number != null && number >= 1 && number <= 50) {
                      _updateAnswerKey(number);
                    }
                  },
                ),
                const SizedBox(height: 32),
                
                // Answer Key Section
                Text(
                  'Answer Key',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set the correct answer for each question',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                
                // Answer Key Grid
                if (_answerKey.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'Question',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Expanded(
                                flex: 3,
                                child: Text(
                                  'Correct Answer',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Answer rows
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _answerKey.length,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: index < _answerKey.length - 1 
                                        ? Colors.grey[200]! 
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${index + 1}.',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: ['A', 'B', 'C', 'D', 'E'].asMap().entries.map((entry) {
                                        int answerIndex = entry.key;
                                        String answerLetter = entry.value;
                                        
                                        return Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _answerKey[index] = answerIndex;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 2),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: _answerKey[index] == answerIndex 
                                                    ? Colors.blue 
                                                    : Colors.grey[200],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                answerLetter,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: _answerKey[index] == answerIndex 
                                                      ? Colors.white 
                                                      : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _setAllAnswers,
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Quick Fill'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetAnswers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTest,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Create Test',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setAllAnswers() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quick Fill'),
          content: const Text('Set all answers to the same choice?'),
          actions: ['A', 'B', 'C', 'D', 'E'].asMap().entries.map((entry) {
            int index = entry.key;
            String letter = entry.value;
            
            return TextButton(
              onPressed: () {
                setState(() {
                  _answerKey = List.filled(_answerKey.length, index);
                });
                Navigator.pop(context);
              },
              child: Text(letter),
            );
          }).toList()..add(
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        );
      },
    );
  }

  void _resetAnswers() {
    setState(() {
      _answerKey = List.filled(_answerKey.length, 0); // Reset all to A
    });
  }

  void _saveTest() {
    if (_formKey.currentState!.validate()) {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create a test'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert answer key to Map<String, dynamic>
      Map<String, dynamic> answerKeyMap = {};
      for (int i = 0; i < _answerKey.length; i++) {
        answerKeyMap[i.toString()] = _answerKey[i];
      }

      final test = Test(
        id: const Uuid().v4(),
        userId: user.id,
        title: _titleController.text.trim(),
        totalItems: int.parse(_totalItemsController.text),
        answerKey: answerKeyMap,
        createdAt: DateTime.now(),
      );

      context.read<OmrBloc>().add(CreateTest(test));
    }
  }
} 