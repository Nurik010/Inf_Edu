enum QuestionType { multipleChoice, codeOrdering, matching }

class QuestionModel {
  final String id;
  final String text;
  final QuestionType type;
  final String explanation;

  // multiple choice
  final List<String>? options;
  final int? correctIndex;

  // code ordering
  final List<String>? codeLines;
  final List<int>? correctOrder;

  // matching
  final List<String>? matchTerms;
  final List<String>? matchDefinitions;
  final Map<String, String>? pairs;

  QuestionModel({
    required this.id,
    required this.text,
    required this.type,
    this.explanation = '',
    this.options,
    this.correctIndex,
    this.codeLines,
    this.correctOrder,
    this.matchTerms,
    this.matchDefinitions,
    this.pairs,
  });

  factory QuestionModel.fromJson(String id, Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'multipleChoice';
    final type = QuestionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => QuestionType.multipleChoice,
    );

    return QuestionModel(
      id: id,
      text: json['text'] ?? '',
      type: type,
      explanation: json['explanation'] ?? '',
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      correctIndex: json['correctIndex'] is String
          ? int.tryParse(json['correctIndex'] as String)
          : json['correctIndex'] as int?,
      codeLines: json['codeLines'] != null ? List<String>.from(json['codeLines']) : null,
      correctOrder: json['correctOrder'] != null ? List<int>.from(json['correctOrder']) : null,
      matchTerms: json['matchTerms'] != null ? List<String>.from(json['matchTerms']) : null,
      matchDefinitions: json['matchDefinitions'] != null ? List<String>.from(json['matchDefinitions']) : null,
      pairs: json['pairs'] != null ? Map<String, String>.from(json['pairs']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type.name,
      'explanation': explanation,
      'options': options,
      'correctIndex': correctIndex,
      'codeLines': codeLines,
      'correctOrder': correctOrder,
      'matchTerms': matchTerms,
      'matchDefinitions': matchDefinitions,
      'pairs': pairs,
    };
  }
}
