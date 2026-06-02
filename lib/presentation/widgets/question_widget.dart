import 'package:flutter/material.dart';
import 'package:inf_edu_app/domain/entities/question_model.dart';
import 'package:inf_edu_app/presentation/widgets/multiple_choice_widget.dart';
import 'package:inf_edu_app/presentation/widgets/code_ordering_widget.dart';
import 'package:inf_edu_app/presentation/widgets/matching_widget.dart';

class QuestionWidget extends StatelessWidget {
  final QuestionModel question;
  final bool revealed;
  final dynamic userAnswer;
  final void Function(dynamic answer) onAnswer;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.revealed,
    this.userAnswer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question.text,
          options: question.options!,
          correctIndex: question.correctIndex!,
          selectedIndex: userAnswer as int?,
          revealed: revealed,
          onAnswer: (index) => onAnswer(index),
        );

      case QuestionType.codeOrdering:
        return CodeOrderingWidget(
          question: question.text,
          codeLines: question.codeLines!,
          correctOrder: question.correctOrder!,
          revealed: revealed,
          onAnswer: (order) => onAnswer(order),
        );

      case QuestionType.matching:
        return MatchingWidget(
          question: question.text,
          matchTerms: question.matchTerms!,
          matchDefinitions: question.matchDefinitions!,
          pairs: question.pairs!,
          revealed: revealed,
          onAnswer: (matches) => onAnswer(matches),
        );
    }
  }
}
