class Test {
  final String id;
  final String userId;
  final String title;
  final int totalItems;
  final Map<String, dynamic> answerKey; // JSONB field - question index -> correct answer
  final DateTime createdAt;

  Test({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalItems,
    required this.answerKey,
    required this.createdAt,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      totalItems: json['total_items'],
      answerKey: Map<String, dynamic>.from(json['answer_key'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'total_items': totalItems,
      'answer_key': answerKey,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to get answer key as Map<int, int> for easier processing
  Map<int, int> get answerKeyAsIntMap {
    Map<int, int> result = {};
    answerKey.forEach((key, value) {
      final intKey = int.tryParse(key.toString());
      final intValue = int.tryParse(value.toString());
      if (intKey != null && intValue != null) {
        result[intKey] = intValue;
      }
    });
    return result;
  }
}

class TestResult {
  final String id;
  final String testId;
  final String studentName;
  final String studentId;
  final List<String> studentAnswers; // A, B, C, D, E or null for unanswered
  final int score;
  final double percentage;
  final DateTime submittedAt;
  final String? imageUrl;

  TestResult({
    required this.id,
    required this.testId,
    required this.studentName,
    required this.studentId,
    required this.studentAnswers,
    required this.score,
    required this.percentage,
    required this.submittedAt,
    this.imageUrl,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      testId: json['test_id'],
      studentName: json['student_name'],
      studentId: json['student_id'],
      studentAnswers: List<String>.from(json['student_answers']),
      score: json['score'],
      percentage: json['percentage'].toDouble(),
      submittedAt: DateTime.parse(json['submitted_at']),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_id': testId,
      'student_name': studentName,
      'student_id': studentId,
      'student_answers': studentAnswers,
      'score': score,
      'percentage': percentage,
      'submitted_at': submittedAt.toIso8601String(),
      'image_url': imageUrl,
    };
  }
}

// Local model for processing results (not stored in Supabase)
class ProcessingResult {
  final String testId;
  final String studentName;
  final String studentId;
  final List<String> detectedAnswers; // A, B, C, D, E
  final int score;
  final double percentage;
  final DateTime processedAt;
  final String? imageUrl;

  ProcessingResult({
    required this.testId,
    required this.studentName,
    required this.studentId,
    required this.detectedAnswers,
    required this.score,
    required this.percentage,
    required this.processedAt,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'test_id': testId,
      'student_name': studentName,
      'student_id': studentId,
      'detected_answers': detectedAnswers,
      'score': score,
      'percentage': percentage,
      'processed_at': processedAt.toIso8601String(),
      'image_url': imageUrl,
    };
  }
} 