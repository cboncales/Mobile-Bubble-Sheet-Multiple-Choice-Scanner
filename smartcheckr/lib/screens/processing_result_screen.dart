import 'package:flutter/material.dart';
import '../models/test_model.dart';

class ProcessingResultScreen extends StatelessWidget {
  final ProcessingResult result;
  final Test test;

  const ProcessingResultScreen({
    super.key,
    required this.result,
    required this.test,
  });

  @override
  Widget build(BuildContext context) {
    final correctAnswers = test.answerKeyAsIntMap;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareResult(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Score Circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getScoreColor(result.percentage).withOpacity(0.1),
                        border: Border.all(
                          color: _getScoreColor(result.percentage),
                          width: 4,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${result.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(result.percentage),
                            ),
                          ),
                          Text(
                            '${result.score}/${correctAnswers.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Student Info
                    Text(
                      result.studentName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${result.studentId}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test: ${test.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Processed: ${_formatDateTime(result.processedAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Detailed Results
            Text(
              'Detailed Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Answers Comparison
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
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Question',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Student',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Correct',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Result',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Answer rows
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: correctAnswers.length,
                    itemBuilder: (context, index) {
                      String studentAnswer = index < result.detectedAnswers.length 
                          ? result.detectedAnswers[index] 
                          : 'N/A';
                      
                      int correctAnswerIndex = correctAnswers[index] ?? 0;
                      String correctAnswer = String.fromCharCode(65 + correctAnswerIndex);
                      
                      bool isCorrect = studentAnswer == correctAnswer;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isCorrect 
                              ? Colors.green.withOpacity(0.05)
                              : (studentAnswer == 'N/A' 
                                  ? Colors.grey.withOpacity(0.05)
                                  : Colors.red.withOpacity(0.05)),
                          border: Border(
                            bottom: BorderSide(
                              color: index < correctAnswers.length - 1 
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
                              flex: 2,
                              child: Text(
                                studentAnswer,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: studentAnswer == 'N/A' 
                                      ? Colors.grey[600]
                                      : (isCorrect ? Colors.green : Colors.red),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                correctAnswer,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Icon(
                                isCorrect 
                                    ? Icons.check_circle 
                                    : (studentAnswer == 'N/A' 
                                        ? Icons.help_outline
                                        : Icons.cancel),
                                color: isCorrect 
                                    ? Colors.green 
                                    : (studentAnswer == 'N/A' 
                                        ? Colors.grey 
                                        : Colors.red),
                                size: 20,
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
            
            const SizedBox(height: 24),
            
            // Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatItem('Correct Answers', '${result.score}', Colors.green),
                    _buildStatItem('Wrong Answers', '${_getWrongCount()}', Colors.red),
                    _buildStatItem('Unanswered', '${_getUnansweredCount()}', Colors.grey),
                    _buildStatItem('Total Questions', '${correctAnswers.length}', Colors.blue),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  int _getWrongCount() {
    int wrong = 0;
    final correctAnswers = test.answerKeyAsIntMap;
    
    for (int i = 0; i < correctAnswers.length; i++) {
      String studentAnswer = i < result.detectedAnswers.length 
          ? result.detectedAnswers[i] 
          : 'N/A';
      
      if (studentAnswer != 'N/A') {
        int correctAnswerIndex = correctAnswers[i] ?? 0;
        String correctAnswer = String.fromCharCode(65 + correctAnswerIndex);
        
        if (studentAnswer != correctAnswer) {
          wrong++;
        }
      }
    }
    
    return wrong;
  }

  int _getUnansweredCount() {
    return result.detectedAnswers.where((answer) => answer == 'N/A').length;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareResult(BuildContext context) {
    // Implement result sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
      ),
    );
  }
} 