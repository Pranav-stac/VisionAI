import 'dart:io';

class SceneDescription {
  final String id;
  final String description;
  final DateTime timestamp;
  final File? imageFile;
  final String? imagePath;
  final Map<String, String>? analysisResults;
  final List<SceneQuestion>? questions;
  final String? location;

  SceneDescription({
    required this.id,
    required this.description,
    required this.timestamp,
    this.imageFile,
    this.imagePath,
    this.analysisResults,
    this.questions,
    this.location,
  });

  // Create a copy with additional data
  SceneDescription copyWith({
    String? id,
    String? description,
    DateTime? timestamp,
    File? imageFile,
    String? imagePath,
    Map<String, String>? analysisResults,
    List<SceneQuestion>? questions,
    String? location,
  }) {
    return SceneDescription(
      id: id ?? this.id,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      imageFile: imageFile ?? this.imageFile,
      imagePath: imagePath ?? this.imagePath,
      analysisResults: analysisResults ?? this.analysisResults,
      questions: questions ?? this.questions,
      location: location ?? this.location,
    );
  }

  // Add an analysis result
  SceneDescription addAnalysisResult(String type, String result) {
    final newResults = Map<String, String>.from(analysisResults ?? {});
    newResults[type] = result;
    
    return copyWith(analysisResults: newResults);
  }

  // Add a question and answer
  SceneDescription addQuestion(SceneQuestion question) {
    final newQuestions = List<SceneQuestion>.from(questions ?? []);
    newQuestions.add(question);
    
    return copyWith(questions: newQuestions);
  }

  // Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'analysisResults': analysisResults,
      'questions': questions?.map((q) => q.toMap()).toList(),
      'location': location,
    };
  }

  // Create from a map
  factory SceneDescription.fromMap(Map<String, dynamic> map) {
    return SceneDescription(
      id: map['id'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      imagePath: map['imagePath'],
      analysisResults: map['analysisResults'] != null 
          ? Map<String, String>.from(map['analysisResults']) 
          : null,
      questions: map['questions'] != null 
          ? (map['questions'] as List).map((q) => SceneQuestion.fromMap(q)).toList() 
          : null,
      location: map['location'],
    );
  }
}

class SceneQuestion {
  final String question;
  final String answer;
  final DateTime timestamp;

  SceneQuestion({
    required this.question,
    required this.answer,
    required this.timestamp,
  });

  // Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from a map
  factory SceneQuestion.fromMap(Map<String, dynamic> map) {
    return SceneQuestion(
      question: map['question'],
      answer: map['answer'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
} 