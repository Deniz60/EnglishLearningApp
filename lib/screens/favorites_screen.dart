import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/favorites_provider.dart';
import '../services/data_service.dart';
import '../services/tts_service.dart';
import '../utils/constants.dart';
import '../models/lesson.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedCategory = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    
    // Initialize edilene kadar loading göster
    if (!favorites.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Favorilerim'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Quiz modu butonu
          if (favorites.count > 0)
            IconButton(
              icon: const Icon(Icons.quiz),
              tooltip: 'Favorilerle Quiz',
              onPressed: () => _startFavoritesQuiz(context, favorites),
            ),
          // Temizle butonu
          if (favorites.count > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tümünü Temizle',
              onPressed: () => _confirmClearAll(context, favorites),
            ),
        ],
      ),
      body: favorites.count == 0
          ? _buildEmptyState()
          : Column(
              children: [
                _buildCategoryFilter(favorites),
                Expanded(
                  child: _buildFavoritesList(favorites),
                ),
              ],
            ),
    );
  }
  
  Widget _buildCategoryFilter(FavoritesProvider favorites) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: favorites.categories.length,
        itemBuilder: (context, index) {
          final category = favorites.categories[index];
          final isSelected = _selectedCategory == category;
          final count = category == 'Tümü'
              ? favorites.count
              : favorites.getFavoritesByCategory(category).length;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$category ($count)'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFavoritesList(FavoritesProvider favorites) {
    final filteredFavorites = favorites.getFavoritesByCategory(_selectedCategory);
    
    if (filteredFavorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Bu kategoride favori yok',
              style: AppTextStyles.heading3.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    final favoriteLessons = _getFavoriteLessons(filteredFavorites);

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padding),
      itemCount: favoriteLessons.length,
      itemBuilder: (context, index) {
        return _buildFavoriteCard(
          context,
          favoriteLessons[index],
          favorites,
        ).animate(delay: Duration(milliseconds: index * 50))
          .fadeIn()
          .slideX(begin: -0.2, end: 0);
      },
    );
  }

  List<Lesson> _getFavoriteLessons(Set<String> favoriteIds) {
    final allLessons = DataService().getAllLessons();
    return allLessons.where((lesson) => favoriteIds.contains(lesson.id)).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz favori yok',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'Kelime kartlarını favorilere ekleyerek\nburada görebilirsiniz',
            textAlign: TextAlign.center,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Lesson lesson, FavoritesProvider favorites) {
    final levelColor = AppConstants.levelColors[lesson.level] ?? AppColors.primary;
    final category = favorites.getCategory(lesson.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.level,
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.english,
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson.turkish,
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  color: AppColors.primary,
                  onPressed: () => TtsService().speak(lesson.english),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: AppColors.error),
                  onPressed: () => favorites.removeFavorite(lesson.id),
                ),
              ],
            ),
            // Kategori seçici
            if (category != null || favorites.categories.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.label, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: favorites.categories
                          .where((c) => c != 'Tümü')
                          .map((c) => GestureDetector(
                                onTap: () => favorites.setCategory(lesson.id, c),
                                child: Chip(
                                  label: Text(c, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: category == c
                                      ? AppColors.primary.withOpacity(0.2)
                                      : Colors.grey[200],
                                  padding: const EdgeInsets.all(2),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _confirmClearAll(BuildContext context, FavoritesProvider favorites) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Temizle'),
        content: const Text('Tüm favorileri silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await favorites.clearAll();
    }
  }
  
  Future<void> _startFavoritesQuiz(BuildContext context, FavoritesProvider favorites) async {
    final filteredFavorites = favorites.getFavoritesByCategory(_selectedCategory);
    
    if (filteredFavorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kategoride favori kelime yok!')),
      );
      return;
    }
    
    if (filteredFavorites.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz için en az 5 favori kelime gerekli!')),
      );
      return;
    }
    
    // Quiz ekranına git
    final favoriteLessons = _getFavoriteLessons(filteredFavorites);
    
    Navigator.pushNamed(
      context,
      '/favorites-quiz',
      arguments: {
        'lessons': favoriteLessons,
        'category': _selectedCategory,
      },
    );
  }
}
