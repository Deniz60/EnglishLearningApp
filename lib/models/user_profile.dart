import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 2)
class UserProfile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  String? fullName;

  @HiveField(3)
  String? avatarUrl;

  @HiveField(4)
  bool isPremium;

  @HiveField(5)
  DateTime? premiumUntil;

  @HiveField(6)
  int totalPoints;

  @HiveField(7)
  int currentStreak;

  @HiveField(8)
  int longestStreak;

  @HiveField(9)
  int dailyGoal;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.isPremium = false,
    this.premiumUntil,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.dailyGoal = 10,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Supabase'den gelen JSON'u model'e çevir
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      premiumUntil: json['premium_until'] != null
          ? DateTime.parse(json['premium_until'] as String)
          : null,
      totalPoints: json['total_points'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      dailyGoal: json['daily_goal'] as int? ?? 10,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // Model'i JSON'a çevir (Supabase'e göndermek için)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_premium': isPremium,
      'premium_until': premiumUntil?.toIso8601String(),
      'total_points': totalPoints,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'daily_goal': dailyGoal,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Copy with method (immutable updates için)
  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    bool? isPremium,
    DateTime? premiumUntil,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    int? dailyGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Premium durumunu kontrol et
  bool get isActivePremium {
    if (!isPremium) return false;
    if (premiumUntil == null) return true; // Lifetime premium
    return DateTime.now().isBefore(premiumUntil!);
  }

  // Günlük hedefe ulaşıldı mı?
  bool isDailyGoalReached(int todayPoints) {
    return todayPoints >= dailyGoal;
  }
}
