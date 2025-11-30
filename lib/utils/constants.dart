import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFFFF6584);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  
  // Light mode colors
  static const background = Color(0xFFF5F7FA);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF636E72);
  
  // Dark mode colors
  static const darkBackground = Color(0xFF1A1A2E);
  static const darkCardBackground = Color(0xFF16213E);
  static const darkTextPrimary = Color(0xFFE4E4E4);
  static const darkTextSecondary = Color(0xFFB4B4B4);
  
  // Level colors
  static const levelA1 = Color(0xFF4ECDC4);
  static const levelA2 = Color(0xFF45B7D1);
  static const levelB1 = Color(0xFF5F27CD);
  static const levelB2 = Color(0xFFFF6348);
  
  // Game colors
  static const correct = Color(0xFF2ECC71);
  static const incorrect = Color(0xFFE74C3C);
  static const premium = Color(0xFFFFD700);
}

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppConstants {
  static const double borderRadius = 16.0;
  static const double cardElevation = 4.0;
  static const double padding = 16.0;
  static const double paddingLarge = 24.0;
  
  static const int maxLives = 5;
  static const int premiumLives = 50;
  static const int lifeRegenerationHours = 1;
  static const int wordsPerLesson = 10;
  static const int passScore = 7; // 7/10 doğru yapınca geç
  
  static const Map<String, String> levelNames = {
    'A1': 'Başlangıç',
    'A2': 'Temel',
    'B1': 'Orta',
    'B2': 'İleri',
  };
  
  static const Map<String, Color> levelColors = {
    'A1': AppColors.levelA1,
    'A2': AppColors.levelA2,
    'B1': AppColors.levelB1,
    'B2': AppColors.levelB2,
  };
}
