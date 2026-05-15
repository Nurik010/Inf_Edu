import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DraggableChip extends StatelessWidget {
  final String label;
  final int index;

  const DraggableChip({super.key, required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 100),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        shadowColor: AppTheme.primary.withAlpha(80),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Container(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withAlpha(80)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class DragTargetSlot extends StatelessWidget {
  final String? label;
  final int index;
  final bool isCorrect;
  final bool revealed;
  final void Function(int?) onAccept;

  const DragTargetSlot({
    super.key,
    this.label,
    required this.index,
    required this.isCorrect,
    required this.revealed,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;

    if (revealed) {
      borderColor = isCorrect ? AppTheme.success : AppTheme.error;
      bgColor = isCorrect
          ? AppTheme.success.withAlpha(25)
          : AppTheme.error.withAlpha(25);
    } else if (label != null) {
      borderColor = AppTheme.primary;
      bgColor = AppTheme.primary.withAlpha(25);
    } else {
      borderColor = Colors.grey.shade300;
      bgColor = Colors.grey.shade50;
    }

    return DragTarget<int>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isHovered ? AppTheme.primary.withAlpha(30) : bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHovered ? AppTheme.primary : borderColor,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: label != null
                      ? AppTheme.primary.withAlpha(30)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: label != null ? AppTheme.primary : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: label != null
                    ? Text(
                        label!,
                        style: TextStyle(
                          fontSize: 14,
                          color: revealed
                              ? (isCorrect ? AppTheme.success : AppTheme.error)
                              : AppTheme.textPrimary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        'Перетащите сюда',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              if (revealed)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? AppTheme.success : AppTheme.error,
                    size: 20,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
