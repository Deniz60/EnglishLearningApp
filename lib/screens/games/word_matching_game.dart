import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/lesson.dart';
import '../../services/data_service.dart';
import '../../providers/progress_provider.dart';
import '../../utils/constants.dart';

class WordMatchingGame extends StatefulWidget {
  final String level;
  final int lessonGroupIndex;

  const WordMatchingGame({super.key, required this.level, required this.lessonGroupIndex});

  @override
  State<WordMatchingGame> createState() => _WordMatchingGameState();
}

class _WordMatchingGameState extends State<WordMatchingGame> {
  late List<Lesson> _lessons;
  late List<String> _englishWords;
  late List<String> _turkishWords;
  Map<int, int> _matches = {};
  int? _selectedEnglish;
  int? _selectedTurkish;
  int _score = 0;
  bool _gameCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadGame() {
    _lessons = DataService().getLessonGroup(
      widget.level,
      widget.lessonGroupIndex,
      gameType: 'word_matching',
    );
    _englishWords = _lessons.map((l) => l.english).toList();
    _turkishWords = _lessons.map((l) => l.turkish).toList()..shuffle();
    setState(() {});
  }

  void _selectCard(bool isEnglish, int index) {
    if (_gameCompleted) return;
    if (isEnglish && _matches.containsKey(index)) return;
    if (!isEnglish && _matches.containsValue(index)) return;

    setState(() {
      if (isEnglish) {
        _selectedEnglish = _selectedEnglish == index ? null : index;
      } else {
        _selectedTurkish = _selectedTurkish == index ? null : index;
      }
    });

    if (_selectedEnglish != null && _selectedTurkish != null) {
      _checkMatch();
    }
  }

  void _checkMatch() async {
    final turkishWord = _turkishWords[_selectedTurkish!];
    
    final correctTurkish = _lessons[_selectedEnglish!].turkish;
    
    if (turkishWord == correctTurkish) {
      setState(() {
        _matches[_selectedEnglish!] = _selectedTurkish!;
        _score += 10;
        _selectedEnglish = null;
        _selectedTurkish = null;
      });
      
      // 6/6 eşleşme kontrolü
      if (_matches.length == 6) {
        Future.delayed(const Duration(seconds: 1), () {
          _showResultDialog();
        });
      }
    } else {
      final progress = context.read<ProgressProvider>();
      await progress.decreaseLives();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _selectedEnglish = null;
          _selectedTurkish = null;
        });
      });
    }
  }

  void _showResultDialog() async {
    setState(() {
      _gameCompleted = true;
    });

    final progress = context.read<ProgressProvider>();
    
    // Önce puanı ekle, sonra dersi tamamla
    await progress.addScore(_score);
    
    // Dersi tamamla (60 puan = 6 kelime x 10 puan)
    final lessonKey = '${widget.level}_${widget.lessonGroupIndex}_word_matching';
    await progress.completeLesson(lessonKey, _score);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tebrikler!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: AppColors.premium,
            ),
            const SizedBox(height: 16),
            Text(
              'Puanınız: $_score',
              style: AppTextStyles.heading2,
            ),
            Text(
              '6 eşleştirmeyi doğru yaptınız! 🎉',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
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
                _matches.clear();
                _selectedEnglish = null;
                _selectedTurkish = null;
                _score = 0;
                _gameCompleted = false;
              });
              _loadGame();
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lessons.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Eşleştirme'),
        backgroundColor: AppColors.levelA2,
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
          Padding(
            padding: const EdgeInsets.all(AppConstants.padding),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _matches.length / _lessons.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.levelA2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Eşleşen: ${_matches.length}/${_lessons.length}',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildWordList(true),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildWordList(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(bool isEnglish) {
    final words = isEnglish ? _englishWords : _turkishWords;
    
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final isMatched = isEnglish
            ? _matches.containsKey(index)
            : _matches.containsValue(index);
        final isSelected = isEnglish
            ? _selectedEnglish == index
            : _selectedTurkish == index;

        if (isMatched) {
          return Card(
            color: AppColors.correct.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.correct),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      words[index],
                      style: AppTextStyles.body1.copyWith(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(duration: 300.ms);
        }

        return Card(
          elevation: isSelected ? 8 : 2,
          color: isSelected ? AppColors.primary.withOpacity(0.3) : null,
          child: InkWell(
            onTap: () => _selectCard(isEnglish, index),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                words[index],
                style: AppTextStyles.body1.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ).animate().slideX(begin: isEnglish ? -0.2 : 0.2, delay: (100 * index).ms);
      },
    );
  }
}
