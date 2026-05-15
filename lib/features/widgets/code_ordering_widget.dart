import 'package:flutter/material.dart';
import 'package:inf_edu_app/features/widgets/draggable_chip.dart';
import '../../core/theme/app_theme.dart';

class CodeOrderingWidget extends StatefulWidget {
  final String question;
  final List<String> codeLines;
  final List<int> correctOrder;
  final bool revealed;
  final void Function(List<int> order) onAnswer;

  const CodeOrderingWidget({
    super.key,
    required this.question,
    required this.codeLines,
    required this.correctOrder,
    required this.revealed,
    required this.onAnswer,
  });

  @override
  State<CodeOrderingWidget> createState() => _CodeOrderingWidgetState();
}

class _CodeOrderingWidgetState extends State<CodeOrderingWidget> {
  late List<int?> _slots;
  late List<bool> _usedLines;

  @override
  void initState() {
    super.initState();
    _slots = List.filled(widget.codeLines.length, null);
    _usedLines = List.filled(widget.codeLines.length, false);
  }

  void _acceptLine(int slotIndex, int lineIndex) {
    setState(() {
      final oldLine = _slots[slotIndex];
      if (oldLine != null) {
        _usedLines[oldLine] = false;
      }
      _slots[slotIndex] = lineIndex;
      _usedLines[lineIndex] = true;
    });

    if (_slots.every((s) => s != null)) {
      widget.onAnswer(_slots.cast<int>());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.code, color: AppTheme.primary, size: 22),
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppTheme.warning),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Расставьте в правильном порядке',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Доступные строки:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.codeLines.every((_) => true))
          ...List.generate(widget.codeLines.length, (i) {
            if (_usedLines[i]) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DraggableChip(label: widget.codeLines[i], index: i),
            );
          }),
        const SizedBox(height: 20),
        const Text(
          'Ваш порядок:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(widget.codeLines.length, (i) {
          final lineIndex = _slots[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: DragTargetSlot(
              index: i,
              label: lineIndex != null ? widget.codeLines[lineIndex] : null,
              revealed: widget.revealed,
              isCorrect: widget.revealed && lineIndex != null
                  ? _slots[i] == widget.correctOrder[i]
                  : false,
              onAccept: (data) {
                if (data != null && !widget.revealed) {
                  _acceptLine(i, data);
                }
              },
            ),
          );
        }),
      ],
    );
  }
}
