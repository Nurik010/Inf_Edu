class TopicModel {
  final String id;
  final String title;
  final String content;
  final String grade;
  final int order;

  TopicModel({
    required this.id,
    required this.title,
    required this.content,
    required this.grade,
    required this.order,
  });

  factory TopicModel.fromJson(String id, Map<String, dynamic> json) {
    return TopicModel(
      id: id,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      grade: json['grade'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}