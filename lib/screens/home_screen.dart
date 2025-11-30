import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/progress_provider.dart';
import '../utils/constants.dart';
import '../widgets/lives_display.dart';
import 'level_selection_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'premium_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(context),
                    const SizedBox(height: 12),
                    _buildStatsSection(context),
                    const SizedBox(height: 16),
                    _buildLevelSection(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Row(
        children: [
          // Sol ikonlar
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
          ),
          const Spacer(),
          const LivesDisplay(),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_fire_department, size: 28, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Text('${progress.streak} Gün Serisi 🔥', style: AppTextStyles.heading3),
          ],
        ),
      ),
    ).animate().slideX(begin: -0.2, duration: 400.ms);
  }

  Widget _buildStatsSection(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İstatistiklerim', style: AppTextStyles.heading3),
        const SizedBox(height: 10),
        Row(
          children: [
        Expanded(
          child: _buildStatCard('Puan', '${progress.totalScore}', Icons.star, AppColors.warning)
              .animate().scale(delay: 100.ms),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('Ders', '${progress.totalCompletedLessons}', Icons.check_circle, AppColors.success)
              .animate().scale(delay: 200.ms),
        ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.heading3.copyWith(color: color)),
            Text(title, style: AppTextStyles.body2.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seviyeler', style: AppTextStyles.heading3),
        const SizedBox(height: 10),
        _buildLevelCard(context, 'A1', 'Başlangıç', AppColors.levelA1, 0),
        _buildLevelCard(context, 'A2', 'Temel', AppColors.levelA2, 1),
        _buildLevelCard(context, 'B1', 'Orta', AppColors.levelB1, 2),
        _buildLevelCard(context, 'B2', 'İleri', AppColors.levelB2, 3),
      ],
    );
  }

  Widget _buildLevelCard(BuildContext context, String level, String name, Color color, int index) {
    final progress = context.watch<ProgressProvider>();
    final completed = progress.progress.getCompletedLessonsCount(level);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (progress.canPlay()) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LevelSelectionScreen(level: level)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Canınız bitti! Bekleyin veya Premium alın.')),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(level, style: AppTextStyles.heading3.copyWith(color: color)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('$completed ders', style: AppTextStyles.body2.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    ).animate().slideX(begin: 0.2, delay: (80 * index).ms);
  }
}
