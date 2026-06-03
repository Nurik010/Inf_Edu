import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final String question;
  final List<String> options;
  final int correctIndex;
  final int? selectedIndex;
  final bool revealed;
  final void Function(int) onAnswer;

  const MultipleChoiceWidget({
    super.key,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.selectedIndex,
    required this.revealed,
    required this.onAnswer,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.quiz_outlined,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(widget.options.length, (index) {
          final isSelected = widget.selectedIndex == index;
          final isCorrect = index == widget.correctIndex;

          Color? bgColor;
          Color borderColor = Colors.grey.shade200;
          Color? textColor;
          IconData? icon;

          if (widget.revealed) {
            if (isCorrect) {
              bgColor = AppTheme.success.withAlpha(25);
              borderColor = AppTheme.success;
              textColor = AppTheme.success;
              icon = Icons.check_circle_rounded;
            } else if (isSelected) {
              bgColor = AppTheme.error.withAlpha(25);
              borderColor = AppTheme.error;
              textColor = AppTheme.error;
              icon = Icons.cancel_rounded;
            }
          } else if (isSelected) {
            bgColor = AppTheme.primary.withAlpha(25);
            borderColor = AppTheme.primary;
            textColor = AppTheme.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    widget.revealed ? null : () => widget.onAnswer(index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: bgColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: widget.revealed && isCorrect
                          ? 2
                          : isSelected
                              ? 2
                              : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected || (widget.revealed && isCorrect)
                              ? (textColor ?? AppTheme.primary).withAlpha(30)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: textColor ?? AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.options[index],
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor ?? AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.revealed && icon != null)
                        Icon(icon,
                            color: textColor ?? AppTheme.success, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
