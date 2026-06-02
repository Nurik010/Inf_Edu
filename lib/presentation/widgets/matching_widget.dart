  import 'package:flutter/material.dart';
  import 'package:inf_edu_app/presentation/widgets/draggable_chip.dart';
  import '../../core/theme/app_theme.dart';

  class MatchingWidget extends StatefulWidget {
    final String question;
    final List<String> matchTerms;
    final List<String> matchDefinitions;
    final Map<String, String> pairs;
    final bool revealed;
    final void Function(Map<String, String> matches) onAnswer;

    const MatchingWidget({
      super.key,
      required this.question,
      required this.matchTerms,
      required this.matchDefinitions,
      required this.pairs,
      required this.revealed,
      required this.onAnswer,
    });

    @override
    State<MatchingWidget> createState() => _MatchingWidgetState();
  }

  class _MatchingWidgetState extends State<MatchingWidget> {
    late Map<String, String?> _matches;
    late List<bool> _usedTerms;

    @override
    void initState() {
      super.initState();
      _matches = {for (final d in widget.matchDefinitions) d: null};
      _usedTerms = List.filled(widget.matchTerms.length, false);
    }

    void _acceptTerm(String definition, int termIndex) {
      if (termIndex < 0 || termIndex >= widget.matchTerms.length) return;
      setState(() {
        final term = widget.matchTerms[termIndex];
        final prevDefForTerm = _matches.entries
            .firstWhere(
              (e) => e.value == term,
              orElse: () => const MapEntry('', null),
            )
            .key;
        if (prevDefForTerm.isNotEmpty) {
          _matches[prevDefForTerm] = null;
        }
        final prevTerm = _matches[definition];
        if (prevTerm != null) {
          final prevIndex = widget.matchTerms.indexOf(prevTerm);
          if (prevIndex != -1) _usedTerms[prevIndex] = false;
        }
        _matches[definition] = term;
        _usedTerms[termIndex] = true;
      });

      if (_matches.values.every((v) => v != null)) {
        widget.onAnswer(_matches.map((key, value) => MapEntry(key, value!)));
      }
    }

    void _returnTerm(String definition) {
      setState(() {
        final term = _matches[definition];
        if (term == null) return;
        final termIndex = widget.matchTerms.indexOf(term);
        if (termIndex != -1) _usedTerms[termIndex] = false;
        _matches[definition] = null;
      });
      if (_matches.values.every((v) => v != null)) {
        widget.onAnswer(_matches.map((key, value) => MapEntry(key, value!)));
      }
    }

    void _returnTermByIndex(int termIndex) {
      if (termIndex < 0 || termIndex >= widget.matchTerms.length) return;
      final term = widget.matchTerms[termIndex];
      final def = _matches.entries
          .firstWhere(
            (e) => e.value == term,
            orElse: () => const MapEntry('', null),
          )
          .key;
      if (def.isNotEmpty) _returnTerm(def);
    }

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
                  child: Icon(Icons.link, color: AppTheme.primary, size: 22),
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
                    'Перетащите термин к его определению',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Термины:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DragTarget<int>(
            onAcceptWithDetails: (details) => _returnTermByIndex(details.data),
            onWillAcceptWithDetails: (details) =>
                details.data < _usedTerms.length && !_usedTerms[details.data] && widget.matchTerms.length > details.data,
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
                  children: List.generate(widget.matchTerms.length, (i) {
                    if (_usedTerms[i]) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: DraggableChip(
                          label: widget.matchTerms[i], index: i),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Определения:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(widget.matchDefinitions.length, (i) {
            final def = widget.matchDefinitions[i];
            final matchedTerm = _matches[def];
            final isCorrect = widget.revealed && matchedTerm != null
                ? widget.pairs[matchedTerm] == def
                : false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DragTarget<int>(
                onAcceptWithDetails: (details) {
                  if (!widget.revealed) _acceptTerm(def, details.data);
                },
                builder: (context, candidates, rejected) {
                  final isHovered = candidates.isNotEmpty;

                  Color bgColor;
                  Color borderColor;

                  if (widget.revealed) {
                    bgColor = isCorrect
                        ? AppTheme.success.withAlpha(25)
                        : AppTheme.error.withAlpha(25);
                    borderColor = isCorrect ? AppTheme.success : AppTheme.error;
                  } else if (matchedTerm != null) {
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: isHovered || matchedTerm != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                def,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (matchedTerm != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: GestureDetector(
                                    onTap: widget.revealed
                                        ? null
                                        : () => _returnTerm(def),
                                    child: widget.revealed
                                        ? Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCorrect
                                                  ? AppTheme.success
                                                      .withAlpha(40)
                                                  : AppTheme.error
                                                      .withAlpha(40),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Text(
                                                  matchedTerm,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: isCorrect
                                                        ? AppTheme.success
                                                        : AppTheme.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : LongPressDraggable<int>(
                                            data: widget.matchTerms
                                                .indexOf(matchedTerm),
                                            delay: const Duration(
                                                milliseconds: 100),
                                            feedback: Material(
                                              elevation: 6,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              shadowColor: AppTheme.primary
                                                  .withAlpha(80),
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      AppTheme.primaryGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                                child: Text(
                                                  matchedTerm,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                matchedTerm,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey
                                                      .shade400,
                                                  fontStyle:
                                                      FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withAlpha(40),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.only(
                                                            right: 6),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 14,
                                                      color:
                                                          AppTheme.primary,
                                                    ),
                                                  ),
                                                  Text(
                                                    matchedTerm,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppTheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.revealed)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? AppTheme.success : AppTheme.error,
                              size: 22,
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
