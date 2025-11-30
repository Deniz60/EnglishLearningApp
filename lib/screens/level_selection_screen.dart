import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/data_service.dart';
import '../utils/constants.dart';
import 'game_lesson_list_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  final String level;

  const LevelSelectionScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final lessons = DataService().getLessonsByLevel(level);
    final color = AppConstants.levelColors[level] ?? AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('$level - ${AppConstants.levelNames[level]}'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(lessons.length, color),
            const SizedBox(height: 24),
            Text('Oyunlar', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              'Çoktan Seçmeli',
              'Doğru cevabı seç',
              Icons.quiz,
              AppColors.levelA1,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameLessonListScreen(
                    level: level,
                    gameType: 'multiple_choice',
                  ),
                ),
              ),
              0,
            ),
            _buildGameCard(
              context,
              'Kelime Eşleştirme',
              'İngilizce-Türkçe eşleştir',
              Icons.grid_on,
              AppColors.levelA2,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameLessonListScreen(
                    level: level,
                    gameType: 'word_matching',
                  ),
                ),
              ),
              1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(int totalLessons, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  level,
                  style: AppTextStyles.heading2.copyWith(color: color),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Toplam Kelime', style: AppTextStyles.body2),
                  Text('$totalLessons', style: AppTextStyles.heading2.copyWith(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildGameCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    int index,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading3),
                    Text(subtitle, style: AppTextStyles.body2),
                  ],
                ),
              ),
              Icon(Icons.play_arrow, color: color, size: 32),
            ],
          ),
        ),
      ),
    ).animate().slideX(begin: 0.2, delay: (100 * index).ms);
  }
}
