import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/test_model.dart';
import '../main.dart';

class OmrService {
  static const String baseUrl = 'http://localhost:5000'; // Your Python API URL
  
  // Process OMR image and get detected answers
  Future<List<String>> processOmrImage(File imageFile, int numberOfQuestions) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/process_omr'));
      request.fields['num_questions'] = numberOfQuestions.toString();
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var data = json.decode(responseBody);
        return List<String>.from(data['answers']);
      } else {
        throw Exception('Failed to process OMR image: $responseBody');
      }
    } catch (e) {
      throw Exception('Error processing OMR image: $e');
    }
  }

  // Save test to Supabase
  Future<void> saveTest(Test test) async {
    try {
      await supabase.from('Tests').insert(test.toJson());
    } catch (e) {
      throw Exception('Failed to save test: $e');
    }
  }

  // Get all tests from Supabase for current user
  Future<List<Test>> getTests() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final response = await supabase
          .from('Tests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return response.map<Test>((json) => Test.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tests: $e');
    }
  }

  // Get specific test by ID
  Future<Test> getTest(String testId) async {
    try {
      final response = await supabase.from('Tests').select().eq('id', testId).single();
      return Test.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch test: $e');
    }
  }

  // Update test
  Future<void> updateTest(Test test) async {
    try {
      await supabase.from('Tests').update(test.toJson()).eq('id', test.id);
    } catch (e) {
      throw Exception('Failed to update test: $e');
    }
  }

  // Delete test
  Future<void> deleteTest(String testId) async {
    try {
      await supabase.from('Tests').delete().eq('id', testId);
    } catch (e) {
      throw Exception('Failed to delete test: $e');
    }
  }

  // Upload image to Supabase Storage
  Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      final bytes = await imageFile.readAsBytes();
      await supabase.storage.from('answer_sheets').uploadBinary(fileName, bytes);
      
      final url = supabase.storage.from('answer_sheets').getPublicUrl(fileName);
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Process answer sheet and return results (not stored in database)
  Future<ProcessingResult> processAnswerSheet({
    required File imageFile,
    required String testId,
    required String studentName,
    required String studentId,
  }) async {
    try {
      // Get the test details
      final test = await getTest(testId);
      
      // Process the OMR image
      final detectedAnswers = await processOmrImage(imageFile, test.totalItems);
      
      // Upload the image
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${studentId}.jpg';
      final imageUrl = await uploadImage(imageFile, fileName);
      
      // Calculate score
      final scoreData = calculateScore(detectedAnswers, test.answerKeyAsIntMap);
      
      // Create processing result
      final result = ProcessingResult(
        testId: testId,
        studentName: studentName,
        studentId: studentId,
        detectedAnswers: detectedAnswers,
        score: scoreData['score'],
        percentage: scoreData['percentage'],
        processedAt: DateTime.now(),
        imageUrl: imageUrl,
      );
      
      return result;
    } catch (e) {
      throw Exception('Failed to process answer sheet: $e');
    }
  }

  // Calculate score and percentage
  Map<String, dynamic> calculateScore(List<String> studentAnswers, Map<int, int> answerKey) {
    int correct = 0;
    int total = answerKey.length;
    
    for (int i = 0; i < studentAnswers.length && i < total; i++) {
      String studentAnswer = studentAnswers[i];
      int correctAnswerIndex = answerKey[i] ?? 0;
      String correctAnswer = String.fromCharCode(65 + correctAnswerIndex); // A=0, B=1, etc.
      
      if (studentAnswer == correctAnswer) {
        correct++;
      }
    }
    
    double percentage = total > 0 ? (correct / total) * 100 : 0;
    
    return {
      'score': correct,
      'total': total,
      'percentage': percentage,
    };
  }

  // Generate a sample answer key for testing
  Map<String, dynamic> generateSampleAnswerKey(int totalItems) {
    Map<String, dynamic> answerKey = {};
    for (int i = 0; i < totalItems; i++) {
      answerKey[i.toString()] = (i % 5); // Rotate through A(0), B(1), C(2), D(3), E(4)
    }
    return answerKey;
  }
} 