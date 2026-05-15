import '../models/question_model.dart';

class DefaultQuestions {
  static List<QuestionModel> getQuestions(String topicId) {
    // Пока возвращаем заглушки. Реальные вопросы будут в Firestore.
    return _fallbackQuestions;
  }

  static final List<QuestionModel> _fallbackQuestions = [
    QuestionModel(
      id: 'fallback_mc_1',
      text: 'Какое устройство является центральным в компьютере?',
      type: QuestionType.multipleChoice,
      options: ['Монитор', 'Процессор', 'Клавиатура', 'Принтер'],
      correctIndex: 1,
      explanation: 'Процессор (CPU) — центральное устройство, обрабатывающее данные.',
    ),
    QuestionModel(
      id: 'fallback_mc_2',
      text: 'Что такое переменная в программировании?',
      type: QuestionType.multipleChoice,
      options: [
        'Фиксированное число',
        'Именованная область памяти для хранения данных',
        'Тип данных',
        'Функция',
      ],
      correctIndex: 1,
      explanation: 'Переменная — это именованная область памяти, хранящая значение.',
    ),
    QuestionModel(
      id: 'fallback_code_1',
      text: 'Расставьте строки кода в правильном порядке для вычисления суммы двух чисел:',
      type: QuestionType.codeOrdering,
      codeLines: [
        'print("Сумма:", a + b)',
        'a = 5',
        'b = 3',
      ],
      correctOrder: [1, 2, 0],
      explanation: 'Сначала объявляем переменные, затем выводим результат.',
    ),
    QuestionModel(
      id: 'fallback_match_1',
      text: 'Сопоставьте термины с их определениями:',
      type: QuestionType.matching,
      matchTerms: ['Цикл', 'Функция', 'Массив'],
      matchDefinitions: [
        'Набор инструкций для повторения',
        'Блок кода для многократного использования',
        'Набор элементов одного типа',
      ],
      pairs: {
        'Цикл': 'Набор инструкций для повторения',
        'Функция': 'Блок кода для многократного использования',
        'Массив': 'Набор элементов одного типа',
      },
      explanation: 'Цикл повторяет код, функция переиспользуется, массив хранит набор данных.',
    ),
  ];
}
