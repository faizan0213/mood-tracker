import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mood_tracker/screens/insight_screen.dart';
import '../../../core/constants.dart';
import '../../../services/mood_services.dart';
import '../../../services/auth_service.dart';
import 'mood_history_screen.dart';

class MoodLoggerScreen extends StatefulWidget {
  const MoodLoggerScreen({super.key});

  @override
  State<MoodLoggerScreen> createState() => _MoodLoggerScreenState();
}

class _MoodLoggerScreenState extends State<MoodLoggerScreen>
    with TickerProviderStateMixin {
  final noteController = TextEditingController();
  final moodService = MoodService();
  String selectedMood = '';
  String? message;
  bool isLoading = false;
  bool showSuccess = false;

  late AnimationController _animationController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _successAnimation;

  static const moodData = {
    'Happy': {
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': Colors.amber,
    },
    'Sad': {
      'icon': Icons.sentiment_very_dissatisfied_rounded,
      'color': Colors.blue,
    },
    'Angry': {
      'icon': Icons.sentiment_dissatisfied_rounded,
      'color': Colors.red,
    },
    'Excited': {'icon': Icons.star_rounded, 'color': Colors.orange},
    'Calm': {'icon': Icons.spa_rounded, 'color': Colors.green},
    'Anxious': {'icon': Icons.psychology_rounded, 'color': Colors.purple},
    'Neutral': {'icon': Icons.sentiment_neutral_rounded, 'color': Colors.grey},
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void submitMood() async {
    if (selectedMood.isEmpty) {
      _showMessage("Please select a mood first! 😊", isError: true);
      return;
    }

    FocusScope.of(context).unfocus(); // Auto dismiss keyboard

    setState(() {
      isLoading = true;
      message = null;
    });

    HapticFeedback.lightImpact();

    final result = await moodService.logMood(
      selectedMood,
      noteController.text.trim(),
    );

    if (result == 'Mood already logged for today') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You have already added mood today!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() {
        isLoading = false;
        showSuccess = false;
      });
      return;
    }

    setState(() {
      isLoading = false;
      showSuccess = true;
      message = result ?? "Mood logged successfully! 🎉";
    });

    _successController.forward();

    // Auto hide success message
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showSuccess = false;
          message = null;
        });
        _successController.reset();
      }
    });
  }

  void _showMessage(String msg, {bool isError = false}) {
    setState(() => message = msg);
    if (isError) HapticFeedback.lightImpact();
  }

  void logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService().logout();
    }
  }

  // ... rest of your widget tree remains the same

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final crossAxisCount = isTablet ? 4 : 2;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Mood Tracker',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTablet ? 24 : 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
        actions: [
          _buildAppBarButton(
            icon: Icons.insights_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InsightsScreen()),
            ),
            tooltip: 'Insights',
          ),
          _buildAppBarButton(
            icon: Icons.history_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoodHistoryScreen()),
            ),
            tooltip: 'History',
          ),
          _buildAppBarButton(
            icon: Icons.logout_rounded,
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                  _buildMoodSelector(theme, crossAxisCount, isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                  _buildNoteInput(theme, isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                  _buildSubmitButton(theme, isTablet),
                  if (message != null) ...[
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildMessage(theme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isTablet) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.mood_rounded,
                color: theme.colorScheme.onPrimary,
                size: isTablet ? 32 : 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling today?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 22 : 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your mood and add notes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector(
    ThemeData theme,
    int crossAxisCount,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Mood',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isTablet ? 1.2 : 1.0,
          ),
          itemCount: moodData.length,
          itemBuilder: (context, index) {
            final mood = moodData.keys.elementAt(index);
            final data = moodData[mood]!;
            final isSelected = selectedMood == mood;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + (index * 100)),
              curve: Curves.elasticOut,
              builder: (context, animation, child) {
                return Transform.scale(
                  scale: animation,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => selectedMood = mood);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (data['color'] as Color).withOpacity(0.1)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (data['color'] as Color)
                              : theme.colorScheme.outline.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (data['color'] as Color).withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(isSelected ? 12 : 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (data['color'] as Color)
                                  : (data['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              data['icon'] as IconData,
                              color: isSelected
                                  ? Colors.white
                                  : (data['color'] as Color),
                              size: isTablet ? 32 : 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (data['color'] as Color)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoteInput(ThemeData theme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a Note (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: TextField(
            controller: noteController,
            maxLines: isTablet ? 4 : 3,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind? Share your thoughts...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 56 : 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : submitMood,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          isLoading ? 'Logging Mood...' : 'Log My Mood',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 18 : 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 8,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(ThemeData theme) {
    final isSuccess = showSuccess || (message?.contains('success') == true);

    return AnimatedBuilder(
      animation: showSuccess ? _successAnimation : _fadeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: showSuccess ? _successAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSuccess
                  ? Colors.green.withOpacity(0.1)
                  : theme.colorScheme.errorContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSuccess
                    ? Colors.green.withOpacity(0.3)
                    : theme.colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: isSuccess ? Colors.green : theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSuccess ? Colors.green : theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
