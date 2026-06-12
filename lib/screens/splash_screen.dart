import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/data_service.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    // Veriyi yükle (kullanıcı giriş yapmış olsun ya da olmasın)
    final dataService = context.read<DataService>();
    await dataService.ensureInitialized();
    
    if (!mounted) return;
    
    // Kullanıcı giriş yapmışsa progress ve favorileri YENİDEN yükle (Supabase'den)
    if (authProvider.isAuthenticated) {
      print('🔄 SplashScreen: Kullanıcı authenticated, progress yeniden yükleniyor...');
      final progressProvider = context.read<ProgressProvider>();
      await progressProvider.loadProgress();
      
      if (!mounted) return;

      final favoritesProvider = context.read<FavoritesProvider>();
      await favoritesProvider.reinitialize();
      
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 100,
              color: Colors.white,
            ).animate().scale(duration: 600.ms).then().shimmer(),
            const SizedBox(height: 24),
            Text(
              'English Learning',
              style: AppTextStyles.heading1.copyWith(color: Colors.white),
            ).animate().fadeIn(duration: 800.ms),
            const SizedBox(height: 8),
            Text(
              'Öğrenme Yolculuğunuz Başlıyor!',
              style: AppTextStyles.body1.copyWith(color: Colors.white70),
            ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}
