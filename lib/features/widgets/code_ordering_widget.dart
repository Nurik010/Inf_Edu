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

  void _acceptLine(int slotIndex, int data) {
    setState(() {
      if (data < 0) {
        final sourceSlot = -data - 1;
        if (sourceSlot == slotIndex) return;
        final lineIndex = _slots[sourceSlot];
        if (lineIndex == null) return;
        final oldLine = _slots[slotIndex];
        if (oldLine != null) {
          _usedLines[oldLine] = false;
        }
        _slots[sourceSlot] = null;
        _slots[slotIndex] = lineIndex;
      } else {
        if (_usedLines[data]) return;
        final oldLine = _slots[slotIndex];
        if (oldLine != null) {
          _usedLines[oldLine] = false;
        }
        _slots[slotIndex] = data;
        _usedLines[data] = true;
      }
    });

    if (_slots.every((s) => s != null)) {
      widget.onAnswer(_slots.cast<int>());
    }
  }

  void _returnLine(int slotIndex) {
    setState(() {
      final lineIndex = _slots[slotIndex];
      if (lineIndex == null) return;
      _slots[slotIndex] = null;
      _usedLines[lineIndex] = false;
    });
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
        DragTarget<int>(
          onAcceptWithDetails: (details) {
            if (details.data < 0) {
              final sourceSlot = -details.data - 1;
              _returnLine(sourceSlot);
            }
          },
          onWillAcceptWithDetails: (details) =>
              !widget.revealed && details.data < 0,
          builder: (context, candidates, rejected) {
            final isHovered = candidates.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHovered
                    ? AppTheme.primary.withAlpha(30)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHovered ? AppTheme.primary : Colors.grey.shade200,
                  width: isHovered ? 2 : 1,
                ),
              ),
              child: Column(
                children: List.generate(widget.codeLines.length, (i) {
                  if (_usedLines[i]) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child:
                        DraggableChip(label: widget.codeLines[i], index: i),
                  );
                }),
              ),
            );
          },
        ),
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
            child: DragTarget<int>(
              onAcceptWithDetails: (details) {
                if (!widget.revealed) _acceptLine(i, details.data);
              },
              onWillAcceptWithDetails: (details) {
                if (widget.revealed) return false;
                if (details.data < 0) {
                  return -details.data - 1 != i;
                }
                return !_usedLines[details.data];
              },
              builder: (context, candidates, rejected) {
                final isHovered = candidates.isNotEmpty;

                Color borderColor;
                Color bgColor;

                if (widget.revealed) {
                  final isCorrect = lineIndex != null &&
                      _slots[i] == widget.correctOrder[i];
                  bgColor = isCorrect
                      ? AppTheme.success.withAlpha(25)
                      : AppTheme.error.withAlpha(25);
                  borderColor = isCorrect ? AppTheme.success : AppTheme.error;
                } else if (lineIndex != null) {
                  bgColor = AppTheme.primary.withAlpha(25);
                  borderColor = AppTheme.primary;
                } else {
                  bgColor = isHovered
                      ? AppTheme.primary.withAlpha(30)
                      : Colors.grey.shade50;
                  borderColor = isHovered
                      ? AppTheme.primary
                      : Colors.grey.shade300;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor,
                      width: isHovered || lineIndex != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: lineIndex != null
                              ? AppTheme.primary.withAlpha(30)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: lineIndex != null
                                  ? AppTheme.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: lineIndex != null
                            ? widget.revealed
                                ? Text(
                                    widget.codeLines[lineIndex],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _slots[i] == widget.correctOrder[i]
                                          ? AppTheme.success
                                          : AppTheme.error,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : GestureDetector(
                                    onTap: () => _returnLine(i),
                                    child: LongPressDraggable<int>(
                                      data: -(i + 1),
                                      delay: const Duration(
                                          milliseconds: 100),
                                      feedback: Material(
                                        elevation: 6,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        shadowColor:
                                            AppTheme.primary.withAlpha(80),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 280),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient:
                                                AppTheme.primaryGradient,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            widget.codeLines[lineIndex],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.transparent,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${i + 1}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color:
                                                      Colors.grey.shade400,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Перетащите сюда',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(right: 6),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              widget.codeLines[lineIndex],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color:
                                                    AppTheme.textPrimary,
                                              ),
                                              maxLines: 3,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                      if (widget.revealed)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            lineIndex != null &&
                                    _slots[i] == widget.correctOrder[i]
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: lineIndex != null &&
                                    _slots[i] == widget.correctOrder[i]
                                ? AppTheme.success
                                : AppTheme.error,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
