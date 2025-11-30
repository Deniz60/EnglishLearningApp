import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson.dart';
import '../services/data_service.dart';
import '../services/tts_service.dart';
import '../providers/favorites_provider.dart';
import '../utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Lesson> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final allLessons = DataService().getAllLessons();
    final lowerQuery = query.toLowerCase();

    _searchResults = allLessons.where((lesson) {
      return lesson.english.toLowerCase().contains(lowerQuery) ||
          lesson.turkish.toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Ara'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _performSearch,
        decoration: InputDecoration(
          hintText: 'İngilizce veya Türkçe kelime ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.background,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Kelime aramak için yukarıdaki\narama çubuğunu kullanın',
              textAlign: TextAlign.center,
              style: AppTextStyles.body2,
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir kelime deneyin',
              style: AppTextStyles.body2,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padding),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final lesson = _searchResults[index];
        return _buildResultCard(lesson);
      },
    );
  }

  Widget _buildResultCard(Lesson lesson) {
    final levelColor = AppConstants.levelColors[lesson.level] ?? AppColors.primary;

    return Consumer<FavoritesProvider>(
      builder: (context, favorites, _) {
        final isFavorite = favorites.isFavorite(lesson.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => TtsService().speak(lesson.english),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.error : Colors.grey,
                    ),
                    onPressed: () => _showCategoryDialog(context, favorites, lesson.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showCategoryDialog(BuildContext context, FavoritesProvider favorites, String lessonId) {
    final isFavorite = favorites.isFavorite(lessonId);
    
    if (isFavorite) {
      // Zaten favoride, çıkar
      favorites.toggleFavorite(lessonId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Favorilerden çıkarıldı'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      // Favorilere ekle, kategori seç
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📚 Kategoriye Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: favorites.categories
                .where((c) => c != 'Tümü')
                .map((category) => ListTile(
                      leading: Icon(
                        _getCategoryIcon(category),
                        color: AppColors.primary,
                      ),
                      title: Text(category),
                      onTap: () async {
                        await favorites.toggleFavorite(lessonId, category: category);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ "$category" kategorisine eklendi!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ))
                .toList(),
          ),
        ),
      );
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Zor Kelimeler':
        return Icons.psychology;
      case 'Çalışılacaklar':
        return Icons.schedule;
      case 'Önemli':
        return Icons.star;
      default:
        return Icons.bookmark;
    }
  }
}
