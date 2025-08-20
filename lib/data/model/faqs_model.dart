class FaqsModel {
  FaqsModel({this.id, this.question, this.answer});

  FaqsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    question = json['question']?.toString() ?? '';
    answer = json['answer']?.toString() ?? '';
  }
  int? id;
  String? question;
  String? answer;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['question'] = question;
    data['answer'] = answer;
    return data;
  }

  FaqsModel copyWith({int? id, String? question, String? answer}) => FaqsModel(
        id: id ?? this.id,
        question: question ?? this.question,
        answer: answer ?? this.answer,
      );
}
