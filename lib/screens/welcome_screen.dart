// screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/user_service.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> 
    with TickerProviderStateMixin {
  
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _showFeatures = false;
  String? _errorMessage;
  
  late AnimationController _mainAnimationController;
  late AnimationController _featuresAnimationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  static const List<_Feature> _features = [
    _Feature(
      icon: Icons.trending_up,
      title: 'تتبع المصروفات والدخل',
      description: 'سجل جميع معاملاتك المالية بسهولة وتتبع دخلك ومصروفاتك بوضوح',
    ),
    _Feature(
      icon: Icons.pie_chart_rounded,
      title: 'تقارير وتحليلات',
      description: 'احصل على تقارير مفصلة عن أنماط إنفاقك ونصائح مالية ذكية',
    ),
    _Feature(
      icon: Icons.lock_clock_rounded,
      title: 'إدارة الالتزامات',
      description: 'تتبع التزاماتك المالية الشهرية وتجنب المفاجآت غير المتوقعة',
    ),
    _Feature(
      icon: Icons.volunteer_activism_rounded,
      title: 'التبرع عبر إحسان',
      description: 'تبرع بسهولة عبر منصة إحسان مباشرة من التطبيق',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialAnimation();
  }
  
  void _setupAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _featuresAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));
  }
  
  void _startInitialAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mainAnimationController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _mainAnimationController.dispose();
    _featuresAnimationController.dispose();
    super.dispose();
  }

  Future<void> _saveNameAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      _showValidationError();
      return;
    }
    
    _setLoadingState(true);
    _clearError();
    
    try {
      final name = _nameController.text.trim();
      
      // حفظ الاسم في UserService
      final userService = UserService();
      final success = await userService.saveUserName(name);
      
      if (!mounted) return;
      
      if (success) {
        // تحديث UserProvider
        final userProvider = context.read<UserProvider>();
        await userProvider.updateUserName(name);
        
        // الانتقال لشاشة المميزات
        await _transitionToFeatures();
      } else {
        _setError('فشل في حفظ الاسم، يرجى المحاولة مرة أخرى');
      }
    } catch (e) {
      debugPrint('خطأ في حفظ الاسم: $e');
      _setError('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى');
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _transitionToFeatures() async {
    try {
      HapticFeedback.lightImpact();
      
      await _mainAnimationController.reverse();
      
      if (!mounted) return;
      
      setState(() {
        _showFeatures = true;
      });
      
      await _featuresAnimationController.forward();
      
      // الانتقال التلقائي بعد 3 ثوان
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        await _completeOnboarding();
      }
    } catch (e) {
      debugPrint('خطأ في الانتقال للمميزات: $e');
      _setError('حدث خطأ في الانتقال');
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      HapticFeedback.mediumImpact();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_time_user', false);
      
      if (!mounted) return;
      
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      debugPrint('خطأ في إكمال التسجيل: $e');
      _setError('حدث خطأ، يرجى المحاولة مرة أخرى');
    }
  }

  // دوال مساعدة لإدارة الحالة
  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
      _showErrorSnackBar(message);
    }
  }

  void _clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _showValidationError() {
    HapticFeedback.lightImpact();
    _nameFocusNode.requestFocus();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _showFeatures 
              ? _buildFeaturesView() 
              : _buildWelcomeView(),
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildAppIcon(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    _buildWelcomeTitle(),
                    
                    const SizedBox(height: 16),
                    
                    _buildWelcomeDescription(),
                    
                    const SizedBox(height: 48),
                    
                    _buildQuickFeatures(),
                  ],
                ),
              ),
            ),
          ),
          
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildNameInputSection(),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAppIcon() {
    return Hero(
      tag: 'app_icon',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWelcomeTitle() {
    return const Text(
      'مرحباً بك في مدير الأموال',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildWelcomeDescription() {
    return Text(
      'تطبيقك الشخصي لإدارة الأموال بذكاء\nتتبع مصروفاتك ودخلك بسهولة ووضوح',
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildQuickFeatures() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildQuickFeatureItem(
            Icons.trending_up,
            'تتبع المصروفات والدخل',
            'راقب أموالك بطريقة منظمة',
          ),
          const SizedBox(height: 16),
          _buildQuickFeatureItem(
            Icons.pie_chart_rounded,
            'تقارير مفصلة',
            'اكتشف أنماط إنفاقك',
          ),
          const SizedBox(height: 16),
          _buildQuickFeatureItem(
            Icons.security_rounded,
            'بيانات آمنة',
            'معلوماتك محفوظة محلياً',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ما اسمك؟',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'سنستخدم اسمك لتخصيص تجربتك',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildNameTextField(),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildErrorMessage(),
            ],
            
            const SizedBox(height: 24),
            
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameTextField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'أدخل اسمك هنا',
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontWeight: FontWeight.normal,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        errorStyle: const TextStyle(fontSize: 0, height: 0), // إخفاء رسالة الخطأ الافتراضية
      ),
      validator: _validateName,
      onFieldSubmitted: (_) => _saveNameAndContinue(),
      enabled: !_isLoading,
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال اسمك';
    }
    if (value.trim().length < 2) {
      return 'الاسم يجب أن يحتوي على حرفين على الأقل';
    }
    if (value.trim().length > 30) {
      return 'الاسم طويل جداً';
    }
    // التحقق من وجود أحرف خاصة غير مرغوبة
    if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'يرجى استخدام أحرف عربية أو إنجليزية فقط';
    }
    return null;
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveNameAndContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'لنبدأ الرحلة!',
                  key: ValueKey('continue_text'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFeaturesView() {
    return AnimatedBuilder(
      animation: _featuresAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _featuresAnimationController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _featuresAnimationController,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          _buildProgressIndicator(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _buildFeaturesTitle(),
                  
                  const SizedBox(height: 8),
                  
                  _buildFeaturesDescription(),
                  
                  const SizedBox(height: 40),
                  
                  ..._features.asMap().entries.map((entry) {
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (entry.key * 200)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * 50),
                          child: Opacity(
                            opacity: value,
                            child: _buildDetailedFeatureItem(entry.value),
                          ),
                        );
                      },
                    );
                  }).toList(),
                  
                  const SizedBox(height: 40),
                  
                  _buildStartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        );
      },
    );
  }

  Widget _buildFeaturesTitle() {
    return const Text(
      'اكتشف مميزات التطبيق',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFeaturesDescription() {
    return Text(
      'تعرف على كيفية استفادتك القصوى من تطبيق مدير الأموال',
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDetailedFeatureItem(_Feature feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              feature.icon,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  feature.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ابدأ الاستخدام الآن!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;

  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
}