import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _settingsBoxName = 'notification_settings';
  
  FlutterLocalNotificationsPlugin? _notifications;
  Box? _settingsBox;
  bool _isInitialized = false;
  bool _isAvailable = true;

  bool _dailyReminderEnabled = true;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _streakReminderEnabled = true;
  bool _reviewReminderEnabled = true;
  bool _achievementNotificationsEnabled = true;

  bool get isAvailable => _isAvailable;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  TimeOfDay get dailyReminderTime => _dailyReminderTime;
  bool get streakReminderEnabled => _streakReminderEnabled;
  bool get reviewReminderEnabled => _reviewReminderEnabled;
  bool get achievementNotificationsEnabled => _achievementNotificationsEnabled;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        _isAvailable = false;
        _isInitialized = true;
        return;
      }

      _settingsBox = await Hive.openBox(_settingsBoxName);
      _loadSettingsFromBox();

      _notifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      await _setupNotificationChannels();
      await _requestNotificationPermissions();
      
      _isAvailable = true;
      _isInitialized = true;
      debugPrint('NotificationService initialized');

      if (_dailyReminderEnabled) {
        await scheduleDailyReminder();
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      _isAvailable = false;
      _isInitialized = true;
    }
  }

  void _loadSettingsFromBox() {
    if (_settingsBox == null) return;
    _dailyReminderEnabled = _settingsBox!.get('dailyReminderEnabled', defaultValue: true);
    _streakReminderEnabled = _settingsBox!.get('streakReminderEnabled', defaultValue: true);
    _reviewReminderEnabled = _settingsBox!.get('reviewReminderEnabled', defaultValue: true);
    _achievementNotificationsEnabled = _settingsBox!.get('achievementEnabled', defaultValue: true);
    
    final hour = _settingsBox!.get('dailyReminderHour', defaultValue: 20);
    final minute = _settingsBox!.get('dailyReminderMinute', defaultValue: 0);
    _dailyReminderTime = TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _saveSettingsToBox() async {
    if (_settingsBox == null) return;
    await _settingsBox!.put('dailyReminderEnabled', _dailyReminderEnabled);
    await _settingsBox!.put('streakReminderEnabled', _streakReminderEnabled);
    await _settingsBox!.put('reviewReminderEnabled', _reviewReminderEnabled);
    await _settingsBox!.put('achievementEnabled', _achievementNotificationsEnabled);
    await _settingsBox!.put('dailyReminderHour', _dailyReminderTime.hour);
    await _settingsBox!.put('dailyReminderMinute', _dailyReminderTime.minute);
  }

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _setupNotificationChannels() async {
    if (_notifications == null) return;
    
    final androidPlugin = _notifications!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'daily_reminder',
        'Gunluk Hatirlatma',
        description: 'Gunluk calisma hatirlatmalari',
        importance: Importance.high,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'streak_reminder',
        'Seri Uyarisi',
        description: 'Gunluk seri kaybetme uyarilari',
        importance: Importance.high,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'review_reminder',
        'Tekrar Hatirlatma',
        description: 'Kelime tekrari hatirlatmalari',
        importance: Importance.defaultImportance,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'achievement',
        'Basarilar',
        description: 'Rozet ve basari bildirimleri',
        importance: Importance.defaultImportance,
      ),
    );
  }

  Future<void> _requestNotificationPermissions() async {
    if (_notifications == null) return;
    
    try {
      final androidPlugin = _notifications!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      
      final iosPlugin = _notifications!.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  Future<void> scheduleDailyReminder() async {
    if (!_isAvailable || _notifications == null) return;
    if (!_dailyReminderEnabled) return;

    await _notifications!.cancel(1);

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Gunluk Hatirlatma',
      channelDescription: 'Gunluk calisma hatirlatmalari',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications!.periodicallyShow(
      1,
      'Gunluk Calisma Zamani!',
      'Bugun henuz calismadin. Serini kaybetme!',
      RepeatInterval.daily,
      notificationDetails,
      payload: 'daily_reminder',
    );
  }

  Future<void> sendStreakWarning(int currentStreak) async {
    if (!_isAvailable || _notifications == null || !_streakReminderEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'streak_reminder',
      'Seri Uyarisi',
      channelDescription: 'Gunluk seri kaybetme uyarilari',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notifications!.show(
      2,
      '$currentStreak Gunluk Seri Tehlikede!',
      'Bugun calismazsan serin sifirlanacak! Hemen basla!',
      notificationDetails,
      payload: 'streak_warning',
    );
  }

  Future<void> sendReviewReminder(int wordCount) async {
    if (!_isAvailable || _notifications == null || !_reviewReminderEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'review_reminder',
      'Tekrar Hatirlatma',
      channelDescription: 'Kelime tekrari hatirlatmalari',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notifications!.show(
      3,
      '$wordCount Kelime Tekrar Bekliyor',
      'Ogrendigin kelimeleri tekrar et, kalici hafizaya al!',
      notificationDetails,
      payload: 'review_reminder',
    );
  }

  Future<void> sendAchievementNotification(String title, String message) async {
    if (!_isAvailable || _notifications == null || !_achievementNotificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'achievement',
      'Basarilar',
      channelDescription: 'Rozet ve basari bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notifications!.show(4, title, message, notificationDetails, payload: 'achievement');
  }

  Future<void> showNotification({
    required String title, 
    required String body, 
    String? payload,
  }) async {
    if (!_isAvailable || _notifications == null) return;

    const androidDetails = AndroidNotificationDetails(
      'general',
      'Genel',
      channelDescription: 'Genel bildirimler',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications?.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications?.cancel(id);
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    _dailyReminderEnabled = enabled;
    await _saveSettingsToBox();
    if (enabled) {
      await scheduleDailyReminder();
    } else {
      await cancelNotification(1);
    }
    notifyListeners();
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    _dailyReminderTime = time;
    await _saveSettingsToBox();
    if (_dailyReminderEnabled) {
      await scheduleDailyReminder();
    }
    notifyListeners();
  }

  Future<void> setStreakReminderEnabled(bool enabled) async {
    _streakReminderEnabled = enabled;
    await _saveSettingsToBox();
    notifyListeners();
  }

  Future<void> setReviewReminderEnabled(bool enabled) async {
    _reviewReminderEnabled = enabled;
    await _saveSettingsToBox();
    notifyListeners();
  }

  Future<void> setAchievementNotificationsEnabled(bool enabled) async {
    _achievementNotificationsEnabled = enabled;
    await _saveSettingsToBox();
    notifyListeners();
  }
}
