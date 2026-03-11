import 'package:flutter/material.dart';

/// فئة واحدة من اهتمامات الـ Lifestyle (مثل رياضة، مطبخ).
class LifestyleCategory {
  const LifestyleCategory({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.icon,
    required this.options,
  });

  final String id;
  final String labelEn;
  final String labelAr;
  final IconData icon;
  final List<LifestyleOption> options;
}

/// خيار واحد (مثل "جري"، "قهوة").
class LifestyleOption {
  const LifestyleOption({required this.id, required this.labelEn, required this.labelAr, this.icon});

  final String id;
  final String labelEn;
  final String labelAr;
  final IconData? icon;
}

/// قائمة فئات وخيارات الـ Lifestyle للاختيار في البروفايل.
List<LifestyleCategory> getLifestyleCategories() {
  return [
    LifestyleCategory(
      id: 'hobbies',
      labelEn: 'Interests & Hobbies',
      labelAr: 'اهتمامات وهوايات',
      icon: Icons.favorite_border,
      options: const [
        LifestyleOption(id: 'reading', labelEn: 'Reading', labelAr: 'قراءة', icon: Icons.menu_book_outlined),
        LifestyleOption(id: 'cinema', labelEn: 'Cinema', labelAr: 'سينما', icon: Icons.movie_outlined),
        LifestyleOption(id: 'music', labelEn: 'Music', labelAr: 'موسيقى', icon: Icons.music_note_outlined),
        LifestyleOption(id: 'cooking', labelEn: 'Cooking', labelAr: 'طبخ', icon: Icons.restaurant_outlined),
        LifestyleOption(id: 'baking', labelEn: 'Baking', labelAr: 'خبز', icon: Icons.cake_outlined),
        LifestyleOption(id: 'photography', labelEn: 'Photography', labelAr: 'تصوير', icon: Icons.camera_alt_outlined),
        LifestyleOption(id: 'gaming', labelEn: 'Gaming', labelAr: 'ألعاب', icon: Icons.sports_esports_outlined),
        LifestyleOption(id: 'gardening', labelEn: 'Gardening', labelAr: 'حدائق', icon: Icons.eco_outlined),
        LifestyleOption(id: 'volunteering', labelEn: 'Volunteering', labelAr: 'تطوع', icon: Icons.volunteer_activism_outlined),
        LifestyleOption(id: 'festivals', labelEn: 'Festivals', labelAr: 'مهرجانات', icon: Icons.celebration_outlined),
        LifestyleOption(id: 'family', labelEn: 'Family', labelAr: 'عائلة', icon: Icons.family_restroom_outlined),
        LifestyleOption(id: 'friends', labelEn: 'Meeting friends', labelAr: 'لقاء الأصدقاء', icon: Icons.groups_outlined),
        LifestyleOption(id: 'travel', labelEn: 'Travel', labelAr: 'سفر', icon: Icons.flight_takeoff_outlined),
        LifestyleOption(id: 'yoga', labelEn: 'Yoga', labelAr: 'يوغا', icon: Icons.self_improvement_outlined),
        LifestyleOption(id: 'diy', labelEn: 'DIY', labelAr: 'حرف يدوية', icon: Icons.build_outlined),
        LifestyleOption(id: 'comedy', labelEn: 'Comedy', labelAr: 'كوميديا', icon: Icons.theater_comedy_outlined),
        LifestyleOption(id: 'coffee', labelEn: 'Coffee', labelAr: 'قهوة', icon: Icons.coffee_outlined),
        LifestyleOption(id: 'blogging', labelEn: 'Blogging', labelAr: 'تدوين', icon: Icons.article_outlined),
        LifestyleOption(id: 'history', labelEn: 'History', labelAr: 'تاريخ', icon: Icons.account_balance_outlined),
        LifestyleOption(id: 'outdoors', labelEn: 'Outdoors', labelAr: 'هواء الطلق', icon: Icons.nature_outlined),
      ],
    ),
    LifestyleCategory(
      id: 'sport',
      labelEn: 'Sport',
      labelAr: 'رياضة',
      icon: Icons.fitness_center,
      options: const [
        LifestyleOption(id: 'running', labelEn: 'Running', labelAr: 'جري', icon: Icons.directions_run_outlined),
        LifestyleOption(id: 'swimming', labelEn: 'Swimming', labelAr: 'سباحة', icon: Icons.pool_outlined),
        LifestyleOption(id: 'football', labelEn: 'Football', labelAr: 'كرة قدم', icon: Icons.sports_soccer_outlined),
        LifestyleOption(id: 'basketball', labelEn: 'Basketball', labelAr: 'كرة سلة', icon: Icons.sports_basketball_outlined),
        LifestyleOption(id: 'gym', labelEn: 'Gym', labelAr: 'نادي رياضي', icon: Icons.fitness_center_outlined),
        LifestyleOption(id: 'climbing', labelEn: 'Climbing', labelAr: 'تسلق', icon: Icons.terrain_outlined),
        LifestyleOption(id: 'cycling', labelEn: 'Cycling', labelAr: 'دراجة', icon: Icons.directions_bike_outlined),
        LifestyleOption(id: 'yoga_sport', labelEn: 'Yoga', labelAr: 'يوغا', icon: Icons.self_improvement_outlined),
        LifestyleOption(id: 'hiking', labelEn: 'Hiking', labelAr: 'مشي جبلي', icon: Icons.hiking_outlined),
        LifestyleOption(id: 'tennis', labelEn: 'Tennis', labelAr: 'تنس', icon: Icons.sports_tennis_outlined),
        LifestyleOption(id: 'handball', labelEn: 'Handball', labelAr: 'كرة يد', icon: Icons.sports_handball_outlined),
        LifestyleOption(id: 'martial_arts', labelEn: 'Martial arts', labelAr: 'فنون قتالية', icon: Icons.sports_martial_arts_outlined),
      ],
    ),
    LifestyleCategory(
      id: 'culinary',
      labelEn: 'Culinary',
      labelAr: 'مطبخ وأكل',
      icon: Icons.restaurant,
      options: const [
        LifestyleOption(id: 'arabic_food', labelEn: 'Arabic cuisine', labelAr: 'مطبخ عربي', icon: Icons.restaurant_outlined),
        LifestyleOption(id: 'italian_food', labelEn: 'Italian cuisine', labelAr: 'مطبخ إيطالي', icon: Icons.local_pizza_outlined),
        LifestyleOption(id: 'asian_food', labelEn: 'Asian cuisine', labelAr: 'مطبخ آسيوي', icon: Icons.ramen_dining_outlined),
        LifestyleOption(id: 'fast_food', labelEn: 'Fast food', labelAr: 'وجبات سريعة', icon: Icons.fastfood_outlined),
        LifestyleOption(id: 'coffee_culinary', labelEn: 'Coffee', labelAr: 'قهوة', icon: Icons.coffee_outlined),
        LifestyleOption(id: 'desserts', labelEn: 'Desserts', labelAr: 'حلويات', icon: Icons.cake_outlined),
        LifestyleOption(id: 'vegetarian', labelEn: 'Vegetarian', labelAr: 'نباتي', icon: Icons.eco_outlined),
        LifestyleOption(id: 'organic', labelEn: 'Organic', labelAr: 'عضوي', icon: Icons.grass_outlined),
        LifestyleOption(id: 'bbq', labelEn: 'BBQ', labelAr: 'شواء', icon: Icons.outdoor_grill_outlined),
      ],
    ),
    LifestyleCategory(
      id: 'travel',
      labelEn: 'Travel',
      labelAr: 'سفر',
      icon: Icons.flight_takeoff,
      options: const [
        LifestyleOption(id: 'beach', labelEn: 'Beach holidays', labelAr: 'إجازات شاطئ', icon: Icons.beach_access_outlined),
        LifestyleOption(id: 'camping', labelEn: 'Camping', labelAr: 'تخييم', icon: Icons.landscape_outlined),
        LifestyleOption(id: 'cities', labelEn: 'City trips', labelAr: 'مدن', icon: Icons.location_city_outlined),
        LifestyleOption(id: 'nature', labelEn: 'Nature', labelAr: 'طبيعة', icon: Icons.nature_outlined),
        LifestyleOption(id: 'adventure', labelEn: 'Adventure', labelAr: 'مغامرات', icon: Icons.terrain_outlined),
      ],
    ),
    LifestyleCategory(
      id: 'character',
      labelEn: 'Character & traits',
      labelAr: 'شخصية وصفات',
      icon: Icons.psychology_outlined,
      options: const [
        LifestyleOption(id: 'adventurous', labelEn: 'Adventurous', labelAr: 'مغامر', icon: Icons.explore_outlined),
        LifestyleOption(id: 'active', labelEn: 'Active', labelAr: 'نشيط', icon: Icons.bolt_outlined),
        LifestyleOption(id: 'ambitious', labelEn: 'Ambitious', labelAr: 'طموح', icon: Icons.trending_up_outlined),
        LifestyleOption(id: 'open_minded', labelEn: 'Open-minded', labelAr: 'منفتح', icon: Icons.lightbulb_outline),
        LifestyleOption(id: 'calm', labelEn: 'Calm', labelAr: 'هادئ', icon: Icons.spa_outlined),
        LifestyleOption(id: 'authentic', labelEn: 'Authentic', labelAr: 'صادق', icon: Icons.verified_user_outlined),
        LifestyleOption(id: 'family_person', labelEn: 'Family person', labelAr: 'عائلي', icon: Icons.family_restroom_outlined),
        LifestyleOption(id: 'humorous', labelEn: 'Humorous', labelAr: 'مرح', icon: Icons.emoji_emotions_outlined),
        LifestyleOption(id: 'empathetic', labelEn: 'Empathetic', labelAr: 'متسامح', icon: Icons.favorite_border),
        LifestyleOption(id: 'generous', labelEn: 'Generous', labelAr: 'كريم', icon: Icons.card_giftcard_outlined),
      ],
    ),
  ];
}

/// تحويل قائمة IDs محفوظة إلى تسميات للعرض حسب اللغة.
List<String> resolveLifestyleLabels(List<String> ids, String localeLanguageCode) {
  if (ids.isEmpty) return [];
  final categories = getLifestyleCategories();
  final idToOption = <String, LifestyleOption>{};
  for (final cat in categories) {
    for (final opt in cat.options) {
      idToOption[opt.id] = opt;
    }
  }
  final isArabic = localeLanguageCode == 'ar';
  return ids
      .map((id) => idToOption[id])
      .whereType<LifestyleOption>()
      .map((o) => isArabic ? o.labelAr : o.labelEn)
      .toList();
}
