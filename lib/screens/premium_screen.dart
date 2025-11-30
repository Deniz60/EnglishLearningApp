import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/premium_service.dart';
import '../utils/constants.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PremiumService _premiumService = PremiumService();

  @override
  void initState() {
    super.initState();
    _premiumService.addListener(_onPremiumChange);
  }

  @override
  void dispose() {
    _premiumService.removeListener(_onPremiumChange);
    super.dispose();
  }

  void _onPremiumChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_premiumService.isPremium) {
      return _buildPremiumActiveScreen();
    }
    return _buildPurchaseScreen();
  }

  Widget _buildPremiumActiveScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: AppColors.premium,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.premium, Color(0xFFFFD700)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premium.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 80,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                'Premium Üyesiniz! 🎉',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.premium,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                'Tüm premium özellikler aktif!',
                style: AppTextStyles.body1,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
              _buildActiveFeaturesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFeaturesList() {
    final features = _premiumService.getPremiumFeatures();
    
    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        
        return ListTile(
          leading: Text(feature.icon, style: const TextStyle(fontSize: 28)),
          title: Text(feature.title),
          subtitle: Text(feature.description),
          trailing: const Icon(Icons.check_circle, color: AppColors.success),
        ).animate(delay: Duration(milliseconds: 400 + index * 100)).fadeIn().slideX(begin: 0.2);
      }).toList(),
    );
  }

  Widget _buildPurchaseScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: AppColors.premium,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.premium, Color(0xFFFFD700)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, size: 50, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Sınırsız Öğrenme',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 20),
            _buildFeaturesList(),
            const SizedBox(height: 20),
            const Text('Planlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPricingCards(),
            const SizedBox(height: 16),
            _buildRestoreButton(),
            if (_premiumService.errorMessage != null) _buildErrorMessage(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = _premiumService.getPremiumFeatures();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.premium.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(feature.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 50 + index * 30)).fadeIn().scale();
      }).toList(),
    );
  }

  Widget _buildPricingCards() {
    return Column(
      children: [
        _buildPlanCard(
          title: 'Aylık',
          price: '₺49.99',
          period: '/ay',
          description: 'Her ay yenilenir',
          color: Colors.blue,
          onTap: () => _purchase(_premiumService.monthlyProduct),
          delay: 100,
        ),
        const SizedBox(height: 8),
        _buildPlanCard(
          title: 'Yıllık',
          price: '₺399.99',
          period: '/yıl',
          description: '%33 tasarruf!',
          color: AppColors.premium,
          isPopular: true,
          onTap: () => _purchase(_premiumService.yearlyProduct),
          delay: 150,
        ),
        const SizedBox(height: 8),
        _buildPlanCard(
          title: 'Ömür Boyu',
          price: '₺999.99',
          period: '',
          description: 'Tek seferlik',
          color: const Color(0xFFFFD700),
          onTap: () => _purchase(_premiumService.lifetimeProduct),
          delay: 200,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required int delay,
    bool isPopular = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: isPopular ? 4 : 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPopular ? BorderSide(color: color, width: 2) : BorderSide.none,
          ),
          child: InkWell(
            onTap: _premiumService.isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.workspace_premium, color: color, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(description, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                      if (period.isNotEmpty)
                        Text(period, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(begin: 0.1),
        if (isPopular)
          Positioned(
            top: -8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('POPÜLER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ).animate(delay: Duration(milliseconds: delay + 50)).scale(),
          ),
      ],
    );
  }

  Widget _buildRestoreButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _premiumService.isLoading ? null : _restorePurchases,
        icon: const Icon(Icons.restore),
        label: const Text('Satın Alımları Geri Yükle'),
      ),
    ).animate(delay: 700.ms).fadeIn();
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _premiumService.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.error),
            onPressed: _premiumService.clearError,
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(dynamic product) async {
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu ürün şu anda mevcut değil'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = await _premiumService.purchaseProduct(product);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium satın alındı! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    await _premiumService.restorePurchases();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _premiumService.isPremium 
              ? 'Premium geri yüklendi! 🎉'
              : 'Geri yüklenecek satın alım bulunamadı',
          ),
          backgroundColor: _premiumService.isPremium ? AppColors.success : AppColors.warning,
        ),
      );
    }
  }
}
