import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;
  static const String _kInstallDateKey = 'install_date';
  static const String _kHasReviewedKey = 'has_reviewed';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kInstallDateKey)) {
      await prefs.setInt(
          _kInstallDateKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> requestReviewIfAppropriate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasReviewed = prefs.getBool(_kHasReviewedKey) ?? false;

    if (hasReviewed) return;

    if (await _inAppReview.isAvailable()) {
      // Check if installed for at least 3 days
      final installDateMillis = prefs.getInt(_kInstallDateKey) ?? 0;
      final installDate = DateTime.fromMillisecondsSinceEpoch(installDateMillis);
      final daysSinceInstall = DateTime.now().difference(installDate).inDays;

      if (daysSinceInstall >= 3) {
        await _inAppReview.requestReview();
        await prefs.setBool(_kHasReviewedKey, true);
      }
    }
  }
}
