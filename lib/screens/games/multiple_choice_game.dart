import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/lesson.dart';
import '../../services/data_service.dart';
import '../../services/database_service.dart';
import '../../services/tts_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../providers/progress_provider.dart';
import '../../utils/constants.dart';

class MultipleChoiceGame extends StatefulWidget {
  final String level;
  final int lessonGroupIndex;

  const MultipleChoiceGame({super.key, required this.level, required this.lessonGroupIndex});

  @override
  State<MultipleChoiceGame> createState() => _MultipleChoiceGameState();
}

class _MultipleChoiceGameState extends State<MultipleChoiceGame> {
  late List<Lesson> _questions;
  int _currentQuestion = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _answered = false;
  final Map<int, List<String>> _questionOptions = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsService _ttsService = TtsService();
  final SpacedRepetitionService _srService = SpacedRepetitionService();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _loadQuestions() {
    _questions = DataService().getLessonGroup(
      widget.level, 
      widget.lessonGroupIndex,
      gameType: 'multiple_choice',
    );
    _questionOptions.clear();
    
    // Generate options for all questions at once
    for (int i = 0; i < _questions.length; i++) {
      final options = _generateOptions(_questions[i]);
      print('Question $i: ${_questions[i].english} - Options count: ${options.length}');
      print('Options: $options');
      _questionOptions[i] = options;
    }
    
    setState(() {});
  }

  List<String> _generateOptions(Lesson correct) {
    final allLessons = DataService().getLessonsByLevel(widget.level);
    
    print('All lessons count: ${allLessons.length}, correct id: ${correct.id}');
    
    // Diğer yanlış cevapları ekle (aynı seviyeden random, doğru cevap hariç)
    final wrongOptions = allLessons
        .where((lesson) => lesson.id != correct.id && lesson.turkish != correct.turkish)
        .map((lesson) => lesson.turkish)
        .toList();
    
    print('Wrong options count: ${wrongOptions.length}');
    
    wrongOptions.shuffle();
    
    // 3 yanlış şık al
    final selectedWrong = wrongOptions.take(3).toList();
    
    print('Selected wrong count: ${selectedWrong.length}');
    
    // Doğru cevap + 3 yanlış cevap
    final options = [correct.turkish, ...selectedWrong];
    
    print('Final options before shuffle: $options');
    
    // Şıkları karıştır
    options.shuffle();
    return options;
  }

  void _selectAnswer(String answer) async {
    if (_answered) return;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });

    final currentLesson = _questions[_currentQuestion];
    final isCorrect = answer == currentLesson.turkish;
    
    if (isCorrect) {
      _score += 10;
      print('✅ DOĞRU CEVAP! Skor: $_score');
      
      // Spaced Repetition: Doğru cevap kalitesi 4-5
      await _srService.recordAnswer(currentLesson.id, 4);
    } else {
      print('❌ YANLIŞ CEVAP! Can azaltılıyor...');
      final progress = context.read<ProgressProvider>();
      print('🎮 Oyun - Önceki can: ${progress.lives}, Premium: ${progress.isPremium}');
      await progress.decreaseLives();
      print('🎮 Oyun - Sonraki can: ${progress.lives}');
      
      // Spaced Repetition: Yanlış cevap kalitesi 1-2
      await _srService.recordAnswer(currentLesson.id, 1);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestion < _questions.length - 1) {
        setState(() {
          _currentQuestion++;
          _selectedAnswer = null;
          _answered = false;
        });
      } else {
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() async {
    final progress = context.read<ProgressProvider>();
    final correctAnswers = (_score / 10).toInt();
    final lessonKey = '${widget.level}_${widget.lessonGroupIndex}_multiple_choice';
    
    // Skoru kaydet ve gerekirse sonraki dersi aç
    await progress.addScore(_score);
    await progress.completeLesson(lessonKey, correctAnswers);
    await progress.updateStreak();
    
    // Quiz sonucunu Supabase'e kaydet
    if (!mounted) return;
    try {
      await DatabaseService().saveQuizResult(
        level: widget.level,
        totalQuestions: _questions.length,
        correctAnswers: correctAnswers,
        pointsEarned: _score,
      );
    } catch (e) {
      print('⚠️ Quiz sonucu kaydetme hatası: $e');
    }
    
    final isPassed = correctAnswers >= AppConstants.passScore;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isPassed ? 'Tebrikler!' : 'Oyun Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPassed ? Icons.emoji_events : Icons.sentiment_satisfied,
              size: 64,
              color: isPassed ? AppColors.premium : AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Puanınız: $_score',
              style: AppTextStyles.heading2,
            ),
            Text(
              '${_questions.length} sorudan $correctAnswers doğru',
              style: AppTextStyles.body2,
            ),
            if (isPassed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🎉 Dersi geçtin! Sonraki ders açıldı!',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'Geçmek için en az ${AppConstants.passScore} doğru yapmalısın',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Menü'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentQuestion = 0;
                _score = 0;
                _selectedAnswer = null;
                _answered = false;
                _questionOptions.clear();
              });
              _loadQuestions();
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentLesson = _questions[_currentQuestion];
    final options = _questionOptions[_currentQuestion]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çoktan Seçmeli'),
        backgroundColor: AppColors.levelA1,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Puan: $_score',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(
                value: (_currentQuestion + 1) / _questions.length,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.levelA1),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    children: [
                      Text(
                        'Soru ${_currentQuestion + 1}/${_questions.length}',
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentLesson.english,
                                      style: AppTextStyles.heading1.copyWith(
                                        fontSize: 36,
                                        color: AppColors.primary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.volume_up, size: 32),
                                    color: AppColors.primary,
                                    onPressed: () => _ttsService.speak(currentLesson.english),
                                    tooltip: 'Dinle',
                                  ),
                                ],
                              ),
                              if (currentLesson.example != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  currentLesson.example!,
                                  style: AppTextStyles.body2.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate().scale(duration: 400.ms),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView.builder(
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = _selectedAnswer == option;
                            final isCorrect = option == currentLesson.turkish;
                            
                            Color? cardColor;
                            if (_answered) {
                              if (isCorrect) {
                                cardColor = AppColors.correct.withOpacity(0.3);
                              } else if (isSelected) {
                                cardColor = AppColors.incorrect.withOpacity(0.3);
                              }
                            }

                            return Card(
                              color: cardColor,
                              elevation: isSelected ? 8 : 2,
                              child: InkWell(
                                onTap: () => _selectAnswer(option),
                                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey[300],
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + index),
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: AppTextStyles.heading3,
                                        ),
                                      ),
                                      if (_answered && isCorrect)
                                        const Icon(Icons.check_circle, color: AppColors.correct, size: 32),
                                      if (_answered && isSelected && !isCorrect)
                                        const Icon(Icons.cancel, color: AppColors.incorrect, size: 32),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().slideX(begin: 0.2, delay: (100 * index).ms);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
