import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Premium Ödeme Servisi (In-App Purchase)
class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  static const String _premiumBoxName = 'premium_data';
  
  // Ürün ID'leri (Google Play Console ve App Store Connect'te tanımlanmalı)
  static const String monthlyProductId = 'premium_monthly';
  static const String yearlyProductId = 'premium_yearly';
  static const String lifetimeProductId = 'premium_lifetime';
  
  static const Set<String> _productIds = {
    monthlyProductId,
    yearlyProductId,
    lifetimeProductId,
  };

  Box? _premiumBox;
  bool _isInitialized = false;
  bool _isAvailable = false;
  bool _isPremium = false;
  String? _currentUserId;
  
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;

  ProductDetails? get monthlyProduct => 
      _products.where((p) => p.id == monthlyProductId).firstOrNull;
  ProductDetails? get yearlyProduct => 
      _products.where((p) => p.id == yearlyProductId).firstOrNull;
  ProductDetails? get lifetimeProduct => 
      _products.where((p) => p.id == lifetimeProductId).firstOrNull;

  Future<void> init({String? userId}) async {
    if (_isInitialized && _currentUserId == userId) return;
    
    _currentUserId = userId;

    try {
      _premiumBox = await Hive.openBox(_premiumBoxName);
      
      if (kIsWeb) {
        _isAvailable = false;
        await _checkPremiumFromSupabase();
        _isInitialized = true;
        return;
      }

      _isAvailable = await InAppPurchase.instance.isAvailable();
      
      if (!_isAvailable) {
        debugPrint('PremiumService: In-app purchases not available');
        await _checkPremiumFromSupabase();
        _isInitialized = true;
        return;
      }

      _subscription = InAppPurchase.instance.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('Purchase stream error: $error'),
      );

      await _loadProducts();
      await _restorePurchases();
      await _checkPremiumFromSupabase();
      
      _isInitialized = true;
      debugPrint('PremiumService initialized');
    } catch (e) {
      debugPrint('PremiumService init error: $e');
      _errorMessage = 'Premium servis başlatılamadı';
      _isInitialized = true;
    }
    
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await InAppPurchase.instance.queryProductDetails(_productIds);
      
      if (response.error != null) {
        debugPrint('Product query error: ${response.error}');
        _errorMessage = 'Ürünler yüklenemedi';
        return;
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('Load products error: $e');
      _errorMessage = 'Ürünler yüklenemedi';
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetails) {
    for (final purchase in purchaseDetails) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _isLoading = true;
        notifyListeners();
        break;
        
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndDeliverPurchase(purchase);
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
        break;
        
      case PurchaseStatus.error:
        _isLoading = false;
        _errorMessage = 'Satın alma hatası: ${purchase.error?.message}';
        notifyListeners();
        break;
        
      case PurchaseStatus.canceled:
        _isLoading = false;
        notifyListeners();
        break;
    }
  }

  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchase) async {
    _isLoading = false;
    _isPremium = true;
    
    await _premiumBox?.put('isPremium', true);
    await _premiumBox?.put('purchaseDate', DateTime.now().toIso8601String());
    await _premiumBox?.put('productId', purchase.productID);
    
    await _updatePremiumInSupabase(true, purchase.productID);
    
    notifyListeners();
    debugPrint('Purchase verified: ${purchase.productID}');
  }

  Future<void> _checkPremiumFromSupabase() async {
    if (_currentUserId == null || _currentUserId!.startsWith('guest_')) {
      _isPremium = _premiumBox?.get('isPremium', defaultValue: false) ?? false;
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('is_premium, premium_expires_at')
          .eq('id', _currentUserId!)
          .maybeSingle();

      if (response != null) {
        final isPremium = response['is_premium'] == true;
        final expiresAt = response['premium_expires_at'] as String?;
        
        if (isPremium && expiresAt != null) {
          final expiryDate = DateTime.tryParse(expiresAt);
          _isPremium = expiryDate != null && expiryDate.isAfter(DateTime.now());
        } else {
          _isPremium = isPremium;
        }
        
        await _premiumBox?.put('isPremium', _isPremium);
      }
    } catch (e) {
      debugPrint('Check premium from Supabase error: $e');
      _isPremium = _premiumBox?.get('isPremium', defaultValue: false) ?? false;
    }
  }

  Future<void> _updatePremiumInSupabase(bool isPremium, String productId) async {
    if (_currentUserId == null || _currentUserId!.startsWith('guest_')) return;

    try {
      DateTime? expiresAt;
      
      if (productId == monthlyProductId) {
        expiresAt = DateTime.now().add(const Duration(days: 30));
      } else if (productId == yearlyProductId) {
        expiresAt = DateTime.now().add(const Duration(days: 365));
      }
      
      await Supabase.instance.client.from('users').upsert({
        'id': _currentUserId,
        'is_premium': isPremium,
        'premium_product_id': productId,
        'premium_purchased_at': DateTime.now().toIso8601String(),
        if (expiresAt != null) 'premium_expires_at': expiresAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Update premium in Supabase error: $e');
    }
  }

  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      _errorMessage = 'Satın alma servisi kullanılamıyor';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final purchaseParam = PurchaseParam(productDetails: product);
      
      if (product.id == lifetimeProductId) {
        return await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        return await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Satın alma başlatılamadı: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      _errorMessage = 'Satın alma servisi kullanılamıyor';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await InAppPurchase.instance.restorePurchases();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Satın almalar geri yüklenemedi: $e';
      notifyListeners();
    }
  }

  List<PremiumFeature> getPremiumFeatures() {
    return [
      PremiumFeature(
        title: 'Sınırsız Kelime',
        description: 'Tüm seviyelerdeki tüm kelimelere erişin',
        icon: '📚',
      ),
      PremiumFeature(
        title: 'Reklamsız Deneyim',
        description: 'Hiç reklam görmeden öğrenin',
        icon: '🚫',
      ),
      PremiumFeature(
        title: 'Gelişmiş İstatistikler',
        description: 'Detaylı ilerleme raporları',
        icon: '📊',
      ),
      PremiumFeature(
        title: 'Offline Mod',
        description: 'İnternet olmadan çalışın',
        icon: '📴',
      ),
      PremiumFeature(
        title: 'Öncelikli Destek',
        description: 'Hızlı müşteri desteği',
        icon: '⭐',
      ),
      PremiumFeature(
        title: 'Özel Temalar',
        description: 'Premium tema seçenekleri',
        icon: '🎨',
      ),
    ];
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class PremiumFeature {
  final String title;
  final String description;
  final String icon;

  PremiumFeature({
    required this.title,
    required this.description,
    required this.icon,
  });
}
