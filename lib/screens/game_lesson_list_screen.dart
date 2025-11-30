import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../providers/progress_provider.dart';
import '../utils/constants.dart';
import 'games/multiple_choice_game.dart';
import 'games/word_matching_game.dart';

class GameLessonListScreen extends StatelessWidget {
  final String level;
  final String gameType; // 'multiple_choice', 'word_matching', 'fill_blank'

  const GameLessonListScreen({
    super.key,
    required this.level,
    required this.gameType,
  });

  String get gameTitle {
    switch (gameType) {
      case 'multiple_choice':
        return 'Çoktan Seçmeli';
      case 'word_matching':
        return 'Kelime Eşleştirme';
      default:
        return 'Oyun';
    }
  }

  IconData get gameIcon {
    switch (gameType) {
      case 'multiple_choice':
        return Icons.quiz;
      case 'word_matching':
        return Icons.swap_horiz;
      default:
        return Icons.games;
    }
  }

  Color get gameColor {
    switch (gameType) {
      case 'multiple_choice':
        return AppColors.primary;
      case 'word_matching':
        return AppColors.levelA2;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final lessonGroupCount = dataService.getLessonGroupCount(level, gameType: gameType);

    return Scaffold(
      appBar: AppBar(
        title: Text('$level - $gameTitle'),
        backgroundColor: gameColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProgressProvider>(
        builder: (context, progress, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.padding),
            itemCount: lessonGroupCount,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final lessonKey = '${level}_${index}_$gameType';
              final lessonProgress = progress.progress.lessonProgress[lessonKey];
              final isUnlocked = lessonProgress?.isUnlocked ?? (index == 0);
              final isCompleted = lessonProgress?.isCompleted ?? false;
              final bestScore = lessonProgress?.bestScore ?? 0;

              return _buildLessonCard(
                context,
                index,
                isUnlocked,
                isCompleted,
                bestScore,
                progress,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    int index,
    bool isUnlocked,
    bool isCompleted,
    int bestScore,
    ProgressProvider progress,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isUnlocked ? 4 : 2,
      child: InkWell(
        onTap: isUnlocked
            ? () {
                if (progress.lives <= 0 && !progress.isPremium) {
                  _showNoLivesDialog(context);
                  return;
                }

                _navigateToGame(context, index);
              }
            : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Ders numarası
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked ? gameColor : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 30)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Ders bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ders ${index + 1}',
                      style: AppTextStyles.heading3.copyWith(
                        color: isUnlocked ? AppColors.textPrimary : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked 
                        ? (gameType == 'word_matching' ? '6 Kelime' : '10 Kelime')
                        : 'Kilitli - Önceki dersi tamamla',
                      style: AppTextStyles.body2.copyWith(
                        color: isUnlocked ? AppColors.textSecondary : Colors.grey[600],
                      ),
                    ),
                    if (isCompleted && bestScore > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: gameColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gameType == 'word_matching' 
                              ? 'En İyi: $bestScore/60'
                              : 'En İyi: $bestScore/10',
                            style: TextStyle(
                              color: gameColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Durum ikonu
              Icon(
                isUnlocked
                    ? (isCompleted ? Icons.check_circle : Icons.play_circle_outline)
                    : Icons.lock,
                color: isUnlocked
                    ? (isCompleted ? AppColors.success : gameColor)
                    : Colors.grey[600],
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, int lessonGroupIndex) {
    Widget gameScreen;

    switch (gameType) {
      case 'multiple_choice':
        gameScreen = MultipleChoiceGame(
          level: level,
          lessonGroupIndex: lessonGroupIndex,
        );
        break;
      case 'word_matching':
        gameScreen = WordMatchingGame(
          level: level,
          lessonGroupIndex: lessonGroupIndex,
        );
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => gameScreen),
    );
  }

  void _showNoLivesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Canın Bitti!'),
        content: const Text(
          'Oyun oynamak için can gerekiyor. Canlar saatte 1 yenilenir veya Premium al!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
