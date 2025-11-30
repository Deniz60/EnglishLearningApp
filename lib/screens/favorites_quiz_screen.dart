import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../models/lesson.dart';
import '../providers/progress_provider.dart';
import '../services/tts_service.dart';
import '../utils/constants.dart';

class QuizQuestion {
  final String english;
  final String correctAnswer;
  final List<String> options;
  final String? example;

  QuizQuestion({
    required this.english,
    required this.correctAnswer,
    required this.options,
    this.example,
  });
}

class FavoritesQuizScreen extends StatefulWidget {
  const FavoritesQuizScreen({super.key});

  @override
  State<FavoritesQuizScreen> createState() => _FavoritesQuizScreenState();
}

class _FavoritesQuizScreenState extends State<FavoritesQuizScreen> {
  late List<Lesson> _lessons;
  late String _category;
  late List<QuizQuestion> _questions;
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _lessons = args['lessons'] as List<Lesson>;
    _category = args['category'] as String;
    
    // Quiz sorularını oluştur
    _questions = _generateQuestions(_lessons);
  }

  List<QuizQuestion> _generateQuestions(List<Lesson> lessons) {
    final random = Random();
    final questions = <QuizQuestion>[];
    final shuffledLessons = List<Lesson>.from(lessons)..shuffle(random);
    
    // En fazla 10 soru
    final questionCount = min(10, shuffledLessons.length);
    
    for (int i = 0; i < questionCount; i++) {
      final correctLesson = shuffledLessons[i];
      final wrongOptions = shuffledLessons
          .where((l) => l.id != correctLesson.id)
          .toList()
        ..shuffle(random);
      
      final options = [
        correctLesson.turkish,
        ...wrongOptions.take(3).map((l) => l.turkish),
      ]..shuffle(random);
      
      questions.add(QuizQuestion(
        english: correctLesson.english,
        correctAnswer: correctLesson.turkish,
        options: options,
        example: correctLesson.example,
      ));
    }
    
    return questions;
  }

  void _checkAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
      _isCorrect = answer == _questions[_currentQuestionIndex].correctAnswer;
      _showResult = true;
      
      if (_isCorrect) {
        _correctAnswers++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showResult = false;
        _isCorrect = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final progress = context.read<ProgressProvider>();
    final score = (_correctAnswers / _questions.length * 10).round();
    
    // Can harcama (premium değilse)
    if (!progress.isPremium) {
      progress.decreaseLives();
    }
    
    // Puan ekle
    progress.addScore(_correctAnswers * 5);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              score >= 7 ? Icons.celebration : Icons.thumb_up,
              color: score >= 7 ? AppColors.success : AppColors.warning,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(score >= 7 ? 'Harika!' : 'İyi Deneme!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_correctAnswers}/${_questions.length}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Doğru Cevap',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _correctAnswers / _questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                score >= 7 ? AppColors.success : AppColors.warning,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.star, color: AppColors.success),
                      const SizedBox(height: 4),
                      Text(
                        '+${_correctAnswers * 5}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text('Puan', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.favorite, color: AppColors.error),
                      const SizedBox(height: 4),
                      Text(
                        progress.isPremium ? '∞' : '${progress.lives}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text('Can', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Quiz ekranı
            },
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              setState(() {
                _currentQuestionIndex = 0;
                _correctAnswers = 0;
                _selectedAnswer = null;
                _showResult = false;
                _isCorrect = false;
                _questions.shuffle();
              });
            },
            child: const Text('Tekrar Çöz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('$_category Quiz'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme çubuğu
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 4,
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Soru kartı
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'İngilizce kelime:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up),
                                color: AppColors.primary,
                                onPressed: () => TtsService().speak(question.english),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.english,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (question.example != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                question.example!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate().fadeIn().scale(),
                  
                  const SizedBox(height: 32),
                  
                  // Seçenekler
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedAnswer == option;
                    final isCorrectOption = option == question.correctAnswer;
                    
                    Color? backgroundColor;
                    Color? borderColor;
                    
                    if (_showResult) {
                      if (isCorrectOption) {
                        backgroundColor = AppColors.success.withOpacity(0.1);
                        borderColor = AppColors.success;
                      } else if (isSelected && !_isCorrect) {
                        backgroundColor = AppColors.error.withOpacity(0.1);
                        borderColor = AppColors.error;
                      }
                    } else if (isSelected) {
                      backgroundColor = AppColors.primary.withOpacity(0.1);
                      borderColor = AppColors.primary;
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showResult ? null : () => _checkAnswer(option),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: backgroundColor ?? Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor ?? Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: borderColor?.withOpacity(0.2) ?? Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index), // A, B, C, D
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: borderColor ?? Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (_showResult && isCorrectOption)
                                  const Icon(Icons.check_circle, color: AppColors.success),
                                if (_showResult && isSelected && !_isCorrect)
                                  const Icon(Icons.cancel, color: AppColors.error),
                              ],
                            ),
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: index * 100))
                        .fadeIn()
                        .slideX(begin: -0.2, end: 0),
                    );
                  }).toList(),
                  
                  if (_showResult) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentQuestionIndex < _questions.length - 1
                            ? 'Sonraki Soru'
                            : 'Sonuçları Gör',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
