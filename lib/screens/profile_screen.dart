import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/progress_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, progress),
            tooltip: 'Profili Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, authProvider),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Misafir uyarı banner'ı
            if (authProvider.isGuest)
              _buildGuestBanner(context, authProvider),
            if (authProvider.isGuest) const SizedBox(height: 16),
            _buildProfileCard(context, authProvider, progress),
            const SizedBox(height: 24),
            _buildStatsGrid(progress),
            const SizedBox(height: 24),
            _buildProgressBar(progress),
            const SizedBox(height: 24),
            _buildAchievementsSection(progress),
            const SizedBox(height: 24),
            _buildLastActivity(progress),
            const SizedBox(height: 24),
            _buildPremiumCard(context, authProvider),
            const SizedBox(height: 24),
            _buildActionButtons(context, progress),
            const SizedBox(height: 80), // Telefonun geri tuşu için ekstra boşluk
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthProvider authProvider, ProgressProvider progress) {
    final userProfile = authProvider.userProfile;
    final userName = progress.fullName ?? userProfile?.fullName ?? 'Kullanıcı';
    final userEmail = userProfile?.email ?? '';
    final isPremium = userProfile?.isActivePremium ?? false;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isPremium ? AppColors.premium.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Avatar Section
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          isPremium ? AppColors.premium : AppColors.primary,
                          isPremium ? const Color(0xFFFFD700) : AppColors.primary.withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isPremium ? AppColors.premium : AppColors.primary).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImagePath != null
                          ? FileImage(File(_profileImagePath!)) as ImageProvider
                          : null,
                      child: _profileImagePath == null
                          ? Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: isPremium ? AppColors.premium : AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  
                  // Fotoğraf butonu
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showImagePickerDialog(context, progress),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPremium ? AppColors.premium : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ).animate().scale(delay: 300.ms).then().shimmer(duration: 2000.ms),
                    ),
                  ),
                  
                  // Premium rozet
                  if (isPremium)
                    Positioned(
                      top: -5,
                      left: -5,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.premium, Color(0xFFFFD700)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 22,
                        ),
                      ).animate()
                        .scale(duration: 400.ms)
                        .then()
                        .shimmer(duration: 2000.ms),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.premium, Color(0xFFFFD700)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ).animate().shimmer(duration: 2000.ms),
                        ],
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3, end: 0),
                    
                    if (userEmail.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              userEmail,
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3, end: 0),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Quick Stats
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickStat(
                          Icons.local_fire_department,
                          '${progress.streak}',
                          AppColors.warning,
                        ),
                        _buildQuickStat(
                          Icons.star,
                          '${progress.totalScore}',
                          AppColors.success,
                        ),
                        _buildQuickStat(
                          Icons.favorite,
                          '${progress.lives}',
                          AppColors.error,
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildQuickStat(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context, AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.8),
            AppColors.warning,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Misafir Modu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Verileriniz sadece bu cihazda saklanıyor. Bulut yedeği yok. Hesap oluşturarak verilerinizi güvende tutun!',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text(
                'Hesap Oluştur',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatsGrid(ProgressProvider progress) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatItem('🔥 Seri', '${progress.streak} Gün', AppColors.warning, 0),
        _buildStatItem('⭐ Puan', '${progress.totalScore}', AppColors.success, 100),
        _buildStatItem('❤️ Can', '${progress.lives}/5', AppColors.error, 200),
        _buildStatItem('✅ Tamamlanan', '${progress.totalCompletedLessons}', AppColors.primary, 300),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, Color color, int delay) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ).animate(delay: Duration(milliseconds: delay))
              .fadeIn()
              .scale(begin: const Offset(0.5, 0.5))
              .then()
              .shimmer(duration: 1500.ms),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: delay))
      .fadeIn()
      .slideY(begin: 0.3, end: 0);
  }

  Widget _buildProgressBar(ProgressProvider progress) {
    final currentLevel = (progress.totalScore / 100).floor() + 1;
    final nextLevelScore = currentLevel * 100;
    final progressValue = (progress.totalScore % 100) / 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Seviye $currentLevel', style: AppTextStyles.heading3),
                Text('${progress.totalScore % 100}/100', style: AppTextStyles.body2),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              'Sonraki seviyeye ${nextLevelScore - progress.totalScore} puan kaldı',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildAchievementsSection(ProgressProvider progress) {
    final achievements = <Map<String, dynamic>>[];
    
    if (progress.streak >= 7) {
      achievements.add({'icon': '🔥', 'title': '7 Gün Seri', 'color': Colors.orange});
    }
    if (progress.totalScore >= 100) {
      achievements.add({'icon': '⭐', 'title': '100 Puan', 'color': Colors.amber});
    }
    if (progress.totalCompletedLessons >= 5) {
      achievements.add({'icon': '🎓', 'title': '5 Ders', 'color': Colors.blue});
    }
    if (progress.totalCompletedLessons >= 10) {
      achievements.add({'icon': '🏆', 'title': '10 Ders', 'color': AppColors.premium});
    }
    if (progress.totalScore >= 500) {
      achievements.add({'icon': '💎', 'title': '500 Puan', 'color': const Color(0xFF00BCD4)});
    }
    if (progress.streak >= 30) {
      achievements.add({'icon': '⚡', 'title': '30 Gün Seri', 'color': const Color(0xFFFF5722)});
    }

    if (achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Başarılar', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements.asMap().entries.map((entry) {
            final index = entry.key;
            final achievement = entry.value;
            return Chip(
              avatar: Text(achievement['icon'] as String, style: const TextStyle(fontSize: 20)),
              label: Text(achievement['title'] as String),
              backgroundColor: (achievement['color'] as Color).withOpacity(0.2),
            ).animate(delay: Duration(milliseconds: 500 + (index * 100)))
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildLastActivity(ProgressProvider progress) {
    if (progress.lastStudyDate == null) return const SizedBox.shrink();
    
    final difference = DateTime.now().difference(progress.lastStudyDate!);
    
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} saat önce';
    } else {
      timeAgo = '${difference.inMinutes} dakika önce';
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.access_time, color: AppColors.primary),
        title: const Text('Son Aktivite'),
        subtitle: Text(timeAgo),
      ),
    ).animate().fadeIn(delay: 550.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildPremiumCard(BuildContext context, AuthProvider authProvider) {
    final isPremium = authProvider.userProfile?.isActivePremium ?? false;
    
    if (isPremium) {
      return Card(
        color: AppColors.premium.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.premium, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Üye',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.premium),
                    ),
                    Text('Sınırsız can ve tüm özellikler aktif!', style: AppTextStyles.body2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().shimmer();
    }

    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          _showPremiumDialog(context, authProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.premium, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Premium'a Geç!", style: AppTextStyles.heading3),
                    Text('Sınırsız can ve özel içerikler', style: AppTextStyles.body2),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    ).animate().shimmer(duration: 2000.ms);
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showPremiumDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Üyelik'),
        content: const Text(
          'Premium üyelikle:\n\n'
          '• Sınırsız can\n'
          '• Tüm seviyelere erişim\n'
          '• Reklamsız deneyim\n'
          '• Özel rozetler\n'
          '• İleri düzey içerikler',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('💎 Premium özelliği yakında aktif olacaktır!'),
                  backgroundColor: AppColors.premium,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.premium,
            ),
            child: const Text('Satın Al'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProgressProvider progress) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isPremium = authProvider.userProfile?.isActivePremium ?? false;
    
    return Column(
      children: [
        Card(
          child: SwitchListTile(
            title: const Text('Karanlık Mod'),
            subtitle: const Text('Göz dostu tema'),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _refreshData(context),
          icon: const Icon(Icons.refresh),
          label: const Text('Kelimeleri Yenile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        if (!isPremium)
          ElevatedButton.icon(
            onPressed: () => _showPremiumDialog(context, authProvider),
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Premium Satın Al'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.premium,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, ProgressProvider progress) {
    final nameController = TextEditingController(text: progress.fullName ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profili Düzenle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Ad Soyad',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await progress.updateFullName(nameController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil güncellendi! ✅')),
                  );
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Verileri yenile
      await DataService().forceRefresh();

      if (context.mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Kelimeler güncellendi!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.pop(context); // Dialog'u kapat
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                source == ImageSource.camera
                    ? '📷 Fotoğraf çekildi!'
                    : '🖼️ Fotoğraf seçildi!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImagePickerDialog(BuildContext context, ProgressProvider progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.photo_camera, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Profil Fotoğrafı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profil fotoğrafını nasıl yüklemek istersin?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceButton(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  color: const Color(0xFF6C63FF),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildImageSourceButton(
                  context,
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  color: const Color(0xFF4A90E2),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 100.ms).shimmer(duration: 1500.ms);
  }
}
