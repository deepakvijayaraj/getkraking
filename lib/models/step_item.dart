class StepItem {
  StepItem({required this.text, this.done = false});

  String text;
  bool done;

  Map<String, dynamic> toJson() => {'text': text, 'done': done};

  factory StepItem.fromJson(Map<String, dynamic> json) => StepItem(
        text: json['text'] as String,
        done: json['done'] as bool? ?? false,
      );
}
